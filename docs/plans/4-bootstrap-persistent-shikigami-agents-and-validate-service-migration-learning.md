---
id: 4
slug: bootstrap-persistent-shikigami-agents-and-validate-service-migration-learning
title: "Bootstrap persistent Shikigami agents and validate service migration learning"
kind: exec-plan
created_at: 2026-09-18T14:36:35Z
intention: "intention_01m2tck9jnetav4f00csnp2871"
provenance:
  created_by:
    model: "gpt-6-astra"
    harness: "codex-cli"
    at: 2026-09-18T14:36:35Z
  revisions:
    - model: "gpt-6-astra"
      harness: "codex-cli"
      at: 2026-09-18T14:39:25Z
      mode: "other"
      note: "Grounded bootstrap in host modules and current upstream packaging, authorization, capability, and memory constraints."
    - model: "gpt-5.6-sol"
      harness: "codex-cli"
      at: 2026-09-19T13:52:04Z
      mode: "update"
      note: "Aligned with Shikigami 93d454f, qualified Keiro 0.17, current deployment gaps, and completed notification-hub benchmark."
---

# Bootstrap persistent Shikigami agents and validate service migration learning


This ExecPlan is a living document. Maintain Progress, Surprises & Discoveries, Decision Log, and Outcomes & Retrospective during implementation. Planning does not imply that Shikigami has been deployed or that its coding capabilities work.

## Purpose / Big Picture


Run one persistent, per-user Shikigami installation on this Mac, managed by this dotfiles repository. The owner can register distinct agents, submit a task for a specific repository, inspect its durable result, restart the service, and submit another task that recalls useful prior experience. The first agent assesses and begins Danwa's move from Keiro 0.15/Language 5 to the qualified Keiro 0.17/Language 6 baseline in an isolated Danwa checkout.

Completion requires a working authorized repository/tool path and evidence of learning across two runs, not merely healthy processes. A bounded Danwa coding task must produce a real diff and focused build/test evidence in an isolated checkout through Shikigami-owned execution. Danwa's existing MasterPlan and open ExecPlans remain the planning authority and must be refreshed rather than duplicated. This plan establishes the platform and proves it can undertake that work; it does not complete Danwa's entire migration or introduce fleet scheduling.

## Progress


- [ ] Milestone 1: publish reproducible per-role Shikigami packages and the durable repository-execution contract.
- [ ] Milestone 2: pin and configure the selected Shikigami revision in dotfiles.
- [ ] Milestone 3: start and rehearse the supervised server and worker roles.
- [ ] Milestone 4: install the principal directory, agent catalog, migration skill, and playbook.
- [ ] Milestone 5: demonstrate authorized coding, crash recovery, memory recall, applicability control, and agent isolation.

Implementation has not started. The current hard prerequisites are upstream packaging, completion of the writable repository harness, and a durable wrapper that admits and recovers one identified executor operation without replaying a mutation.

## Surprises & Discoveries


2026-09-19: The Shikigami revision reviewed here is `93d454fb7677dddeb3d701238289df1878a057c6`, and the authoritative `origin/master` ref resolves to the same commit. The repository has no release tags, so the deployable source must be described as an exact unreleased commit rather than as version `0.1.0.0` alone.

2026-09-19: Since the first draft, Shikigami completed its own Keiro 0.17 adoption. Its clean qualification uses Keiro 0.17.0.0, Kioku 0.7.0.0, PGMQ 0.6.1.0, Shikumi 0.4.0.0, and Baikai 0.7.0.0 from published packages. The bootstrap should consume this qualified baseline instead of planning another Shikigami runtime migration.

2026-09-19: `nix flake show --json` still fails while evaluating `packages.aarch64-darwin.default`: `callCabal2nix` is pointed at the repository root, which has seven Cabal packages and no root Cabal file. Upstream qualification proves the Cabal project, not deployable Nix role outputs.

2026-09-19: The persistent worker still supplies `emptyCapabilityRuntime`. The existing one-off path implements bounded `workspace.read`, but `mori://shinzui/shikigami/plans/48-add-a-portable-one-off-repository-agent-harness` remains incomplete for status/diff, writes, structured commands, the `shikigami-run` executable, and installation. Those are reusable prerequisites, not evidence that persistent coding works today.

