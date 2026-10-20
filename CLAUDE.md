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

A feature is an issue in `galax-io/galaxio-sdlc-backlog`. It belongs to exactly one backlog milestone whose description has the line `Release: business`. Backlog milestones without that line (the backlog's own tooling and documents) are not releases and follow "Milestones" above.

- **Feature issue.** Lists the work in every repository it touches as a checklist, one line per issue or PR: `- [ ] galax-io/<repo>#<N> → <repo milestone>`. A line is checked when that work is merged and the repository milestone it names has been released, so its tag exists.
- **Repository work.** Every issue and PR of a feature carries the version milestone of its own repository and writes `Part of galax-io/galaxio-sdlc-backlog#<feature>`. A repository ships its own version when its milestone is complete, as under "Release Process". `scripts/check-linkage.sh` skips the same-milestone rule for a link to a feature; the PR still needs its own milestone.
- **Every PR links a feature.** No PR of a product repository merges without `Part of galax-io/galaxio-sdlc-backlog#<feature>` (or a closing link to a feature); `scripts/check-linkage.sh --pr` fails it. A bot's PR (a bot author, or a `dependabot/` or `update/` branch) and the backlog's own PRs are exempt. The backlog is private, so the CI job reads it with `BACKLOG_READ_TOKEN`, a read-only token for that repository (Issues and Metadata) set as an organisation secret; without it the gate fails and says it cannot read the backlog. Maintenance and technical PRs with no feature of their own link the standing feature of the active business milestone (the issue with the label `standing`); every business milestone has one.
- **Work enters through the backlog.** A bug, an audit finding or a request is not worked on until it belongs to a feature: grouped into one or given one. An issue from outside stays in its repository, which is public, and carries the label `needs-feature` until it is linked to a feature in the backlog.
- **Feature done.** A feature issue is closed only when every line of its checklist is checked.
- **Release.** When every feature of a business milestone is closed, close the milestone and publish a GitHub Release in `galax-io/galaxio-sdlc-backlog` that lists each feature with the repository versions that carry it. Name the release and its tag by the milestone's id, the title up to its first em dash, lowercased (`M1 — first run` → `m1`).
- **Published releases are not edited.** A revert after the release is a new feature in the next business milestone.
- **Never** close a business milestone with an open feature, release a feature whose repository version is not tagged, or leave a repository version out of the release text.

