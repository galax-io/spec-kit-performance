# spec-kit-performance — research & design

Spec-driven-development (SDD) methodology for **performance/load testing**, built on GitHub spec-kit, intended to encode generic load-testing methodology patterns (retrospective inspiration) as a constitution — not yet ratified; see the status note below.

## Read in order

1. [01 — Spec-Kit, cover to cover](01-spec-kit-teardown.md) — how spec-kit actually works: layers, init flow, command pipeline, the who-calls-whom call graph, template resolution, presets/extensions/bundles/workflows.
2. [02 — SDD landscape & artifacts](02-sdd-landscape-and-artifacts.md) — spec-kit vs Kiro/BMAD/Agent-OS/Tessl/Roo; ADR/PRD/ARD/RFC/context-file definitions; SDD-for-testing prior art and the white space.
3. [03 — Prior art & inspiration](03-prior-art-inspiration.md) — a generic, retrospective catalogue of load-testing methodology patterns worth borrowing (test taxonomy, workload model, profile-from-logs, NFR/SLA contract, quality gate, SUT, role split). No specific tool or org named.
4. [04 — spec-kit-performance design](04-perf-speckit-design.md) — the proposed technology: 4-phase / 2-actor flow, the order skill, natural-language NFR → EARS → numeric gate, the automating workflow.
5. [06 — Decision: stack choice + harness](06-decision-stack-and-harness.md) — **the core answer**: own vs embed vs other (with technical drivers); how spec-kit's bidirectional review (analyze/converge) and integration model work; the campaign-vs-fleet harness model for managing the whole project.
6. [ADR-0001 — packaging approach](adr/0001-perf-testing-sdd-approach.md) — decision: ship as a spec-kit **bundle** (preset + extension), automated by a workflow.
7. [07 — Phase-1 implementation plan](07-impl-plan-phase1.md) — first buildable slice: bundle/install skeleton (integration) → constitution preset → order intake.

## TL;DR

```
A · bootstrap (load engineer)  →  B · order (customer skill)  →  C · spec & plan (load engineers)   →  D · build & run
constitution + SUT                plain-language order           NFR prose → clarify → EARS → numeric   scripts → run → gate → report
```

Two front-door actors. The **customer** files a *plain-language* order through a wiki-aware skill — no numbers required ("survive Black Friday" is enough). The **load engineers** bootstrap the repo (methodology + SUT), then take the order, check it against the methodology + SLA, write the charter with NFRs in **natural language**, and only then **quantify** them into EARS SLOs compiled to a machine-readable NFR/SLA file — giving **numeric, traceable, real pass/fail**. A constitution is intended to govern everything once ratified. Packaged as a spec-kit bundle = preset (reshape core phases) + extension (add order/sut/run/analyze/report) + workflow (gated automation).

> Methodology patterns are generic, retrospective inspiration (doc 03) — no specific platform is assumed or integrated.
>
> **Status:** [`.specify/memory/constitution.md`](../.specify/memory/constitution.md) still holds the default, uncustomized spec-kit template text and has not yet been ratified.