2026-09-19: Danwa is a live migration case rather than a completed benchmark. Its local committed revision is `79d1c3934f93944aa6e8074130828e540983804d`; authoritative `origin/master` is `1541d9f67001ba6b214ca34bdb0b705ba7b55ed4`, so the local checkout is one documentation commit ahead. The committed service remains on Keiro 0.15.0.0 and Language 5. MasterPlan 3 has completed EP-19 through EP-23 while EP-24 and EP-25 remain unstarted.

## Decision Log


2026-09-18: Use a persistent per-user installation with separate server and worker processes under launchd, the macOS service supervisor. Reuse existing PostgreSQL and telemetry services. Add scheduler or Kafka consumer processes only when an enabled agent requires those triggers.

2026-09-18: Keep deployment/configuration in dotfiles, runtime changes in Shikigami, and migration artifacts in their target repositories. Initially keep the versioned agent catalog under config/shikigami in this repository; a dedicated catalog repository is unnecessary to prove the first two agents.

2026-09-18: Treat package reproducibility, an empty worker tool catalog, fresh per-action authorization, and durable mutation execution as explicit prerequisites to full acceptance. Do not substitute allow-all test authorization or manual off-platform work and report the agent succeeded.

2026-09-18: Link this enabling work to the active Keiro adoption intention. Preserve notification-hub's existing master plan as the migration authority; this standalone plan is not another child in that repository's dependency graph.

2026-09-19: Pin the reviewed upstream baseline to unreleased commit `93d454fb7677dddeb3d701238289df1878a057c6` unless implementation deliberately advances it after repeating the same source, package, configuration, and execution-contract audit. The seven package versions are all `0.1.0.0` and do not identify source by themselves.

2026-09-19: Reuse the safe workspace and structured-execution primitives owned by `mori://shinzui/shikigami/plans/48-add-a-portable-one-off-repository-agent-harness`, but keep durable admission, operation identity, replay, cancellation, and evidence as a separate worker integration. The one-off harness explicitly excludes durable workflows and therefore cannot be relabeled as the required adapter.

2026-09-19: Treat Shikigami's completed Keiro 0.17 qualification as the runtime baseline. The notification-hub exercise validates whether an agent can apply that migration knowledge to another repository; it does not ask Shikigami to rediscover or redo its own cohort adoption.

2026-09-19: Use notification-hub as a read-only historical benchmark. Run assessment against the recorded pre-initiative commit, score it against the completed master plan and validation evidence, and keep the mutation proof in a purpose-built disposable fixture. Do not create a competing change or mark any already-complete notification-hub plan again.

2026-09-19: Supersede the notification-hub benchmark decision at the user's request and use Danwa as both the assessment and bounded coding target. Work only in an isolated checkout at the recorded Danwa revision during bootstrap acceptance. Refresh Danwa's existing MasterPlan 3 for Keiro 0.17/Language 6 before implementing code, preserve completed children, and add one prerequisite child only if the cross-cutting cohort/language change cannot be represented honestly by the two open plans.

2026-09-19: Keep intention and plan authority repository-local. Dotfiles work retains this plan's `intention_01m2tck9jnetav4f00csnp2871`; any Danwa plan edits or implementation commits use MasterPlan 3's `intention_01m1s0hrmqe92twv5s57eb5q06` and the applicable Danwa ExecPlan trailer. Do not carry the former notification-hub association into Danwa history.

## Outcomes & Retrospective


To be completed during implementation. Distill durable host/runtime ownership, recovery, and agent-learning decisions into docs/adr before closure.

## Context and Orientation


The requested checkout is /Users/shinzui/Keikaku/dotfiles.nix; on this machine it resolves to /Users/shinzui/.config/dotfiles.nix. This plan and all paths without a Mori owner are local to that checkout. It has no docs/adr corpus or mori.dhall at planning time and no registered Mori project was found; do not invent a project identity as part of this work. Existing service conventions in docs/local-services.md, home/notion-hub.nix, home/rei.nix, and home/mina.nix supply local design context. No relevant local ADR exists.

flake.nix declares tool inputs, following the shared haskell-nix-dev toolchain. flake-modules/overlays.nix exposes Haskell executables through bin-only wrappers to prevent profile collisions. home/default.nix imports service modules. flake-modules/darwin-configurations.nix defines the SungkyungM1X host and the deliberately minimal bootstrap-arm host. home/postgresql.nix runs PostgreSQL 18 with a user socket and provides pg-ensure-db. home/victorialogs.nix ships named log files; home/victoriatraces.nix provides OTLP collection. darwin/secrets.nix owns agenix secret declarations; its values must not be copied into Nix source or logs. justfile exposes status/restart/log commands. Changed launchd definitions are stopped and waited for before Home Manager installs replacements; unchanged definitions must stay running.

