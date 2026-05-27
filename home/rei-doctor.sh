#!/usr/bin/env bash
# rei-doctor — one-shot health check for the rei action-recording pipeline.
# Pipeline: commits -> mori-automate (ingest+match) -> webhook -> mori-rei-app
#           -> pgmq commit_batching -> worker drain -> public.actions (rei db)
#
# Usage: rei-doctor [--heal] [--notify] [--quiet]
#   --heal    kickstart any daemon whose pool looks wedged (the recurring failure)
#   --notify  send a macOS notification when something is wrong or was healed
#   --quiet   only print problems (for the watchdog)
set -uo pipefail

SOCK="${REI_DOCTOR_SOCKET:-/Users/shinzui/.local/state/postgresql}"
APP_ID="app_01knxf3p1aezarprphnkpgsqzj"
HOME_DIR="${HOME:-/Users/shinzui}"
UIDN="$(id -u)"
DOMAIN="gui/$UIDN"
STATE_DIR="$HOME_DIR/.cache/rei-doctor"
HEAL_COOLDOWN=600   # don't re-kickstart the same set within 10 min
STALE_INGEST=5400   # 90 min: daemon ingests hourly, so >90m = wedged
STUCK_QUEUE=7200    # 2h: worker drains hourly, so oldest msg >2h = stuck
APP_DRAIN_GRACE=3900 # 65 min: mori-rei-app sleeps one interval before first drain

HEAL=0; NOTIFY=0; QUIET=0
for a in "$@"; do case "$a" in
  --heal) HEAL=1;; --notify) NOTIFY=1;; --quiet) QUIET=1;;
  -h|--help) sed -n '2,9p' "$0"; exit 0;;
esac; done

mkdir -p "$STATE_DIR"
now=$(date +%s)
fails=0; warns=0; declare -a problems=(); declare -a heal_targets=()

if [ -t 1 ]; then
  c_red=$'\033[31m'; c_grn=$'\033[32m'; c_yel=$'\033[33m'; c_dim=$'\033[2m'; c_rst=$'\033[0m'
else
  c_red=""; c_grn=""; c_yel=""; c_dim=""; c_rst=""
fi
red()    { printf '%s✗%s %s\n' "$c_red" "$c_rst" "$1"; problems+=("$1"); fails=$((fails+1)); }
yellow() { printf '%s!%s %s\n' "$c_yel" "$c_rst" "$1"; warns=$((warns+1)); }
green()  { [ "$QUIET" = 1 ] || printf '%s✓%s %s\n' "$c_grn" "$c_rst" "$1"; }
info()   { [ "$QUIET" = 1 ] || printf '  %s%s%s\n' "$c_dim" "$1" "$c_rst"; }

