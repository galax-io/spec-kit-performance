# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