home/local-web-proxy.nix already reserves shikigami on port 5219 for the documentation development server. Preserve it. The proxy listens on the LAN as well as loopback; starting a backend on loopback does not make it local-only through that proxy. Start this runtime on dedicated loopback ports without adding a proxy route. A later authenticated route is separate work.

Resolve upstream source through mori://shinzui/shikigami. Research used commit `93d454fb7677dddeb3d701238289df1878a057c6`, verified against the authoritative `origin/master` ref on 2026-09-19. The repository has no local or remote release tags; all seven Cabal packages report version 0.1.0.0, so the full commit is the only adequate current source identity. The following project-relative paths belong to that canonical project; artifact-level source/document URIs are pending. README.md identifies separate `shikigami-server`, `shikigami-worker`, `shikigami-migrate`, and `shikigami` administrative executables, plus optional scheduler and consumer roles. `cabal.project` still includes sibling Kikan-En contract/client paths, so a clean deployment source cannot rely on the developer checkout topology. `nix/haskell.nix` and `flake.module.nix` still call `callCabal2nix` on the repository root. A direct `nix flake show --json` fails because that root has no Cabal file, and the flake exports no per-role packages. There is no demonstrated packaged service in dotfiles yet.

The same upstream commit has completed `mori://shinzui/shikigami/masterplans/12-adopt-keiro-0-17-and-applicable-runtime-haskell-and-postgresql-patterns`. `docs/dependency-cohort.md` and `docs/evidence/keiro-0.17/qualification.md` record a clean public-package solve and aggregate qualification for Keiro 0.17.0.0, Kioku 0.7.0.0, PGMQ 0.6.1.0, `shibuya-pgmq-adapter` 0.16.0.0, Shikumi 0.4.0.0, and Baikai 0.7.0.0. This bootstrap must preserve that cohort and its Language 6, queue, guarded-timer, schema-isolation, API, CLI, and readiness behavior. It need not repeat the migration design, but it must re-run the upstream-supported package/build checks for the exact deployment source.

In the same upstream project, shikigami-workers/src/Shikigami/Workers/Config.hs sets AgentWorkflow.capabilities = emptyCapabilityRuntime. A declared workspace.read tool therefore cannot become a functioning worker tool through configuration alone. shikigami-agent/src/Shikigami/Agent/Capability/OneOff.hs supplies the existing bounded read-only provider, but both one-off commands use denyAllActionAuthorizer. shikigami-workers/src/Shikigami/Workers/Command/Worker.hs supports a Kikan-En/Shomei-backed authorizer; disabled authorization denies actions. Durable overlays admit observation tools only. Editing and running builds need a supported operation with durable identity and retry behavior, not a tool mislabeled as a read.

Relevant plain Markdown upstream decisions were read in mori://shinzui/shikigami: project-relative `docs/adr/0019-a-loop-that-stops-stops-the-process.md`, `docs/adr/0020-readiness-covers-only-what-restarting-can-fix.md`, `docs/adr/0025-capability-overlays-are-requests-for-additive-model-tools.md`, `docs/adr/0033-recorded-agent-principals-key-durable-state.md`, `docs/adr/0036-external-agent-actions-require-fresh-exact-authorization.md`, `docs/adr/0037-adopt-the-released-keiro-contracts-before-v1.md`, and `docs/adr/0038-runtime-startup-and-maintenance-share-validated-owners.md`. Artifact-level handles are pending because Mori concept lookup returns no registered records. Together they require fatal stopped loops, readiness limited to recoverable local dependencies, an operator-owned immutable capability catalog, principal-keyed durable state, fresh exact authorization for protected actions, the released Keiro baseline, and validated shared owners for runtime startup and maintenance. Carry these rules into implementation rather than bypassing them in wrappers.

Kioku is memory persisted across runs, not model-weight training. Upstream `shikigami-core/src/Shikigami/Agent/Run.hs` retrieves memories using agent description and task payload and renders output summary/reply as a learning. `Workflow.hs` records that output according to policy. Kioku 0.7 moves query-embedding execution to a host-owned runtime loaded through `KIOKU_AI_CONFIG`; when embedding is absent or disabled, recall falls back to keyword search. Successful completion is therefore not automatic proof that a lesson is correct, and a change in recall mode can change retrieval quality. The agent must produce evidence-bearing lessons, record the recall mode in validation evidence, and keep verified recipes in version control. Shared memory declarations are not a reason to assume cross-agent recall works.

