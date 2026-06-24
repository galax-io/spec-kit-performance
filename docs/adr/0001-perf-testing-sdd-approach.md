# ADR-0001: Packaging approach for a spec-driven performance-testing workflow

**Status:** Proposed
**Date:** 2026-06-24
**Deciders:** Performance engineering lead, QA lead, platform owner

## Context

We want a spec-driven-development (SDD) workflow for **performance/load testing**: an ordering team answers questions about what to test (and what not to), the answers become a reviewable charter attached to a work item, a ratified load-testing methodology ("constitution") governs the work, and the chain proceeds spec → plan → tasks → implementation → run → report, emitting Gatling/k6 scripts and a gated NFR report.

Forces at play:

- Mature load-testing methodology *patterns* are well understood (test taxonomy, workload model, profile-from-logs, an NFR/SLA contract, a quality gate, SUT definition, role split). We should encode these patterns, not reinvent them — but generically, naming no specific platform. (See [doc 03](../03-prior-art-inspiration.md), retrospective inspiration.)
- [GitHub spec-kit](https://github.com/github/spec-kit) provides an agent-agnostic SDD chassis with four documented extension seams: **preset** (reshape commands/templates), **extension** (add commands + hooks), **bundle** (package by role), **workflow** (automate the chain). (See [doc 01](../01-spec-kit-teardown.md).)
- No existing tool does spec-first perf testing end-to-end; the pieces exist in isolation (EARS, k6 thresholds/OpenSLO, BMAD TEA, PRO-TEST, k6 MCP). (See [doc 02](../02-sdd-landscape-and-artifacts.md).)
- The perf workflow needs **two kinds of change** to core spec-kit: (1) *reshape* the meaning of constitution/specify/plan/tasks/implement for the perf domain, and (2) *add* phases that don't exist in core (define SUT, run tests, gate on NFRs, report).

## Decision

**Ship `spec-kit-performance` as a spec-kit *bundle* = a preset (reshape) + an extension (new phases), automated by a shipped workflow. Encode generic load-testing methodology patterns (doc 03) as the constitution. Adopt EARS notation for SLOs and a machine-readable NFR/SLA file + quality gate for numeric acceptance.**

Concretely:
- **Preset** overrides `constitution / specify / clarify / plan / tasks / implement` templates for the perf domain.
- **Extension** adds `speckit.perf.sut / .run / .analyze / .report` commands + lifecycle hooks.
- **Bundle** packages both, versioned, installable via `specify init --preset spec-kit-performance` (or bundle install).
- **Workflow** `spec-kit-performance` chains the phases with perf-team approval gates and a `do-while` retest loop.

## Options Considered

### Option A: Preset only
Reshape the six core commands; cram "run/analyze/report" into `implement`.

| Dimension | Assessment |
|-----------|------------|
| Complexity | Low |
| Coverage | Poor — no clean home for SUT-intake, execution, gating, reporting |
| Team familiarity | High |
| Reversibility | Easy |

**Pros:** Simplest; pure layering, no new commands. **Cons:** Execution/gate/report are first-class perf phases, not sub-steps of implement; hooks (before_specify→sut, after_implement→run) impossible without an extension; conflates "write scripts" with "run + judge".

### Option B: Extension only
Add all perf phases as new `speckit.perf.*` commands; leave core commands untouched.

| Dimension | Assessment |
|-----------|------------|
| Complexity | Medium |
| Coverage | Partial — new phases fine, but specify/plan/tasks still emit *app-feature* artifacts |
| Team familiarity | Medium |
| Reversibility | Easy |

**Pros:** Clean new commands + hooks. **Cons:** The core spec/plan/tasks templates still talk about user stories and code; a perf charter (methodology sections, EARS SLOs, workload model) needs the *templates* reshaped — which is exactly what presets do. Users would run a confusing mix of generic and perf commands.

### Option C: Bundle = Preset + Extension *(chosen)*
Reshape core (preset) **and** add perf phases (extension), packaged as a versioned bundle, automated by a workflow.

| Dimension | Assessment |
|-----------|------------|
| Complexity | Medium-high |
| Coverage | Full — every phase has a correct home; hooks available; one-command install |
| Team familiarity | Medium |
| Reversibility | Moderate (uninstall bundle) |

**Pros:** Each concern in its native seam; rides documented APIs (no core fork); agent-agnostic; versionable; workflow automates the gated chain. **Cons:** Most moving parts; must track spec-kit version compatibility (`requires.speckit_version`); preset + extension naming/coordination overhead.

### Option D: Standalone framework (fork or greenfield)
Build a bespoke perf-SDD tool, or adopt/fork BMAD-METHOD's TEA test-architect.

| Dimension | Assessment |
|-----------|------------|
| Complexity | High |
| Coverage | Full, but all maintenance is ours |
| Team familiarity | Low |
| Reversibility | Hard |

**Pros:** Total control; could deeply integrate a chosen results backend. **Cons:** Throws away spec-kit's agent integrations, template resolution, and workflow engine; high build + maintenance cost; reinvents the chassis. BMAD TEA's automation layer assumes Playwright/Cypress and would need a Gatling/k6 reskin anyway.

## Trade-off Analysis

The decisive factor is **fit of concern to seam**. Perf testing genuinely needs *both* a re-skin of the existing phases (charter ≠ feature spec) *and* net-new phases (define-SUT, run, gate, report) with hooks — so neither preset-only (A) nor extension-only (B) covers it without distortion. A standalone framework (D) would cover it but discards the chassis we get free from spec-kit (30+ agent integrations, template layering, workflow engine, numbering/pathing scripts) and incurs perpetual maintenance. The bundle (C) is the only option that places each concern in its intended mechanism while reusing the chassis and staying agent-agnostic. Its extra complexity is bounded and tracks documented APIs.

Cross-cutting decisions (apply to all options, locked here):
- **Constitution = generic methodology patterns** (doc 03) — encode the patterns, not a specific platform.
- **NFRs start in plain language**, then quantified to **EARS SLOs** compiled to a machine-readable NFR/SLA file — gives numeric, machine-checkable acceptance and need→result traceability, defeating the prose-spec verification gap.
- **Gate = a quality-gate verdict** floored by service criticality, surfaced as PASS/CONCERNS/FAIL/WAIVED (the backend is pluggable).

## Consequences

**Easier:**
- Each perf phase has a correct, discoverable home; one-command install; gated automation via the workflow engine.
- Methodology stays DRY — encoded once in the constitution, enforced by `/speckit.analyze`-style compliance checks.
- Portable across Claude/Copilot/Gemini; no spec-kit core fork to maintain.
- Numeric acceptance gives a real CI pass/fail and end-to-end SLO traceability.

**Harder:**
- Must pin and test against spec-kit versions (`requires.speckit_version`); spec-kit CLI has shown breaking changes historically.
- Preset + extension must be co-versioned and coordinated (shared naming `speckit.perf.*`).
- Backend integration (CI trigger, results pull) lives in the extension's `run`/`analyze` commands and needs auth/access wiring.

**To revisit:**
- Whether `perf.run` should shell out to CI or call a results-backend API directly.
- Whether to also emit OpenSLO/k6-threshold artifacts for portability beyond Gatling.
- Whether the retest `do-while` loop belongs in the workflow or is left manual.

## Action Items

1. [ ] Scaffold the `spec-kit-performance` preset: override `constitution / specify / clarify / plan / tasks / implement` templates (perf charter = methodology sections + In/Out-of-Scope + **plain-language NFRs**; EARS SLOs are compiled later, in `plan`).
2. [ ] Author the perf `constitution-template.md` from the patterns in [doc 03](../03-prior-art-inspiration.md).
3. [ ] Build the `perf` extension: `speckit.perf.sut / .run / .analyze / .report` + hooks (`before_specify`→sut, `after_implement`→run).
4. [ ] Define the EARS→`nfr.yml` compilation and SLO-ID traceability rule.
5. [ ] Wire `perf.run` to perf-ci and `perf.analyze` to Cosmos/Galaxio Quality Gate.
6. [ ] Package as a `bundle.yml`; ship the `spec-kit-performance` workflow with approval gates + retest loop.
7. [ ] Pilot on one service (smoke → benchmark → maxperf) and validate SLO→result traceability end-to-end.
