# spec-kit-performance

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Status](https://img.shields.io/badge/status-research%20%26%20design-orange.svg)](docs/README.md)
[![Built on](https://img.shields.io/badge/built%20on-spec--kit-6f42c1.svg)](https://github.com/github/spec-kit)

A **spec-driven-development (SDD) methodology for performance / load testing**, built on
GitHub [spec-kit](https://github.com/github/spec-kit). It encodes generic load-testing
methodology patterns as a ratified **constitution** and ships them as a spec-kit bundle —
so a load-testing engagement runs as a governed, traceable, gated pipeline instead of a
pile of ad-hoc scripts.

> **Status: research & design.** No production code yet. The design lives in [`docs/`](docs/README.md).
> Methodology content is generic, retrospective inspiration — no specific platform, tool, or
> org is assumed or integrated.

## The pipeline — 4 phases, 2 front-door actors

```
A · bootstrap (load engineer)  →  B · order (customer skill)  →  C · spec & plan (load engineers)   →  D · build & run
constitution + SUT                plain-language order           NFR prose → clarify → EARS → numeric   scripts → run → gate → report
```

- **Customer** files a *plain-language* order through a wiki-aware skill — no numbers required
  ("survive Black Friday" is enough).
- **Load engineers** bootstrap the repo (methodology + system-under-test), take the order, write
  the charter with NFRs in natural language, then **quantify** them into EARS SLOs compiled to a
  machine-readable `nfr.yml` — giving **numeric, traceable, real pass/fail** acceptance.
- A ratified **constitution** governs everything.

## Packaging

Shipped as a spec-kit **bundle**:

| Layer | What it does |
|-------|--------------|
| **preset** | Reshapes core spec-kit phases (constitution / specify / clarify / plan / tasks / implement) for the perf domain |
| **extension** | Adds new phases: `perf.order`, `perf.sut`, `perf.run`, `perf.analyze`, `perf.report` |
| **workflow** | Gated automation chaining the phases end to end |

## Everything through the spec-kit CLI

Every capability is discoverable, installable, and runnable **only** via `specify` — no bespoke
installers, no manual file copying as a supported path.

```bash
# Discover
specify preset search perf
specify extension search perf

# Install
specify init --preset perf
specify extension add <id>

# Run
specify workflow run        # or the /speckit.* agent commands
```

Distribution is the spec-kit catalog (public repo + GitHub Release zip + a PR to
`catalog.community.json`), surfaced by `specify ... search`.

## Repository layout

```
docs/            Design docs and ADRs (start here)
.specify/        spec-kit scaffolding: constitution, templates, scripts, extensions, workflows
.claude/skills/  speckit-* command skills
CLAUDE.md        Guidance for Claude Code working in this repo
```

## Documentation — read in order

1. [01 — Spec-Kit, cover to cover](docs/01-spec-kit-teardown.md) — how spec-kit works: layers, init flow, command pipeline, presets/extensions/bundles/workflows.
2. [02 — SDD landscape & artifacts](docs/02-sdd-landscape-and-artifacts.md) — spec-kit vs Kiro / BMAD / Agent-OS / Tessl / Roo; ADR / PRD / RFC / context-file vocabulary.
3. [03 — Prior art & inspiration](docs/03-prior-art-inspiration.md) — generic, retrospective catalogue of load-testing methodology patterns worth borrowing.
4. [04 — spec-kit-performance design](docs/04-perf-speckit-design.md) — the proposed 4-phase / 2-actor flow, the order skill, NFR → EARS → numeric gate.
5. [06 — Decision: stack choice + harness](docs/06-decision-stack-and-harness.md) — own vs embed vs other; the campaign-vs-fleet harness model.
6. [ADR-0001 — packaging approach](docs/adr/0001-perf-testing-sdd-approach.md) — decision to ship as a bundle (preset + extension), automated by a workflow.

Full index: [`docs/README.md`](docs/README.md).

## License

[Apache-2.0](LICENSE). See [NOTICE](NOTICE) for attribution.