The first workload is `mori://shinzui/danwa/masterplans/3-audit-and-align-danwa-with-current-keiro-and-haskell-patterns`. Its open children are `mori://shinzui/danwa/plans/24-harden-danwa-jobs-integration-events-and-operations` and `mori://shinzui/danwa/plans/25-prove-full-pattern-conformance-through-black-box-release-gates`. Mori locates the project checkout but cannot yet resolve these artifact URIs; preserve the intended URIs and use the registered project root plus `docs/masterplans/3-audit-and-align-danwa-with-current-keiro-and-haskell-patterns.md`, `docs/plans/24-harden-danwa-jobs-integration-events-and-operations.md`, and `docs/plans/25-prove-full-pattern-conformance-through-black-box-release-gates.md` until registry coverage catches up.

Danwa's local committed baseline is `79d1c3934f93944aa6e8074130828e540983804d`; `origin/master` currently resolves to `1541d9f67001ba6b214ca34bdb0b705ba7b55ed4`. The test uses the local committed baseline because it is the user's latest reviewed checkout, never the untracked `.mina/` state. Danwa has six application packages plus generated conformance, GHC 9.12.4, Keiro 0.15.0.0, PGMQ 0.5.0.0, and eight Language 5 specifications. Its current MasterPlan completed dependency, source-pattern, Settei, typed HTTP/OpenAPI, health, telemetry, and request-logging work. EP-24 still owns typed reconciled jobs, integration-event/outbox hardening, graceful worker supervision, and supported operations; EP-25 owns the black-box release gate. A Keiro 0.17/Language 6 adoption is cross-cutting and was not in their September 4 baseline, so the first agent run must reconcile that prerequisite with the existing MasterPlan before editing runtime code.

## Plan of Work


### Milestone 1: Prove a deployable upstream package and execution contract


Create `docs/shikigami-bootstrap.md` with a source/version and prerequisites record. Start from exact unreleased commit `93d454fb7677dddeb3d701238289df1878a057c6`; before implementation, compare it with the authoritative upstream branch and advance only through a deliberate recorded decision followed by the same audit. Resolve Shikigami and its required authorization/identity dependencies through Mori. Verify authoritative upstream refs and published package metadata before selecting pins. Do not infer that local HEAD or package version 0.1.0.0 is a release identity.

In mori://shinzui/shikigami, replace the broken root `callCabal2nix` default with explicit packages or a project-aware build that exports at least `shikigami-server`, `shikigami-worker`, `shikigami`, and `shikigami-migrate` for aarch64-darwin. Preserve optional outputs for `shikigami-scheduler`, `shikigami-consume-stream`, and `shikigami-consume-events` without starting them here. Remove the deployment build's dependence on sibling Kikan-En paths by pinning the exact compatible contract/client source or consuming a published package when one exists. Build the required binaries outside an interactive project development shell, run upstream configuration diagnostics from the packaged outputs, and repeat the supported Cabal/qualification checks for the exact source. Document an unreleased revision explicitly; never use a moving checkout for a login service.

Record the supported model provider, exact model configuration, principal-directory file, Kikan-En and Shomei endpoints, issuer/schema trust material, required credentials, migration configuration, `KIOKU_AI_CONFIG` recall configuration, health routes, and ports. Use the executable's `--describe-config`, `--check-config`, and `--explain-config` output as the configuration authority. The server serves probes on its API port; the main worker defaults to probe port 8091 unless dotfiles assigns another unused loopback port. Use existing reachable services if available; otherwise bootstrap the minimum required dependency services with their own readiness and persistence checks. An unanswered dependency inventory is not a completed milestone. Do not enable unrelated Kafka/stream consumers to make the deployment resemble the full platform.

Complete or consume the repository primitives from `mori://shinzui/shikigami/plans/48-add-a-portable-one-off-repository-agent-harness`: bounded reads, status/diff, stale-write-safe edits, structured allowlisted commands without a shell, instruction discovery, and a typed result. Then add an upstream persistent-worker contract that installs the observation providers in the operator catalog and submits mutations through a durable coding-task adapter. The adapter submits an identified task to an explicitly configured coding executor, persists an operation ID and executor job handle before waiting, polls results, and recovers the same job after restart. Repeated submissions of one operation must not start another writer. Repository/revision, authorized scope, artifact destinations, timeout, cancellation, and result evidence must be explicit inputs. The executor may be an existing supported coding harness; inspect its local source/configuration before selecting it. The plan requires the integration, not a new coding model. Keep one active mutation task per repository with durable ownership. Do not run unjournaled edits inside a replayed workflow step or observation callback.

