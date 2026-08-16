#!/usr/bin/env python3
"""Map Haskell cabal build-depends onto mori registry dependency names.

Usage:
    python3 cabal_mori_deps.py [ROOT] [--json]

ROOT defaults to the current directory. Every *.cabal file under ROOT is parsed
(skipping build output directories) and each dependency is classified:

    namespace/project          -- the cabal name IS a registered mori project
    namespace/project:package  -- the cabal name is one package of that project
    INTERNAL                   -- another cabal package in this same project
    BOOT                       -- GHC boot library; never declared in mori.dhall
    UNREGISTERED               -- real third-party dep with no registry entry yet

The package-qualified form is deliberate, not noise. Mori resolves a dependency
to a project and, when the name identifies one, to a package inside it; keeping
that grain is what lets `mori registry dependents 'ns/project:package'` answer
about the package actually consumed rather than the whole project.

`cabal.project` is parsed too. Its `source-repository-package` stanzas name
upstream git repos that are real, deliberate dependencies -- often *transitive*
ones pinned to a fork (a patched `crypton`, a `memory`->`ram` swap) that never
appear in any `build-depends`. They belong in mori.dhall just as much as direct
deps, so they are reported under the pseudo-package `cabal.project`.

Default output is TSV:
    cabal-package<TAB>scope<TAB>cabal-dep<TAB>classification<TAB>version-constraint

The last column is the cabal version bound verbatim, ready to become a
`versionConstraint` in mori.dhall (empty when the dep declares no bound). Where
stanzas disagree, every distinct bound is reported joined by " | " -- mori holds
one single-line value, so a human resolves it.

With --json: {"packages": {name: {"path": ..., "deps": [{...}]}}}
"""

import functools
import json
import pathlib
import re
import subprocess
import sys

# GHC boot libraries and other ubiquitous packages that ship with the compiler.
# These are noise in a mori dependency graph -- they are filtered out of the
# report rather than reported as UNREGISTERED.
BOOT = {
    "array", "base", "binary", "bytestring", "containers", "deepseq", "directory",
    "exceptions", "filepath", "ghc", "ghc-bignum", "ghc-boot", "ghc-compact",
    "ghc-prim", "haskeline", "hpc", "integer-gmp", "mtl", "parsec", "pretty",
    "process", "stm", "template-haskell", "terminfo", "text", "time",
    "transformers", "unix", "Win32",
}

SKIP_DIRS = {"dist-newstyle", "dist", ".stack-work", ".git", "result"}

STANZA = re.compile(
    r"^(library|executable|test-suite|benchmark|common|custom-setup|flag|source-repository)\b",
    re.I,
)
FIELD = re.compile(r"^([A-Za-z][A-Za-z0-9-]*)\s*:(.*)")
DEPFIELDS = ("build-depends", "build-tool-depends", "setup-depends")
STANZA_SCOPE = {
    "library": "Regular",
    "executable": "Regular",
    "common": "Regular",
    "test-suite": "Test",
    "benchmark": "Test",
    "custom-setup": "Build",
}


DEP_NAME = re.compile(r"^([A-Za-z][A-Za-z0-9_-]*)")


def split_dep(item):
    """'hasql:core >=1.6 && <1.7' -> ('hasql', '>=1.6 && <1.7').

    The version bound is returned verbatim (whitespace normalized) because it is
    exactly what mori.dhall's `versionConstraint` carries: ecosystem-native text
    mori stores and displays but never parses. Sublibrary and tool qualifiers
    (`pkg:lib`, `pkg:{a,b}`) are not constraints and are dropped.
    """
    m = DEP_NAME.match(item)
    if not m:
        return None, ""
    name = m.group(1)
    rest = item[m.end():].strip()
    if rest.startswith(":"):  # pkg:sublib or pkg:{a,b} -- skip the qualifier
        rest = rest[1:].lstrip()
        if rest.startswith("{"):
            rest = rest.partition("}")[2]
        else:
            rest = rest.partition(" ")[2]
        rest = rest.strip()
    return name, " ".join(rest.split())


def parse_cabal(path):
    """Parse one .cabal file into {dep_name: {"scopes": set, "constraints": set}}."""
    deps, stanza, field, buf = {}, "library", None, []

    def flush():
        if field in DEPFIELDS and buf:
            scope = "Build" if field != "build-depends" else STANZA_SCOPE.get(stanza, "Regular")
            for item in " ".join(buf).split(","):
                item = item.strip()
                if not item or item.startswith("--"):
                    continue
                name, constraint = split_dep(item)
                # conditional keywords can trail a dep list before the next field
                if name and name.lower() not in ("if", "else", "elif"):
                    entry = deps.setdefault(name, {"scopes": set(), "constraints": set()})
                    entry["scopes"].add(scope)
                    if constraint:
                        entry["constraints"].add(constraint)

    for raw in pathlib.Path(path).read_text(errors="replace").splitlines():
        if not raw.strip() or raw.lstrip().startswith("--"):
            continue
        if not raw[:1].isspace():  # column 0 starts a stanza or a top-level field
            flush()
            buf, field = [], None
            m = STANZA.match(raw)
            if m:
                stanza = m.group(1).lower()
                continue
        m = FIELD.match(raw.strip())
        if m and (m.group(1).lower() in DEPFIELDS or field is not None):
            flush()
            buf, field = [m.group(2).strip()], m.group(1).lower()
            continue
        if field:
            buf.append(raw.strip())
    flush()
    return deps


SRP = re.compile(r"^source-repository-package\b", re.I)
LOCATION = re.compile(r"^\s*location\s*:\s*(\S+)", re.I)


