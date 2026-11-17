#!/usr/bin/env python3
"""Inventory a keiro service's keiro-dsl specs as DDD raw material.

Reads the `.keiro` source text directly (comments carry the domain rationale
the canonical printer drops) and emits a JSON inventory of every node that
matters to a DDD model: aggregates with their commands, events, states, guards
and named rejections; processes, routers, workflows, operations; integration
contracts, intakes, emits and publishers; work queues, dispatches and read
models. It also scans the service's Haskell sources for coordination code the
DSL does not declare (hand-written process managers, routers, workflows,
queues) so the model is not limited to what the specs happen to cover.

This is a line-oriented reader, not the keiro-dsl parser. It relies on the
DSL's layout conventions: top-level nodes start in column 0 and their bodies
are indented or brace-delimited. When `keiro-dsl check --emit` is available,
prefer it to confirm the service graph; use this for extraction.

Usage:
    keiro_inventory.py [PROJECT_DIR]            # JSON inventory
    keiro_inventory.py [PROJECT_DIR] --summary  # human-readable summary
    keiro_inventory.py --workspace path/to/svc.keiro-workspace
    keiro_inventory.py --spec a.keiro --spec b.keiro
    keiro_inventory.py [PROJECT_DIR] --no-haskell
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

EXCLUDED_DIRS = {
    ".git",
    ".tmp",
    ".backups",
    ".direnv",
    "dist-newstyle",
    "node_modules",
    "test-fixtures",
    "result",
}

TOP_LEVEL = {
    "language",
    "context",
    "module",
    "layout",
    "id",
    "enum",
    "rule",
    "mapped",
    "aggregate",
    "process",
    "router",
    "workflow",
    "operation",
    "contract",
    "intake",
    "emit",
    "publisher",
    "workqueue",
    "dispatch",
    "readmodel",
    "target",
    "rebuild-group",
    "projection-owner",
    "projection-revision",
    "external-read",
}

HASKELL_COORDINATION_MODULES = {
    "Keiro.ProcessManager": "process-manager",
    "Keiro.Router": "router",
    "Keiro.Workflow": "workflow",
    "Keiro.Timer": "timer",
    "Keiro.PGMQ": "queue",
    "Keiro.Inbox": "inbox",
    "Keiro.Outbox": "outbox",
}

IDENT = r"[A-Za-z_][A-Za-z0-9_'.-]*"


def skip_dir(name: str) -> bool:
    return name in EXCLUDED_DIRS or name.startswith(".keiro-dsl-")


def walk(root: Path, suffix: str):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(d for d in dirnames if not skip_dir(d))
        for f in sorted(filenames):
            if f.endswith(suffix):
                yield Path(dirpath) / f


# --------------------------------------------------------------------------
# Workspace manifests


def read_workspace(path: Path) -> dict:
    ws = {"path": str(path), "service": None, "layout": None, "runtimePackage": None, "specs": []}
    for raw in path.read_text().splitlines():
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        word, _, rest = line.partition(" ")
        rest = rest.strip()
        if word == "service":
            ws["service"] = rest
        elif word == "layout":
            ws["layout"] = rest
        elif word == "runtime-package":
            ws["runtimePackage"] = rest
        elif word == "spec":
            ws["specs"].append(str((path.parent / rest).resolve()))
    return ws


# --------------------------------------------------------------------------
# Spec files


def split_blocks(lines: list[str]):
    """Yield (header_comment, first_line_no, block_lines) for each column-0 node."""
    comment: list[str] = []
    block: list[tuple[int, str]] | None = None
    block_comment: list[str] = []
    for no, raw in enumerate(lines, 1):
        line = raw.rstrip("\n")
        top = bool(line) and not line[0].isspace()
        if top and line.startswith("#"):
            if block is not None:
                yield block_comment, block
                block = None
            comment.append(line.lstrip("#").strip())
            continue
        if top and line.strip() == "}":
            if block is not None:
                block.append((no, line))
                yield block_comment, block
                block = None
            comment = []
            continue
        if top:
            if block is not None:
                yield block_comment, block
            block = [(no, line)]
            block_comment = comment
            comment = []
            continue
        if not line.strip():
            if block is None:
                comment = [] if comment and comment[-1] == "" else comment + [""]
            else:
                block.append((no, line))
            continue
        if block is not None:
            block.append((no, line))
    if block is not None:
        yield block_comment, block


def clean_doc(comment: list[str]) -> str | None:
    text = "\n".join(comment).strip()
    return text or None


def body_comments_before(block, index: int) -> str | None:
    out: list[str] = []
    j = index - 1
    while j >= 1:
        s = block[j][1].strip()
        if s.startswith("#"):
            out.insert(0, s.lstrip("#").strip())
            j -= 1
        else:
            break
    return clean_doc(out)


def words(s: str) -> list[str]:
    return s.replace("{", " ").replace("}", " ").split()


def parse_aggregate(name, block, doc):
    agg = {
        "name": name,
        "doc": doc,
        "states": [],
        "initialState": None,
        "terminalStates": [],
        "registers": [],
        "commands": [],
        "events": [],
        "domainOutcomes": None,
        "transitions": [],
        "hasProjection": False,
        "line": block[0][0],
    }
    section = None
    current = None
    for i, (no, raw) in enumerate(block[1:], 1):
        s = raw.strip()
        if not s or s.startswith("#"):
            continue
        m = re.match(rf"^(replay-only\s+)?({IDENT})\s+--\s+({IDENT})\s+-->", s)
        if m:
            current = {
                "from": m.group(2),
                "command": m.group(3),
                "replayOnly": bool(m.group(1)),
                "guard": None,
                "outcome": None,
                "emits": [],
                "to": None,
                "implementationHole": False,
                "note": body_comments_before(block, i),
                "line": no,
            }
            agg["transitions"].append(current)
            section = "transition"
            continue
        head = s.split()[0]
        if head == "regs":
            section = "regs"
            current = None
            continue
        if head == "states":
            states = s.split()[1:]
            agg["states"] = [x.rstrip("!") for x in states]
            agg["terminalStates"] = [x.rstrip("!") for x in states if x.endswith("!")]
            agg["initialState"] = agg["states"][0] if states else None
            section = None
            continue
        if head == "domain-outcomes":
            agg["domainOutcomes"] = dict(
                kv.split("=", 1) for kv in s.split()[1:] if "=" in kv
            )
            continue
        cm = re.match(rf"^command\s+({IDENT})", s)
        if cm:
            agg["commands"].append(cm.group(1))
            section = None
            current = None
            continue
        em = re.match(rf"^((?:retiring|deprecated)\s+)?event\s+({IDENT})(?:\s+v(\d+))?", s)
        if em:
            agg["events"].append(
                {
                    "name": em.group(2),
                    "lifecycle": (em.group(1) or "").strip() or None,
                    "version": int(em.group(3)) if em.group(3) else None,
                }
            )
            section = None
            current = None
            continue
        if head in ("wire", "snapshot", "projection"):
            agg["hasProjection"] = agg["hasProjection"] or head == "projection"
            section = None
            current = None
            continue
        if section == "regs" and raw.startswith("    ") and current is None:
            rm = re.match(rf"^({IDENT})\s+({IDENT})", s)
            if rm:
                agg["registers"].append({"name": rm.group(1), "type": rm.group(2)})
            continue
        if section == "transition" and current is not None:
            if head == "guard":
                current["guard"] = s[len("guard"):].strip()
            elif head == "outcome":
                current["outcome"] = s[len("outcome"):].strip()
            elif head == "emit":
                current["emits"].extend(s.split()[1:2])
            elif head == "goto":
                current["to"] = s.split()[1] if len(s.split()) > 1 else None
            elif s.startswith("implementation hole"):
                current["implementationHole"] = True
    agg["rejections"] = sorted(
        {
            t["outcome"].split(None, 1)[1]
            for t in agg["transitions"]
            if t["outcome"] and t["outcome"].startswith(("rejected", "no-op"))
            and len(t["outcome"].split()) > 1
        }
    )
    for t in agg["transitions"]:
        t["guardKind"] = classify_guard(t["guard"]) if t["guard"] else None
    agg["guardedTransitions"] = sum(1 for t in agg["transitions"] if t["guard"])
    agg["identityGuardedTransitions"] = sum(1 for t in agg["transitions"] if t["guardKind"] == "identity")
    seen: list[str] = []
    for t in agg["transitions"]:
        if t["guardKind"] == "business" and t["guard"] not in seen:
            seen.append(t["guard"])
    agg["businessGuards"] = seen
    agg["holeTransitions"] = sum(1 for t in agg["transitions"] if t["implementationHole"])
    return agg


IDENTITY_CONJUNCT = re.compile(r"^\(?\s*cmd\.\w+\s*(==|!=)\s*reg\.\w+\s*\)?$")


def classify_guard(guard: str) -> str:
    """'identity' when every conjunct only compares a command field to a register.

    Those guards pin a command to its stream (same id, same content hash) and are
    rarely business invariants. Anything else — thresholds, enum checks, rules —
    is 'business' and is a candidate invariant.
    """
    conjuncts = [c.strip() for c in re.split(r"&&|\|\|", guard)]
    return "identity" if all(IDENTITY_CONJUNCT.match(c) for c in conjuncts) else "business"


def parse_process(name, block, doc):
    p = {
        "name": name,
        "doc": doc,
        "runtimeName": None,
        "reactionsVersion": None,
        "inputs": [],
        "correlate": None,
        "saga": None,
        "sagaCategory": None,
        "target": None,
        "handlers": [],
        "timers": [],
        "line": block[0][0],
    }
    handler = None
    timer = None
    for _, raw in block[1:]:
        s = raw.strip()
        if not s or s.startswith("#"):
            continue
        w = s.split()
        head = w[0]
        indent = len(raw) - len(raw.lstrip())
        if indent <= 2:
            handler = None if head != "on" else handler
            timer = None if head != "timer" else timer
        if head == "name" and indent <= 2:
            p["runtimeName"] = s.split('"')[1] if '"' in s else w[1]
        elif head == "reactions" and "version" in w:
            p["reactionsVersion"] = w[-1]
        elif head == "input" and indent <= 2:
            p["inputs"].append(w[1])
        elif head == "correlate":
            p["correlate"] = s[len("correlate"):].strip()
        elif head == "saga":
            p["saga"] = w[1]
            if "category" in w:
                p["sagaCategory"] = w[w.index("category") + 1].strip('"')
        elif head == "target" and indent <= 2:
            p["target"] = w[1]
        elif head == "on" and indent <= 2:
            handler = {"on": w[1], "advances": [], "dispatches": [], "schedules": [], "cancels": [], "guards": []}
            p["handlers"].append(handler)
        elif head == "timer" and indent <= 2:
            timer = {"name": w[1], "fireAt": None, "fires": None, "deadLetter": None}
            p["timers"].append(timer)
        elif timer is not None:
            if head == "fireAt":
                timer["fireAt"] = s[len("fireAt"):].strip()
            elif head == "fire" and "dispatch" in w:
                i = w.index("dispatch")
                timer["fires"] = {"target": w[i + 1].split("@")[0], "command": w[i + 2] if len(w) > i + 2 else None}
            elif head == "max-attempts" and "dead-letter" in w:
                timer["deadLetter"] = s.split("dead-letter", 1)[1].strip().strip('"')
        elif handler is not None:
            if head == "advance":
                handler["advances"].append(w[1])
            elif head == "dispatch":
                handler["dispatches"].append({"target": w[1].split("@")[0], "command": w[2] if len(w) > 2 else None})
            elif head == "schedule":
                handler["schedules"].append(w[2] if len(w) > 2 and w[1] == "once" else w[1])
            elif head == "cancel":
                handler["cancels"].append(w[1])
            elif head == "when":
                handler["guards"].append(s[len("when"):].strip())
    return p


def parse_router(name, block, doc):
    r = {"name": name, "doc": doc, "runtimeName": None, "input": None, "key": None,
         "resolve": None, "target": None, "dispatches": [], "line": block[0][0]}
    for _, raw in block[1:]:
        s = raw.strip()
        w = s.split()
        if not w or s.startswith("#"):
            continue
        if w[0] == "name":
            r["runtimeName"] = s.split('"')[1] if '"' in s else w[1]
        elif w[0] == "input":
            r["input"] = w[1]
        elif w[0] == "key":
            r["key"] = s[len("key"):].strip()
        elif w[0] == "resolve":
            r["resolve"] = s[len("resolve"):].strip()
        elif w[0] == "target":
            r["target"] = w[1]
        elif w[0] == "dispatch-each":
            r["dispatches"].append(w[1])
    return r


def parse_workflow(name, block, doc):
    wf = {"name": name, "doc": doc, "runtimeName": None, "input": None, "output": None,
          "id": None, "steps": [], "awaits": [], "sleeps": [], "children": [], "patches": [],
          "continueAsNew": False, "line": block[0][0]}
    for _, raw in block[1:]:
        s = raw.strip()
        w = s.split()
        if not w or s.startswith("#"):
            continue
        h = w[0]
        if h == "name":
            wf["runtimeName"] = s.split('"')[1] if '"' in s else w[1]
        elif h == "in":
            wf["input"] = w[1]
        elif h == "out":
            wf["output"] = w[1]
        elif h == "id":
            wf["id"] = s[len("id"):].strip()
        elif h == "step":
            wf["steps"].append({"label": w[1], "result": w[-1] if "->" in w else None})
        elif h == "await":
            wf["awaits"].append({"label": w[1], "result": w[-1] if "->" in w else None})
        elif h == "sleep":
            wf["sleeps"].append({"label": w[1], "after": w[-1] if "after" in w else None})
        elif h == "child":
            wf["children"].append({"label": w[1], "result": w[-1] if "->" in w else None})
        elif h == "patch":
            wf["patches"].append(w[1])
        elif h == "continueAsNew":
            wf["continueAsNew"] = True
    return wf


def parse_operation(name, block, doc):
    op = {"name": name, "doc": doc, "kind": None, "subject": None, "line": block[0][0]}
    for _, raw in block[1:]:
        w = raw.split()
        if not w or w[0].startswith("#"):
            continue
        if w[0] in ("command", "query", "signal", "run") and op["kind"] is None:
            op["kind"] = w[0]
            if w[0] == "command" and "on" in w:
                op["subject"] = w[w.index("on") + 1]
            elif w[0] == "signal" and "of" in w:
                op["subject"] = {"signal": w[1], "workflow": w[w.index("of") + 1]}
            else:
                op["subject"] = w[1] if len(w) > 1 else None
    return op


def parse_contract(name, block, doc):
    c = {"name": name, "doc": doc, "schemaVersion": None, "topics": {}, "events": [], "line": block[0][0]}
    for _, raw in block[1:]:
        s = raw.strip()
        w = s.split()
        if not w or s.startswith("#"):
            continue
        if w[0] == "schemaVersion":
            c["schemaVersion"] = w[1]
        elif w[0] == "topic" and len(w) >= 3:
            c["topics"][w[1]] = w[2].strip('"')
        elif w[0] == "event" and "on" in w:
            c["events"].append({"name": w[1], "topic": w[w.index("on") + 1]})
    return c


def parse_keyed(name, block, doc, keys):
    """Generic brace node reader: capture the first value of each named key."""
    out = {"name": name, "doc": doc, "line": block[0][0]}
    for k in keys:
        out[k] = None
    for _, raw in block[1:]:
        s = raw.strip()
        w = s.split()
        if not w or s.startswith("#"):
            continue
        if w[0] in keys and out[w[0]] is None:
            rest = s[len(w[0]):].strip().lstrip("=").strip()
            out[w[0]] = rest.strip('"')
    return out


def parse_intake(name, block, doc):
    i = parse_keyed(name, block, doc, ["contract", "topic"])
    i["accepts"] = []
    for _, raw in block[1:]:
        w = raw.split()
        if w and w[0] == "accept":
            i["accepts"].extend(w[1:])
    return i


def parse_emit(name, block, doc):
    e = parse_keyed(name, block, doc, ["contract", "topic", "source", "key"])
    e["maps"] = []
    for _, raw in block[1:]:
        m = re.match(r'^\s*"([^"]*)"\s*=>\s*(\S+)', raw)
        if m:
            e["maps"].append({"from": m.group(1), "to": m.group(2)})
    return e


def parse_workqueue(name, block, doc):
    q = {"name": name, "doc": doc, "logical": None, "payload": None, "line": block[0][0]}
    for _, raw in block[1:]:
        s = raw.strip()
        m = re.match(r'^queue\s+logical\s*=\s*"([^"]+)"', s)
        if m:
            q["logical"] = m.group(1)
        pm = re.match(rf"^payload\s+({IDENT})", s)
        if pm:
            q["payload"] = pm.group(1)
    return q


def parse_dispatch(name, block, doc):
    d = {"name": name, "doc": doc, "sourceReadModel": None, "enqueueTo": None, "line": block[0][0]}
    for _, raw in block[1:]:
        s = raw.strip()
        m = re.match(r"^source\s+readModel\s*=\s*(\S+)", s)
        if m:
            d["sourceReadModel"] = m.group(1)
        m = re.match(r"^enqueue\s+to\s*=\s*(\S+)", s)
        if m:
            d["enqueueTo"] = m.group(1)
    return d


def parse_readmodel(name, block, doc):
    rm = parse_keyed(name, block, doc, ["group", "freshness", "table", "schema"])
    return rm


def parse_enum(name, block, doc):
    ctors = []
    text = " ".join(raw.split("#", 1)[0] for _, raw in block)
    inner = text.split("{", 1)[1].rsplit("}", 1)[0] if "{" in text else ""
    for tok in inner.split():
        ctors.append(tok.split("=", 1)[0])
    return {"name": name, "doc": doc, "constructors": ctors, "line": block[0][0]}


def node_name(kind: str, first: str) -> str | None:
    w = words(first)
    if kind == "mapped":
        # mapped structural record X { / mapped opaque X { / mapped nominal X
        rest = [x for x in w[1:] if x not in ("structural", "opaque", "nominal", "record", "enum", "union")]
        return rest[0] if rest else None
    if kind in ("target", "rebuild-group", "projection-owner", "projection-revision", "external-read"):
        return w[1] if len(w) > 1 else None
    return w[1] if len(w) > 1 else None


def read_spec(path: Path) -> dict:
    lines = path.read_text().splitlines()
    spec = {
        "path": str(path),
        "language": None,
        "context": None,
        "module": None,
        "layout": None,
        "headerDoc": None,
        "aggregates": [],
        "processes": [],
        "routers": [],
        "workflows": [],
        "operations": [],
        "contracts": [],
        "intakes": [],
        "emits": [],
        "publishers": [],
        "workqueues": [],
        "dispatches": [],
        "readmodels": [],
        "ids": [],
        "enums": [],
        "rules": [],
        "mapped": [],
        "catalog": [],
        "unknown": [],
    }
    first_node = True
    for comment, block in split_blocks(lines):
        first = block[0][1]
        kind = first.split()[0]
        doc = clean_doc(comment)
        if first_node:
            # A comment above the preamble describes the file, not the first node.
            if kind in ("language", "context", "module", "layout"):
                spec["headerDoc"] = doc
                doc = None
            first_node = False
        name = node_name(kind, first)
        if kind == "language":
            spec["language"] = first.split()[-1]
        elif kind == "context":
            spec["context"] = name
        elif kind == "module":
            spec["module"] = name
        elif kind == "layout":
            spec["layout"] = name
        elif kind == "aggregate":
            spec["aggregates"].append(parse_aggregate(name, block, doc))
        elif kind == "process":
            spec["processes"].append(parse_process(name, block, doc))
        elif kind == "router":
            spec["routers"].append(parse_router(name, block, doc))
        elif kind == "workflow":
            spec["workflows"].append(parse_workflow(name, block, doc))
        elif kind == "operation":
            spec["operations"].append(parse_operation(name, block, doc))
        elif kind == "contract":
            spec["contracts"].append(parse_contract(name, block, doc))
        elif kind == "intake":
            spec["intakes"].append(parse_intake(name, block, doc))
        elif kind == "emit":
            spec["emits"].append(parse_emit(name, block, doc))
        elif kind == "publisher":
            spec["publishers"].append(parse_keyed(name, block, doc, ["emit", "ordering"]))
        elif kind == "workqueue":
            spec["workqueues"].append(parse_workqueue(name, block, doc))
        elif kind == "dispatch":
            spec["dispatches"].append(parse_dispatch(name, block, doc))
        elif kind == "readmodel":
            spec["readmodels"].append(parse_readmodel(name, block, doc))
        elif kind == "id":
            spec["ids"].append({"name": name, "doc": doc, "line": block[0][0]})
        elif kind == "enum":
            spec["enums"].append(parse_enum(name, block, doc))
        elif kind == "rule":
            spec["rules"].append({"name": name.rstrip(":") if name else None, "doc": doc,
                                  "signature": first.split(":", 1)[1].strip() if ":" in first else None,
                                  "line": block[0][0]})
        elif kind == "mapped":
            spec["mapped"].append({"name": name, "doc": doc, "form": " ".join(first.split()[1:3]),
                                   "line": block[0][0]})
        elif kind in TOP_LEVEL:
            spec["catalog"].append({"kind": kind, "name": name, "doc": doc, "line": block[0][0]})
        else:
            spec["unknown"].append({"line": block[0][0], "text": first.strip()})
    return spec


# --------------------------------------------------------------------------
# Haskell coordination scan


def scan_haskell(root: Path) -> list[dict]:
    found = []
    import_re = re.compile(r"^import\s+(?:qualified\s+)?(Keiro\.[A-Za-z.]+)")
    for path in walk(root, ".hs"):
        parts = set(path.parts)
        if "Generated" in parts or parts & {"test", "tests", "bench"} or any(
            p.startswith(".keiro-dsl-") for p in parts
        ):
            continue
        kinds = set()
        try:
            with path.open(errors="replace") as fh:
                for line in fh:
                    m = import_re.match(line)
                    if not m:
                        continue
                    mod = m.group(1)
                    for prefix, kind in HASKELL_COORDINATION_MODULES.items():
                        if mod == prefix or mod.startswith(prefix + "."):
                            kinds.add(kind)
        except OSError:
            continue
        if kinds:
            found.append({"path": str(path.relative_to(root)), "kinds": sorted(kinds)})
    return found


def find_hole_modules(root: Path) -> list[str]:
    return [
        str(p.relative_to(root))
        for p in walk(root, ".hs")
        if p.name in ("Holes.hs", "BehaviorHoles.hs", "ProcessHoles.hs")
    ]


# --------------------------------------------------------------------------
# Driver


def discover(root: Path) -> tuple[list[dict], list[Path], list[str]]:
    workspaces = [read_workspace(p) for p in walk(root, ".keiro-workspace")]
    notes = []
    if workspaces:
        members = []
        for ws in workspaces:
            members.extend(Path(s) for s in ws["specs"])
        listed = {p.resolve() for p in members}
        stray = [str(p) for p in walk(root, ".keiro") if p.resolve() not in listed]
        if stray:
            notes.append(
                "Non-member .keiro files (not listed by any workspace; treat as non-authoritative): "
                + ", ".join(stray)
            )
        return workspaces, members, notes
    specs = list(walk(root, ".keiro"))
    if specs:
        notes.append("No .keiro-workspace manifest found; every discovered .keiro file was read.")
    return [], specs, notes


def build(root: Path, workspace: Path | None, specs: list[Path], haskell: bool) -> dict:
    notes: list[str] = []
    if workspace is not None:
        workspaces = [read_workspace(workspace)]
        spec_paths = [Path(s) for s in workspaces[0]["specs"]]
    elif specs:
        workspaces, spec_paths = [], specs
    else:
        workspaces, spec_paths, notes = discover(root)
    parsed = []
    for p in spec_paths:
        if not p.exists():
            notes.append(f"Workspace member missing on disk: {p}")
            continue
        parsed.append(read_spec(p))
    inventory = {
        "root": str(root),
        "workspaces": workspaces,
        "specs": parsed,
        "notes": notes,
    }
    if haskell:
        inventory["haskellCoordination"] = scan_haskell(root)
        inventory["holeModules"] = find_hole_modules(root)
    # Cross-reference: aggregates that are a process's saga are coordination
    # state, not domain aggregates.
    sagas = {pr["saga"] for s in parsed for pr in s["processes"] if pr["saga"]}
    for s in parsed:
        for a in s["aggregates"]:
            a["isSaga"] = a["name"] in sagas
    return inventory


def summarize(inv: dict) -> str:
    out = []
    for ws in inv["workspaces"]:
        out.append(f"workspace {ws['path']}  service={ws['service']}  specs={len(ws['specs'])}")
    for s in inv["specs"]:
        out.append("")
        out.append(f"== {s['path']}  (language {s['language'] or 'unversioned'}, context {s['context']}, module {s['module']})")
        if s["headerDoc"]:
            out.append("   doc: " + s["headerDoc"].splitlines()[0])
        for a in s["aggregates"]:
            tag = " [saga]" if a["isSaga"] else ""
            out.append(f"  aggregate {a['name']}{tag}  states={' '.join(a['states'])}  terminal={','.join(a['terminalStates']) or '-'}")
            out.append(f"    commands: {', '.join(a['commands'])}")
            out.append(f"    events:   {', '.join(e['name'] for e in a['events'])}")
            if a["rejections"]:
                out.append(f"    rejections: {', '.join(a['rejections'])}")
            for g in a["businessGuards"]:
                out.append(f"    business guard: {g}")
            if a["identityGuardedTransitions"]:
                out.append(f"    identity-only guards on {a['identityGuardedTransitions']} transitions (stream pinning, not invariants)")
            if a["holeTransitions"]:
                out.append(f"    implementation holes: {a['holeTransitions']}")
        for p in s["processes"]:
            out.append(f"  process {p['name']}  saga={p['saga']} correlate={p['correlate']} target={p['target']}")
            for h in p["handlers"]:
                d = ", ".join(f"{x['target']}.{x['command']}" for x in h["dispatches"])
                out.append(f"    on {h['on']}: advance {h['advances']} dispatch [{d}] schedule {h['schedules']}")
            for t in p["timers"]:
                out.append(f"    timer {t['name']} fireAt {t['fireAt']} fires {t['fires']}")
        for r in s["routers"]:
            out.append(f"  router {r['name']}  input={r['input']} target={r['target']} dispatch-each={r['dispatches']}")
        for w in s["workflows"]:
            out.append(f"  workflow {w['name']} ({w['runtimeName']})  in={w['input']} out={w['output']}")
            out.append(f"    steps: {', '.join(x['label'] for x in w['steps'])}")
            if w["awaits"]:
                out.append(f"    awaits: {', '.join(x['label'] for x in w['awaits'])}")
            if w["children"]:
                out.append(f"    children: {', '.join(x['label'] for x in w['children'])}")
            if w["sleeps"]:
                out.append(f"    sleeps: {', '.join(x['label'] for x in w['sleeps'])}")
        for c in s["contracts"]:
            out.append(f"  contract {c['name']}  topics={c['topics']}")
            out.append(f"    events: {', '.join(e['name'] for e in c['events'])}")
        for i in s["intakes"]:
            out.append(f"  intake {i['name']}  contract={i['contract']} accepts={i['accepts']}")
        for e in s["emits"]:
            out.append(f"  emit {e['name']}  contract={e['contract']} source={e['source']} -> {[m['to'] for m in e['maps'] if m['to'] != 'skip']}")
        for q in s["workqueues"]:
            out.append(f"  workqueue {q['name']}  logical={q['logical']} payload={q['payload']}")
        for d in s["dispatches"]:
            out.append(f"  dispatch {d['name']}  from readModel={d['sourceReadModel']} to={d['enqueueTo']}")
        for o in s["operations"]:
            out.append(f"  operation {o['name']}  {o['kind']} {o['subject']}")
        if s["readmodels"]:
            out.append(f"  readmodels: {', '.join(r['name'] for r in s['readmodels'])}")
        if s["ids"]:
            out.append(f"  ids: {', '.join(i['name'] for i in s['ids'])}")
        for e in s["enums"]:
            out.append(f"  enum {e['name']}: {' '.join(e['constructors'])}")
        if s["mapped"]:
            out.append(f"  mapped: {', '.join(m['name'] or '?' for m in s['mapped'])}")
        if s["unknown"]:
            out.append(f"  unrecognised top-level lines: {[u['text'] for u in s['unknown']]}")
    if inv.get("haskellCoordination"):
        out.append("")
        out.append("== Hand-written Haskell coordination (not declared in the DSL unless matched above)")
        for h in inv["haskellCoordination"]:
            out.append(f"  {h['path']}: {', '.join(h['kinds'])}")
    if inv.get("holeModules"):
        out.append("")
        out.append(f"== Hole modules ({len(inv['holeModules'])}) — invariant prose often lives here")
        for h in inv["holeModules"]:
            out.append(f"  {h}")
    for n in inv["notes"]:
        out.append("")
        out.append("NOTE: " + n)
    return "\n".join(out)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("project", nargs="?", default=".", help="service project root (default: .)")
    ap.add_argument("--workspace", type=Path, help="read exactly this .keiro-workspace manifest")
    ap.add_argument("--spec", type=Path, action="append", default=[], help="read this .keiro file (repeatable)")
    ap.add_argument("--summary", action="store_true", help="print a human-readable summary instead of JSON")
    ap.add_argument("--no-haskell", action="store_true", help="skip the Haskell coordination scan")
    args = ap.parse_args()

    root = Path(args.project).resolve()
    if not root.is_dir():
        print(f"not a directory: {root}", file=sys.stderr)
        return 2
    inv = build(root, args.workspace.resolve() if args.workspace else None,
                [p.resolve() for p in args.spec], not args.no_haskell)
    if not inv["specs"]:
        print(f"no keiro-dsl specs found under {root}", file=sys.stderr)
        if args.summary:
            print(summarize(inv))
        else:
            json.dump(inv, sys.stdout, indent=2)
        return 1
    if args.summary:
        print(summarize(inv))
    else:
        json.dump(inv, sys.stdout, indent=2)
        print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