Where capabilities beyond Plan 48 are missing, create linked upstream ExecPlans using the upstream local skill and record their canonical `mori://shinzui/shikigami/plans/...` references here. This plan remains incomplete while Plan 48 or the durable integration is unavailable; do not hide that gap behind a host-only completion. Milestone acceptance is reproducible per-role binaries plus an executable contract test proving real bounded reads, a verified write/build result, duplicate-task recovery, unauthorized-action refusal, stale-revision refusal, and cancellation cleanup. Record exact upstream commits and commands in the bootstrap document.

### Milestone 2: Package and configure the persistent installation


Add a pinned shikigami input to flake.nix and lock only required inputs. Follow the shared toolchain input convention after verifying actual upstream inputs. Expose all required role outputs in flake-modules/overlays.nix; do not assume packages.default contains them all. Add home/shikigami.nix and import it from home/default.nix. Use immutable binaries, an explicit working directory and PATH, and per-process environment. Starting a role must not invoke cabal run, nix develop, a shell profile, or a mutable development checkout.

Provide XDG configuration at `~/.config/shikigami`, writable state at `~/.local/state/shikigami`, and writable task artifacts beneath that state directory. Install one public YAML configuration file plus separate mode-0600 secret YAML files rather than placing secret values in a plist. Use a dedicated `shikigami` database on the existing PostgreSQL 18 server. The composed migration executable owns its Kioku/Keiro/framework schemas; do not create a second independently managed memory schema. Add `shikigami-db-setup` using `pg-ensure-db` and the packaged migration executable. Serialize provisioning before starting runtime roles. The migration binary uses `DATABASE_URL`; runtime roles use `PG_CONNECTION_STRING`. Export each explicitly in the appropriate wrapper, not a global generic database variable.

Use packaged role `--describe-config`, `--check-config`, and `--explain-config` output to validate settings and precedence. The pinned schema includes `SHIKIGAMI_AGENTS_DIRECTORY`, `SHIKIGAMI_AGENTS_STRICT`, `SHIKIGAMI_DIRECTORY_MODE`, `SHIKIGAMI_DIRECTORY_FILE_PATH`, `SHIKIGAMI_HTTP_HOST`, `SHIKIGAMI_HTTP_PORT`, `SHIKIGAMI_HEALTH_PORT`, `SHIKIGAMI_BEHAVIOR_PROVIDER`, `SHIKIGAMI_BEHAVIOR_MODEL`, and `SHIKIGAMI_ACTION_AUTHORIZATION_MODE`; resolve all other bindings from that executable schema rather than copying a stale list. Keep per-role health-port overrides out of a shared file so optional workers do not collide. Select real provider mode for acceptance; stub mode is only a separately labeled diagnostic. Configure Kioku's host-owned recall runtime through `KIOKU_AI_CONFIG` and record whether the proof uses hybrid embeddings or keyword fallback. Read provider and authorization credentials from agenix-managed runtime files; never embed their bytes in generated derivations or plists. Preserve bootstrap-arm's independence from decryptable secrets.

Milestone acceptance is Nix evaluation and system build plus role configuration checks under a minimal launchd-like environment. Missing credentials or invalid manifests must produce bounded actionable failures without leaking their contents. The deployment input must remain unchanged when the upstream development checkout changes.

### Milestone 3: Start supervised roles with persistence and observability


Declare `com.shinzui.shikigami-server` and `com.shinzui.shikigami-worker` user launchd agents. Allocate unused loopback API and worker-health ports and record them; keep 5219 for docs. The server serves `/health/live` and `/health/ready` on its API port, while the worker uses its own probe listener. Give each role `RunAtLoad`, crash restart with backoff, a bounded shutdown grace period, explicit logs, and dependency readiness handling. Copy the changed-plist-only stop/wait pattern from existing services. Preserve Shikigami's fatal-loop rule: if a supervised worker loop stops making progress, the process must become unhealthy or exit so launchd can restart it. Check server and worker liveness and readiness individually; a listening API does not prove the worker can execute tasks.

