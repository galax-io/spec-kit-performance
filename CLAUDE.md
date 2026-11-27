# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Constitution:** the principles of this repository are in `.specify/memory/constitution.md`; where they conflict with this file, the constitution wins.

## Project

`spec-kit-performance` — designing a **spec-driven-development (SDD) methodology for performance/load testing**, built on GitHub [spec-kit](https://github.com/github/spec-kit) and intended to encode generic load-testing methodology patterns (retrospective inspiration) as a "constitution". No specific platform/tool/org is assumed or integrated. That constitution has not been ratified: `.specify/memory/constitution.md` still holds the default, uncustomized spec-kit template text.

Currently a **research & design repo** (no code yet). Design lives in [docs/](docs/README.md):
- `docs/01-spec-kit-teardown.md` — how spec-kit works cover-to-cover (call graph, presets/extensions/bundles/workflows).
- `docs/02-sdd-landscape-and-artifacts.md` — SDD framework comparison + ADR/PRD/RFC/context-file vocabulary.
- `docs/03-prior-art-inspiration.md` — generic load-testing methodology patterns worth borrowing (inspiration only).
- `docs/04-perf-speckit-design.md` — the proposed design (4-phase / 2-actor flow).
- `docs/adr/0001-perf-testing-sdd-approach.md` — packaging decision (ship as a spec-kit **bundle** = preset + extension).

## Target pipeline (4 phases, 2 front-door actors — see docs/04)

```
A bootstrap (load engineer)  →  B order (customer skill → order.md)  →  C spec & plan (load engineers)  →  D build & run
constitution + SUT              plain-language order (Confluence)     NFR prose → clarify → EARS → nfr.yml   scripts → run → gate → report
```

Core spec-kit phases (constitution/specify/clarify/plan/tasks/implement) are **reshaped via a preset** for the perf domain; new phases (perf.order/perf.sut/perf.run/perf.analyze/perf.report) are **added via an extension**; both packaged as a **bundle**, automated by a spec-kit **workflow**. The customer states NFRs in **plain language** (low-friction order skill, no numbers required); load engineers **quantify** them into **EARS SLOs** compiled to `nfr.yml` for numeric, traceable pass/fail acceptance.

## HARD RULE — everything through the spec-kit CLI (`specify`)

Every capability MUST be discoverable, installable, and runnable **only** via `specify`:
- **Discover:** `specify preset|extension search`. **Install:** `specify preset|extension add <id>` / `specify init --preset perf`. **Run:** `/speckit.*` (agent) or `specify workflow run`.
- No bespoke installers, no manual file copying as a supported path, no out-of-band binaries. Every feature is expressed as a preset override / extension command+hook / workflow / catalog metadata. (Exception: MCP connectors + the agent, invoked inside spec-kit commands.)
- **Distribution = spec-kit catalog** (public repo + GitHub Release zip + a PR to `catalog.community.json`), surfaced by `specify ... search`. This is NOT Maven Central — the sbt/Maven release rules below apply only to a separate compiled Scala helper-lib component, if any.

## Constitution = inspiration, not a system

The constitution's *content* is drawn from generic load-testing methodology patterns (test taxonomy, workload model, profile-from-logs, NFR/SLA contract, quality gate, SUT, role split) — see `docs/03`, retrospective inspiration only. spec-kit-performance adopts no specific platform; the execution backend (load generator, CI, results/quality-gate) is pluggable. Public tools may be named as examples (Gatling, k6, EARS, OpenSLO).

## Release Process (MANDATORY)

TBD with `release/*` branches cut from `main`. A `vX.Y.Z` tag on a `release/*` branch → Maven Central (`sbt-ci-release`/`dynver`) + GitHub Release (`git-cliff`).

- **Minor/major:** `git checkout -b release/X.Y.0 main` → `git tag vX.Y.0` → `git push origin vX.Y.0`.
- **Patch:** fix on `main` first → `git cherry-pick <sha>` onto `release/X.Y.0` → `git tag vX.Y.1` → push.

Rules:
- One `release/X.Y.0` per minor; branch name must match tag (`release/1.2.0` → `v1.2.x`).
- Tags only on `release/*`, never on `main` (`release.yml` validates).
- Keep `release/*` rebased on `main`; on any conflict/problem, check `main` hasn't moved ahead, then rebase.
- Red pipeline → fix first: `git commit --amend` the red commit; never tag on red.
- Never delete a tag after Sonatype deploy starts; never reuse a version.

## Environment note

`.claude/settings.local.json` allows `rtk ls` / `rtk read` without prompts.

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
<!-- SPECKIT END -->

## Feature milestones (ALWAYS)

A feature is an issue in `galax-io/galaxio-sdlc-backlog`. It belongs to exactly one backlog milestone whose description has the line `Release: business`: that milestone is its release.

- **Trunk-based.** `main` is the trunk: every PR, a feature's, a fix, a bot's or CI, is opened into `main` from a short-lived branch. Unfinished behaviour is not merged or stays behind a flag. The PR of a feature writes `Part of galax-io/galaxio-sdlc-backlog#<feature>`, which records it in the feature.
- **Work enters through the backlog.** A bug, an audit finding or a request is not worked on until it belongs to a feature: grouped into one or given one. An issue from outside stays in its repository and carries the label `status:needs-feature` until it is linked to a feature in the backlog.
- **Release.** The backlog's `scripts/release-build.sh <release>` gives this repository the next minor, `vX.Y.0`, when `main` has commits after its last tag, and runs the phase `prepare` in every such repository: `release/X.Y.0` is cut from `main` and this repository's checks run on it. Only when every repository is green does it run `publish` everywhere: the tag is set on the head `prepare` checked and the GitHub Release is made; `main` is not touched and the branch stays. A red check in one repository publishes nothing anywhere. The backlog's release of the milestone lists each repository's version and links its GitHub Release.
- **Patch.** A fix of a released version is a PR into `main` first, then `git cherry-pick -x` onto `release/X.Y.0` by a PR into that branch; `prepare` and `publish` with `vX.Y.Z` tag it there. A release branch is never merged into `main`.
- **Feature done.** The feature's documents PR in the backlog writes `Closes galax-io/galaxio-sdlc-backlog#<feature>` and is merged last; the work's PRs here write `Part of`.
- **Published releases are not edited.** A fix after the release is a patch on the release branch or the next release; a tag is never moved.

## Labels (ALWAYS)

One label scheme for every repository of the organization: `scripts/labels.json` in `galax-io/galaxio-sdlc-backlog`. A label says what the milestone and the feature link do not: the kind of work, its topic, how bad it is, where it stands.

- **Names.** Every label is `group:value`. Labels a tool owns (GitHub's `good first issue` and `help wanted`, Dependabot's, and those code reads, listed as `reserved`) are left alone.
- **Exactly one `type:*` on every open issue:** `bug`, `enhancement`, `docs`, `maintenance`, `question`; in the backlog `type:feature` (an issue of a business milestone) or `type:standing` (the standing feature of an older milestone). An issue without a type is not triaged.
- **At most one each:** `severity:*` (`critical`, `high`, `medium`, `low`: the impact, not the order of work), `status:*` (`needs-triage`, `needs-info`, `needs-feature`, `ready-for-agent`, `ready-for-human`, `blocked`), `tier:*`.
- **Any number:** `area:*` (topics shared by every repository), `module:*` (parts of one repository, declared in the scheme), `source:external`, `source:audit`.
- **Not labels.** The order of work is the milestone: no `priority:*`. The feature is the `Part of` link: no `feature:*`. A rejected or duplicate issue is closed with that reason and a comment: no `wontfix`, `invalid`, `duplicate`.
- **The engine's labels** `sdlc:*` live in the backlog: only the engine sets `sdlc:gate`, `sdlc:done` and `sdlc:failed`. The label of a run's workflow, `workflow:<pipeline name>`, is the maintainer's to set, at most one on an intent; the engine never sets or removes it.
- **A new label is a change to the scheme**, a PR to `scripts/labels.json`, not a label made in one repository. `scripts/sync-labels.sh` applies the scheme; `--check` lists what breaks it.