# age (seconds) of newest ts-prefixed line matching regex; prints "" if none/unparseable
log_age() {
  local f="$1" re="$2" line ts epoch
  [ -r "$f" ] || return 1
  line=$(grep -aE "$re" "$f" 2>/dev/null | tail -1)
  [ -z "$line" ] && return 1
  ts=$(printf '%s' "$line" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[-+][0-9]{4}' | head -1)
  [ -z "$ts" ] && return 1
  epoch=$(date -d "$ts" +%s 2>/dev/null) || return 1
  echo $(( now - epoch ))
}
human() { local s="$1"; if [ "$s" -lt 90 ]; then echo "${s}s"; elif [ "$s" -lt 5400 ]; then echo "$((s/60))m"; else echo "$((s/3600))h$(((s%3600)/60))m"; fi; }

# epoch when the daemon's current process started (for warm-up grace + "after restart?" checks)
proc_start_epoch() {
  local pid lstart
  pid=$(launchctl print "$DOMAIN/$1" 2>/dev/null | awk -F'= ' '/pid = /{gsub(/ /,"",$2); print $2; exit}')
  [ -z "$pid" ] && return 1
  lstart=$(ps -p "$pid" -o lstart= 2>/dev/null)
  [ -z "$lstart" ] && return 1
  date -d "$lstart" +%s 2>/dev/null
}
INGEST_GRACE=4500   # 75 min: one ingest interval + slack after a (re)start

LOG_AUTOMATE="$HOME_DIR/.mori/logs/automate.stderr.log"
# keiro migration cutover (EP-24): the FD-pressure check repointed from the retired
# rei-subscription to rei-worker-kiroku. VALIDATE: confirm the kiroku worker emits the
# 'Too many open files' marker under FD exhaustion the same way the old poller did.
LOG_KIROKU="$HOME_DIR/.rei/logs/worker-kiroku.stderr.log"
LOG_APP="$HOME_DIR/.mori-rei-app/logs/server.stdout.log"

echo "── rei-doctor $(date '+%Y-%m-%d %H:%M:%S') ──"

# 1. postgres reachable
if pg_isready -h "$SOCK" -q 2>/dev/null; then green "postgres reachable"; else red "postgres not reachable ($SOCK)"; fi

# 2. daemons loaded + have a live pid
# keiro migration cutover (EP-24): rei-subscription + rei-worker are retired (Pure Option A);
# the keiro reactive layer runs as rei-worker-kiroku.
declare -A DAEMON_DB=(
  [com.shinzui.mori-automate]=mori
  [com.shinzui.mori-rei-app]=mori_rei_app
  [com.shinzui.rei-worker-git-sync]=rei
  [com.shinzui.rei-worker-kiroku]=rei
)
for label in "${!DAEMON_DB[@]}"; do
  if launchctl print "$DOMAIN/$label" 2>/dev/null | grep -q 'pid = '; then
    green "daemon up: ${label#com.shinzui.}"
  else
    red "daemon down: ${label#com.shinzui.}"; heal_targets+=("$label")
  fi
done

# 3. each db accepts a fresh connection within 3s (proxy for pool/exhaustion)
for db in mori rei mori_rei_app; do
  if PGCONNECT_TIMEOUT=3 psql -h "$SOCK" -d "$db" -tAc 'select 1' >/dev/null 2>&1; then
    green "db connectable: $db"
  else
    red "db NOT connectable: $db (pool/conn exhaustion?)"
  fi
done

# 4. ingest freshness — THE signal for the recurring wedge.
#    Gate on uptime so a freshly (re)started daemon isn't flagged before its first cycle,
#    and only count pool errors emitted by the *current* process (after it started).
astart=$(proc_start_epoch com.shinzui.mori-automate) || astart=0
auptime=$(( now - astart ))
age=$(log_age "$LOG_AUTOMATE" '\[INGEST\].*events written') || age=""
if [ "$astart" -gt 0 ] && [ "$auptime" -lt "$INGEST_GRACE" ]; then
  info "ingest: mori-automate warming up (up $(human "$auptime"), first cycle pending)"
elif [ -z "$age" ]; then
  yellow "no successful ingest line found in automate log"
elif [ "$age" -gt "$STALE_INGEST" ]; then
  red "ingest STALE: last success $(human "$age") ago (daemon wedged)"; heal_targets+=("com.shinzui.mori-automate")
else
  green "ingest fresh: last success $(human "$age") ago"
fi
# pool errors emitted since the current process started
perr=$(log_age "$LOG_AUTOMATE" 'AcquisitionTimeoutUsageError|Error querying projects') || perr=""
if [ -n "$perr" ] && [ "$perr" -lt "$STALE_INGEST" ] && [ $(( now - perr )) -gt "$astart" ]; then
  red "automate pool errors $(human "$perr") ago (current process)"; heal_targets+=("com.shinzui.mori-automate")
fi

# 5. FD pressure (the upstream trigger) — only if seen since the subscription process started
sstart=$(proc_start_epoch com.shinzui.rei-worker-kiroku) || sstart=0
fderr=$(log_age "$LOG_KIROKU" 'Too many open files in system') || fderr=""
if [ -n "$fderr" ] && [ "$fderr" -lt 3600 ] && [ $(( now - fderr )) -gt "$sstart" ]; then
  red "system FD exhaustion $(human "$fderr") ago — restart leaking app"
  heal_targets+=("com.shinzui.mori-automate" "com.shinzui.rei-worker-kiroku")
fi
nf=$(sysctl -n kern.num_files 2>/dev/null || echo 0); mf=$(sysctl -n kern.maxfiles 2>/dev/null || echo 1)
if [ "$mf" -gt 0 ] && [ $(( nf * 100 / mf )) -ge 80 ]; then
  yellow "FD table ${nf}/${mf} (>=80%)"
else
  info "FD table ${nf}/${mf}"
fi

# 6. pgmq queue health
qm=$(PGCONNECT_TIMEOUT=3 psql -h "$SOCK" -d mori_rei_app -tAc \
  "select queue_length||'|'||coalesce(oldest_msg_age_sec,0)||'|'||total_messages from pgmq.metrics('commit_batching')" 2>/dev/null)
if [ -n "$qm" ]; then
  IFS='|' read -r qlen qold qtot <<<"$qm"
  if [ "${qold%.*}" -gt "$STUCK_QUEUE" ]; then
    appstart=$(proc_start_epoch com.shinzui.mori-rei-app) || appstart=0
    appuptime=$(( now - appstart ))
    if [ "$appstart" -gt 0 ] && [ "$appuptime" -lt "$APP_DRAIN_GRACE" ]; then
      info "queue old but mori-rei-app is warming up (up $(human "$appuptime"), first drain pending)"
    else
      red "queue stuck: oldest msg $(human "${qold%.*}") (worker not draining)"; heal_targets+=("com.shinzui.mori-rei-app")
    fi
  else
    green "queue ok: ${qlen} waiting, ${qtot} lifetime"
  fi
else
  yellow "could not read pgmq metrics"
fi

wqm=$(PGCONNECT_TIMEOUT=3 psql -h "$SOCK" -d rei -tAc \
  "select queue_length||'|'||coalesce(oldest_msg_age_sec,0)||'|'||total_messages from pgmq.metrics('workspace_git_sync')" 2>/dev/null)
if [ -n "$wqm" ]; then
  IFS='|' read -r wqlen wqold wqtot <<<"$wqm"
  if [ "${wqold%.*}" -gt "$STUCK_QUEUE" ]; then
    red "workspace git-sync queue stuck: oldest msg $(human "${wqold%.*}") (worker not draining)"
    heal_targets+=("com.shinzui.rei-worker-git-sync")
  else
    green "workspace git-sync queue ok: ${wqlen} waiting, ${wqtot} lifetime"
  fi
else
  yellow "could not read workspace_git_sync pgmq metrics"
fi

# 7. last recorded action (info; gap is normal when idle)
la=$(PGCONNECT_TIMEOUT=3 psql -h "$SOCK" -d rei -tAc \
  "select coalesce(extract(epoch from (now()-max(occurred_at)))::bigint,-1) from public.actions" 2>/dev/null)
if [ -n "$la" ] && [ "$la" -ge 0 ]; then info "last action recorded $(human "$la") ago"; fi

# 8. delivery backlog (best-effort)
if command -v mori >/dev/null 2>&1; then
  dl=$(MORI_PG_CONNECTION_STRING="host=$SOCK dbname=mori" mori app deliveries "$APP_ID" 2>/dev/null \
        | grep -ciE 'failed|pending' || true)
  [ "${dl:-0}" -gt 0 ] && yellow "delivery backlog: ${dl} failed/pending"
fi

# ── heal ──
# de-dup heal targets
declare -A seen=(); declare -a to_heal=()
for t in "${heal_targets[@]:-}"; do [ -z "$t" ] && continue; [ -n "${seen[$t]:-}" ] && continue; seen[$t]=1; to_heal+=("$t"); done

healed_msg=""
if [ "${#to_heal[@]}" -gt 0 ] && [ "$HEAL" = 1 ]; then
  last_heal=$(cat "$STATE_DIR/last-heal" 2>/dev/null || echo 0)
  if [ $(( now - last_heal )) -lt "$HEAL_COOLDOWN" ]; then
    yellow "heal needed but in cooldown ($(human $(( now - last_heal ))) since last heal)"
  else
    for label in "${to_heal[@]}"; do
      launchctl kickstart -k "$DOMAIN/$label" 2>/dev/null \
        && { echo "  → healed: ${label#com.shinzui.}"; healed_msg+="${label#com.shinzui.} "; } \
        || echo "  → heal FAILED: ${label#com.shinzui.}"
    done
    echo "$now" >"$STATE_DIR/last-heal"
  fi
elif [ "${#to_heal[@]}" -gt 0 ]; then
  info "would heal: ${to_heal[*]#com.shinzui.}  (run with --heal)"
fi

# ── summary + notify ──
if [ "$fails" -gt 0 ]; then
  [ "$QUIET" = 1 ] && printf 'rei-doctor: %d problem(s): %s\n' "$fails" "${problems[*]}"
  echo "${c_red}✗ $fails problem(s), $warns warning(s)${c_rst}"
elif [ "$warns" -gt 0 ]; then
  echo "${c_yel}! healthy with $warns warning(s)${c_rst}"
else
  green "pipeline healthy"
fi

if [ "$NOTIFY" = 1 ]; then
  prev_fails=$(cat "$STATE_DIR/last-status" 2>/dev/null || echo 0)
  if [ -n "$healed_msg" ]; then
    osascript -e "display notification \"healed: $healed_msg\" with title \"rei-doctor: auto-healed\"" >/dev/null 2>&1 || true
  elif [ "$fails" -gt 0 ] && [ "$prev_fails" -eq 0 ]; then
    # only on healthy -> problem transition, so a prolonged outage doesn't notify every tick
    osascript -e "display notification \"${problems[0]}\" with title \"rei-doctor: $fails problem(s)\"" >/dev/null 2>&1 || true
  fi
fi
echo "$fails" >"$STATE_DIR/last-status"

[ "$fails" -gt 0 ] && exit 1 || exit 0
