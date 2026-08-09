# Redpanda

A single-broker Redpanda cluster and its web console, running locally as **Apple
Container** containers. Redpanda speaks the Kafka protocol, so anything that talks to Kafka
talks to this.

The point of the arrangement is that **Colima is not involved**. Apple Container runs each
Linux container as a lightweight virtual machine using Apple's own frameworks, so there is
no Docker daemon and no second VM to boot. Colima and Docker are still installed and still
work; nothing here needs them.

## What runs, and where it is defined

| Piece | Where |
| --- | --- |
| The `home-manager` module | `github:shinzui/redpanda-container`, registered in `flake-modules/modules.nix` |
| Turning it on | `home/redpanda.nix` |
| Apple Container itself | `derivations/apple-container.nix`, kept running by `home/apple-container.nix` |
| Console's friendly URL | `home/local-web-proxy.nix` |
| Recipes | `Justfile`, group `redpanda` |

Two containers, one network, one volume:

```text
network:  redpanda
broker:   redpanda-0          volume: redpanda-0-data -> /var/lib/redpanda/data
console:  redpanda-console
labels:   dev.shinzui.redpanda.managed=true
launchd:  com.shinzui.redpanda   (one-shot: runs redpanda-up at login, then exits)
logs:     ~/.local/state/redpanda/logs/
```

## Addresses

| Service | Address |
| --- | --- |
| Kafka API | `127.0.0.1:9092` |
| Admin API | `127.0.0.1:9644` |
| Schema Registry | `127.0.0.1:8081` |
| HTTP Proxy | `127.0.0.1:8082` |
| Console | http://redpanda.localhost (`127.0.0.1:8080`) |

All bound to loopback only, so nothing is reachable from off the machine.

## Everyday use

`rpk` reaches the cluster from any directory with no flags, via the `local` profile:

```bash
rpk cluster info
rpk topic create orders
echo hello | rpk topic produce orders
rpk topic consume orders -n 1
```

If that stops working, check the profile is still current:

```bash
rpk profile list      # `local` should be marked with *
rpk profile use local
```

The profile lives in `~/Library/Application Support/rpk/rpk.yaml` — **not**
`~/.config/rpk/`, which does not exist on this machine. An activation hook in
`home/redpanda.nix` creates it if absent but never overwrites it, so a profile edited by
hand survives a rebuild.

## The five commands

```bash
redpanda-up        # idempotent bring-up; safe to run any time
redpanda-down      # stop the containers, keep all data
redpanda-status    # what's running + whether the broker is actually serving
redpanda-logs      # tail broker logs; `redpanda-logs redpanda-console` for console
redpanda-purge     # DESTROYS ALL DATA; prompts unless --force
```

And the recipes:

```bash
just status-redpanda        # redpanda-status
just restart-redpanda       # down, then up
just logs-redpanda          # follow broker logs
just logs-redpanda-agent    # what redpanda-up printed at login
just redpanda-ui            # open Console
```

There is deliberately **no** `just` recipe for purging.

## Health checks

```bash
redpanda-status                                   # exits non-zero if not serving
curl -s http://127.0.0.1:9644/v1/status/ready     # {"status":"ready"}
rpk cluster health
```

## When something is wrong

**`redpanda-up` says the Apple Container service is not responding.** Start it:

```bash
container system start
```

**Console loads but shows no brokers, or logs say `no route to host`.** Apple Container's
container-to-container networking has degraded. This happens; it is not caused by anything
in this configuration. Restart the runtime, then bring the cluster back:

```bash
container system stop && container system start
redpanda-up
```

**The broker restarted and Console stopped working.** Expected, and `redpanda-up` fixes it.
The broker gets a new IP every restart, and Console reaches it through a generated hosts
file that is regenerated on each bring-up. Never restart the broker alone with
`container restart redpanda-0`; use `just restart-redpanda` or `redpanda-up`.

**A port is already in use.** Most likely an old Colima-based cluster is still up:

```bash
lsof -nP -iTCP -sTCP:LISTEN | grep -E ':(9092|9644|8081|8082|8080)\b'
rpk container stop     # if it's the old rpk/Docker cluster
colima stop
```

The two stacks cannot run at the same time — they bind the same ports.

**The cluster is wedged and nothing helps.** Purge and start over. This destroys all data:

```bash
redpanda-purge
redpanda-up
```

**Diagnosing a broker that will not start.** `container logs redpanda-0` shows Redpanda's
own output; `container logs --boot redpanda-0` shows the VM boot log, which is what you need
when the container died before Redpanda printed anything.

## Where the data is

On a named Apple Container volume, `redpanda-0-data`, mounted at
`/var/lib/redpanda/data` in the broker. It survives `redpanda-down`, a container delete and
recreate, and a reboot. The underlying disk image is under
`~/Library/Application Support/com.apple.container/volumes/`.

That directory is mutable state **outside** the Nix store — images, volumes, and the
installed Linux kernel all live there, and none of it is reproducible from the flake.

The only way to destroy the data is `redpanda-purge`, which prompts.

## Rollback

To stop the cluster, changing nothing else:

```bash
redpanda-down
```

To disable it but keep everything installed, set `services.redpanda-container.enable = false`
in `home/redpanda.nix` and switch. The volume and its data survive.

To go back to a previous system generation entirely:

```bash
darwin-rebuild --list-generations
sudo darwin-rebuild --switch-generation <N>
```

To go back to the Colima path for Redpanda:

```bash
redpanda-down          # free the ports first
colima start
rpk container start
```

Both stacks work, but not simultaneously — stop one before starting the other.

To restore the `rpk` profile as it was before this was adopted, if you kept a copy:

```bash
cp <backup> ~/Library/Application\ Support/rpk/rpk.yaml
rpk profile list
```

## Design notes

Two details look odd and are deliberate; both are consequences of behaviour verified by
experiment rather than guessed at.

**The broker advertises two different addresses.** A Kafka client connects, asks for
metadata, then connects to whatever address the broker advertised — so the advertised
address has to be correct from the asker's point of view. Console, in a container, is told
`redpanda-0:9092`. `rpk`, on macOS, is told `127.0.0.1:9092`. Each listener advertises what
is right for clients arriving on it.

**Console gets a generated `/etc/hosts` mounted into it.** Apple Container has no
container-to-container name resolution — not by bare name, and not via
`sudo container system dns create`, which configures macOS-side resolution instead. So
`redpanda-up` reads the broker's IP after starting it and writes a hosts file that Console
mounts. There is deliberately no `sudo` step anywhere in this setup.

The full reasoning, including why this is a Nix module rather than a compiled CLI, is in the
`redpanda-container` repository under `docs/adr/` and
`docs/spikes/1-apple-container-redpanda-findings.md`.