Add log shippers in home/victorialogs.nix and service-specific OTLP environment using the existing collector. Add just recipes status-shikigami, logs-shikigami, restart-shikigami, check-shikigami and provision-shikigami. These must inspect the real registered roles, not only test whether binaries exist. Document setup, task submission, run inspection, and recovery in docs/shikigami-bootstrap.md and docs/local-services.md. Keep scheduler and stream consumers disabled unless the first manifests require them.

Validate migrations twice, an unchanged dotfiles activation, a changed service definition, process termination, and a host login/reboot rehearsal. Sessions and memories must persist, one worker generation must remain active, and an intentional loop failure must become visible and restartable. A healthy process that has silently lost its worker loop is a failure. Missing PostgreSQL or authorization dependencies must not turn task attempts into successful empty results.

### Milestone 4: Install a reusable catalog and the migration agent


Create `config/shikigami/agents/keiro-migrator.dhall`, `config/shikigami/skills/keiro-migration/SKILL.md`, and `config/shikigami/playbooks/keiro-0.17.md`. Seed the playbook from the qualified Shikigami cohort and Danwa's current 0.15/Language 5 evidence, retaining canonical source URIs, exact revisions, applicability conditions, and known counterexamples rather than copying conclusions without provenance. Add a small independent observer agent for multi-agent admission/isolation tests, with no repository mutation authority. Render/install these declaratively through `home/shikigami.nix`. Agent names locate declarations; assign and retain verified principal identity through file-backed directory mode and run `shikigami agents sync` so renaming does not fork memory. Declare exactly the installed capabilities, and validate all enabled manifests strictly before worker startup.

The migration skill accepts a canonical repository URI, expected source commit, deployment status evidence, target release, requested phase, task ID and optional existing plan URI. The worker resolves repository access against the operator-owned workspace map; model text cannot grant itself a new filesystem root. Include Mori access through a bounded supported observation provider or trusted task-context resolver so dependency lookup does not assume unrestricted filesystem traversal. Treat plans and source documents as task input, not authority to change grants.

Separate assess, plan, implement-one-milestone and distill phases. Assessment compares actual dependency pins and capabilities against the versioned playbook. Planning follows target-repository skills and reuses an existing current plan rather than creating duplicates. Implementation takes one named milestone and records files changed, checks performed, failures and remaining work. Distillation records a lesson with applicability conditions, source/target versions, source revisions, evidence references, and observed versus verified status. Upstream cohort changes invalidate relevant recipes until rechecked.

Use agent-scoped Kioku memory for observations and failure history; use version-controlled playbooks for verified procedures and target-repository ADRs for durable local decisions. If renderLearning prefers a summary string, ensure that summary preserves evidence/status and links to the complete result so structured evidence is not silently discarded. A process exit or a plausible model answer cannot promote a lesson to verified. Adding the observer agent must require only a new declaration/configuration, with independent memory and no implicit sharing of migration authority.

Milestone acceptance validates both declarations, submits tasks through the real persistent worker, and demonstrates useful repository-specific assessment with file/source evidence. A fixture-only heartbeat or a prewritten answer is insufficient.

### Milestone 5: Demonstrate coding, recovery and useful learning across runs


Add `scripts/check-shikigami-bootstrap.sh` and a `just smoke-shikigami` recipe. The script creates a disposable Danwa checkout at `79d1c3934f93944aa6e8074130828e540983804d`, registers only that checkout in the operator workspace map, and uses an isolated test-task namespace. Submit an assessment referencing Danwa MasterPlan 3 and open EP-24/EP-25. The result must identify the actual Keiro 0.15.0.0, PGMQ 0.5.0.0, GHC 9.12.4, eight Language 5 specifications, completed EP-19 through EP-23 contracts, and the two open children. It must compare them with the qualified 0.17 cohort and explain which existing decisions remain valid, which plan sections are stale, and why changing dependency versions before reconciling the MasterPlan would be unsafe.

Use the planning phase in the isolated checkout to update MasterPlan 3 comprehensively. Preserve completed child history and existing ADR authority. If the 0.17 cohort and Language 6 move require cross-cutting work before EP-24, create one new prerequisite ExecPlan with Danwa's local `exec-plan` skill, add its canonical intended `mori://shinzui/danwa/plans/...` URI to the task evidence, and update EP-24/EP-25 dependencies and context. Do not create a competing MasterPlan or silently fold the upgrade into an operations milestone.