def parse_cabal_project(path):
    """Parse cabal.project -> [(repo_name, owner, url)] for each pinned repo.

    Only `source-repository-package` stanzas matter here; `packages:` entries
    are the local packages, which the .cabal walk already covers.
    """
    repos, in_srp = [], False
    for raw in pathlib.Path(path).read_text(errors="replace").splitlines():
        if not raw.strip() or raw.lstrip().startswith("--"):
            continue
        if not raw[:1].isspace():
            in_srp = bool(SRP.match(raw))
            continue
        if not in_srp:
            continue
        m = LOCATION.match(raw)
        if not m:
            continue
        url = m.group(1).rstrip("/")
        if url.endswith(".git"):
            url = url[: -len(".git")]
        parts = url.split("/")
        repo = parts[-1] if parts else url
        owner = parts[-2] if len(parts) >= 2 else ""
        repos.append((repo, owner, m.group(1)))
    # the same repo can be pinned several times (one stanza per subdir)
    seen, out = set(), []
    for r in repos:
        if r[0] not in seen:
            seen.add(r[0])
            out.append(r)
    return out


@functools.lru_cache(maxsize=None)
def resolve_repo(repo, owner):
    """Git repo name -> 'namespace/project', or None.

    Corpus projects are conventionally named `<upstream>-project`, and a fork is
    pinned under the forker's account while the registry knows it by the
    upstream namespace (shinzui/streamly-project -> composewell/streamly). So
    try the bare name and the `-project`-stripped name, preferring a hit whose
    namespace matches the URL owner but accepting any exact name match.
    """
    candidates = [repo]
    if repo.endswith("-project"):
        candidates.append(repo[: -len("-project")])
    for name in candidates:
        r = subprocess.run(
            ["mori", "registry", "search", name, "--json"], capture_output=True, text=True
        )
        try:
            hits = json.loads(r.stdout or "[]")
        except json.JSONDecodeError:
            continue
        exact = [h for h in hits if h["name"] == name]
        for h in exact:  # same owner is the strongest signal
            if h["namespace"].lower() == owner.lower():
                return f'{h["namespace"]}/{h["name"]}'
        if exact:
            return f'{exact[0]["namespace"]}/{exact[0]["name"]}'
    return None


@functools.lru_cache(maxsize=None)
def resolve(dep):
    """Cabal package name -> a mori dependency name, or None.

    Returns 'namespace/project' when the cabal name IS the project, and the
    package-qualified 'namespace/project:package' when it is one package inside
    a project. Keeping that grain matters: a project-grained name is a strictly
    wider claim, and it is what makes `mori registry dependents
    'ns/project:package'` report everyone who touches any part of the project
    instead of the packages actually consumed here.

    `mori registry search` matches substrings, so only exact name matches count:
    searching "text" otherwise hits "text-iso8601" and TypeScript packages.
    """
    r = subprocess.run(
        ["mori", "registry", "search", dep, "--json"], capture_output=True, text=True
    )
    try:
        hits = json.loads(r.stdout or "[]")
    except json.JSONDecodeError:
        return None
    for h in hits:  # an exact project-name match wins
        if h["name"] == dep:
            return f'{h["namespace"]}/{h["name"]}'
    for h in hits:  # otherwise a package inside a project (usually a corpus)
        for m in h.get("matchedPackages") or []:
            if m["name"] == dep and m.get("language") in (None, "haskell"):
                return f'{h["namespace"]}/{h["name"]}:{m["name"]}'
    return None


def main(argv):
    as_json = "--json" in argv
    positional = [a for a in argv if not a.startswith("-")]
    root = pathlib.Path(positional[0] if positional else ".").resolve()

    cabals = sorted(
        p for p in root.rglob("*.cabal")
        if not any(part in SKIP_DIRS for part in p.parts)
    )
    if not cabals:
        print(f"No .cabal files found under {root}", file=sys.stderr)
        return 1
    local = {p.stem for p in cabals}

    result = {}
    for cab in cabals:
        entries = []
        for dep, info in sorted(parse_cabal(cab).items()):
            scopes = info["scopes"]
            # a dep used by both the library and its tests is Regular
            scope = "Test" if scopes == {"Test"} else ("Build" if scopes == {"Build"} else "Regular")
            if dep in local:
                target = "INTERNAL"
            elif dep in BOOT:
                target = "BOOT"
            else:
                target = resolve(dep) or "UNREGISTERED"
            # One stanza's bound is the constraint. Several disagreeing bounds
            # are reported joined by " | " -- mori's versionConstraint holds one
            # single-line value, so a human picks.
            constraint = " | ".join(sorted(info["constraints"]))
            entries.append(
                {"dep": dep, "scope": scope, "target": target, "constraint": constraint}
            )
        result[str(cab.relative_to(root))] = {
            "name": cab.stem,
            "path": str(cab.parent.relative_to(root)) or ".",
            "deps": entries,
        }

    proj = root / "cabal.project"
    if proj.exists():
        entries = []
        for repo, owner, url in parse_cabal_project(proj):
            if repo in local:
                target = "INTERNAL"
            else:
                target = resolve_repo(repo, owner) or "UNREGISTERED"
            entries.append(
                {
                    "dep": repo,
                    "scope": "Regular",
                    "target": target,
                    "constraint": "",  # a pinned repo has a commit, not a range
                    "url": url,
                }
            )
        if entries:
            result["cabal.project"] = {
                "name": "cabal.project",
                "path": ".",
                "deps": entries,
            }

    if as_json:
        print(json.dumps({"packages": result}, indent=2))
    else:
        for info in result.values():
            for e in info["deps"]:
                print(
                    f'{info["name"]}\t{e["scope"]}\t{e["dep"]}\t{e["target"]}'
                    f'\t{e.get("constraint", "")}'
                )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