Then ask the coding adapter to implement only the first independently verifiable milestone of that refreshed prerequisite plan: resolve and record the released cohort, move the controlled Keiro DSL source to 0.17/Language 6 as the plan specifies, and obtain the focused solver/build/generation evidence required by that milestone. All edits remain in the disposable checkout for review. A useful assessment or a dependency failure is evidence but is not successful coding acceptance; acceptance requires a real Danwa diff and at least one focused build or generated-conformance check that passes. Do not mark the prerequisite, EP-24, EP-25, or MasterPlan complete from this slice.

Interrupt the worker after an executor job is accepted but before its result is collected. On restart it must reconnect to that same operation; prove there is no duplicate checkout writer, duplicate accepted task, or invented result. Test timeout/cancellation and keep external-job state inspectable if cancellation is uncertain. Kill a model attempt separately; a retried observation may repeat, while mutation replay follows the durable executor contract.

After recording the first Danwa task's lesson, restart the service and submit a second controlled Danwa assessment against the resulting checkout and next unimplemented milestone. Capture the recalled memory ID and show the answer applies the cohort/language lesson with its evidence without assuming every new 0.17 feature applies. In particular, grouped FIFO, partitioning, workflow timers, and other optional runtime capabilities require Danwa domain evidence; availability in Keiro or use by Shikigami is insufficient. Submit the same recall question to the observer agent and prove its private memory is separate. Run an otherwise equivalent fresh-memory baseline and compare repeated mistakes, useful evidence, and operator corrections; report measurements without promising a speedup from two runs.

Exercise a negative authorization case and confirm no provider/tool mutation occurs. Verify credential-free logs and trace continuity from task submission through completion. Record run/session/task IDs, binary and model revisions, Kioku recall mode, memory IDs, Danwa starting commit, resulting diff identity, plan path/URI, check outputs, and artifact paths in `docs/validation/shikigami-bootstrap.md`. Finish with supported commands for handing the reviewed Danwa prerequisite milestone to the agent again or exporting the isolated diff for a human-reviewed Danwa change. Distill host ownership, immutable deployment, durable coding operations, and evidence-based learning into a local ADR after inspecting the then-current ADR convention.

## Concrete Steps


Run from this dotfiles checkout. The new scripts and just recipes below are deliverables, to create before invoking them. Discovery and verification must remain scoped; never inspect or traverse /nix/store.

```bash
cd /Users/shinzui/Keikaku/dotfiles.nix
mori registry show shinzui/shikigami --full
mori registry show shinzui/kikan-en --full
mori registry show shinzui/shomei --full
mori registry show shinzui/danwa --full
nix eval --raw .#darwinConfigurations.SungkyungM1X.config.system.build.toplevel.drvPath
nix build .#darwinConfigurations.SungkyungM1X.system --no-link
just provision-shikigami
just check-shikigami
just status-shikigami
just smoke-shikigami
```

The system evaluation/build must succeed without starting anything. Nix evaluates tracked source: include newly created implementation files in the working index before those checks, without staging unrelated edits. Validate bootstrap-arm evaluation as well. Activate the built host configuration using the repository's established darwin-rebuild switch procedure only once configuration, artifacts and checks are ready; activation is a separate machine-changing step, not part of creating this plan. Record the exact activation command and selected ports in the bootstrap guide.

The check recipe must fail on missing database, missing model credentials, missing or invalid `KIOKU_AI_CONFIG`, unsupported capabilities, invalid authorization, wrong agent revision, or an unrecorded Danwa starting commit. The smoke script returns nonzero for every unmet assertion and prints concise named PASS/FAIL results for service health, genuine Danwa repository read, current-plan assessment, isolated plan revision, actual Danwa coding task, focused build/generation evidence, restart recovery, memory recall, applicability control, and agent isolation. It must never silently skip unavailable services or treat a stub model as live-provider acceptance. Use supported commands such as `shikigami enqueue-run`, `shikigami runs show`, `shikigami wf show`, and the health endpoints rather than direct framework-table mutations for task inspection.

## Validation and Acceptance


Completion means the login-managed server/worker use pinned binaries and explicit configuration; fresh and repeated provisioning preserve data; both agents can be admitted and run; the migrator assesses Danwa's current plans and source at the recorded commit; the planning phase refreshes the existing MasterPlan without duplicating it; the coding adapter changes an authorized disposable Danwa checkout and passes the first milestone's focused check; and a second run recalls evidence after process restart and applies it conditionally. Logs and traces identify the task without credentials. The original Danwa checkout and its untracked `.mina/` state remain unchanged. Existing PostgreSQL consumers, dotfiles services, and the Shikigami docs route continue to work.

Packaging alone, a heartbeat, manually copying a model answer into Kioku, manually executing the Danwa task outside the adapter, changing only prose, a solver failure without a passing focused check, and a passing unit test for a fake provider are all insufficient as final evidence. Use such tests for diagnosis but label them honestly. Keep unresolved upstream prerequisites visible in Progress and the bootstrap guide. Full Shikigami conformance remains upstream-owned, and the full Danwa upgrade remains owned by its refreshed MasterPlan; this plan claims only deployment and the measured first-milestone learning proof.

## Idempotence and Recovery


Provision only the dedicated database; never reset the shared PostgreSQL cluster or developer service databases. Rerun migrations through their checksummed ledger. Keep catalog/playbook revisions with task evidence and retain provider revisions still referenced by in-flight work. Dotfiles updates must not switch an executor's code mid-operation. Before changing a runtime revision, drain or checkpoint active jobs and keep the old binaries available for recovery.

Rollback the new host modules/input revision without deleting durable Shikigami/Kioku data. Do not assume reverting a binary reverts database migrations: verify backward compatibility, otherwise restore the dedicated database from a tested backup with the matching binary while preserving the failed generation's evidence. Fixture cleanup may remove only resources created by the smoke script and must wait for associated executor jobs to stop. Reconcile uncertain jobs by operation ID, never by submitting a fresh mutation spec and hoping the first stopped.

## Interfaces and Dependencies


`home/shikigami.nix` owns service enablement, immutable binary selection, per-role environment, agent/config paths, ports, runtime secret-file references, Kioku AI runtime file selection, and optional trigger-role flags. `config/shikigami` owns declarations, instructions, and playbooks, not mutable memories or credentials. `scripts/check-shikigami-bootstrap.sh` owns bounded acceptance scenarios and result collection. `docs/shikigami-bootstrap.md` is the operator runbook; `docs/validation/shikigami-bootstrap.md` is observed evidence.

`mori://shinzui/shikigami` owns the tool catalog, task admission, durable workflow/session lifecycle, executor adapter, and supported operator commands. `mori://shinzui/shikigami/plans/48-add-a-portable-one-off-repository-agent-harness` owns the reusable local-worktree primitives but is incomplete at this revision. `mori://shinzui/kioku` owns memory/session persistence and its host-configured AI recall runtime; `mori://shinzui/kikan-en` and `mori://shinzui/shomei` own protected-action policy and authentication. Inspect required identity integration through Mori before provisioning it. The deployment starts from Shikigami's qualified Keiro 0.17/Kioku 0.7 cohort and records any deliberate advancement. Dotfiles must not duplicate these domains in shell scripts.

`mori://shinzui/danwa` owns the target code, MasterPlan, ExecPlans, ADRs, validation evidence, and resulting migration decisions. Shikigami may edit only the disposable registered Danwa checkout during acceptance. Exported changes remain review artifacts until deliberately applied in Danwa under its own plan and intention; this dotfiles plan never substitutes for Danwa's progress or completion records.

The coding adapter's minimum result contract includes operation ID, executor job ID, canonical repository URI, starting and resulting revision/diff identity, outcome, named check results, artifact references and cancellation state. A second request with identical operation and payload returns the same job; changed payload conflicts. Agent result artifacts additionally carry run/session identity, recalled/evidence memory IDs, lesson status and applicability. Define/version these contracts in the upstream owner and test restart behavior before the host depends on them.

Revision note (2026-09-19): Updated the plan to Shikigami commit `93d454fb7677dddeb3d701238289df1878a057c6`, its qualified Keiro 0.17/Kioku 0.7 baseline, current Settei and health contracts, the still-broken multi-package Nix output, and the incomplete writable/durable execution prerequisites. Recast the now-complete notification-hub migration as a read-only historical benchmark and moved mutation acceptance to a disposable fixture so the plan cannot duplicate completed work.

Revision note (2026-09-19): Replaced the notification-hub benchmark with the user's selected Danwa test. Grounded the scenario in Danwa revision `79d1c3934f93944aa6e8074130828e540983804d`, its Keiro 0.15/Language 5 baseline, completed EP-19 through EP-23 work, and open EP-24/EP-25 scope. The test now refreshes the existing Danwa MasterPlan for 0.17/Language 6 and implements only the first verified prerequisite milestone in an isolated Danwa checkout.
