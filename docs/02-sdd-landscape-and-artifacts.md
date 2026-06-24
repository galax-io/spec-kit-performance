# The SDD Landscape & Spec Artifacts

> Comparison of spec-driven-development frameworks and of the spec-artifact "vocabulary" (ADR / PRD / ARD / RFC / context files), weighted toward what transfers to a **performance-testing** domain rather than app-feature development.

## 1. SDD framework comparison

| Framework | Type / maturity | Core artifacts | Phase flow | "Constitution"/standards layer | Transfers to perf-testing? |
|---|---|---|---|---|---|
| **GitHub Spec Kit** | OSS CLI + prompts, MIT, ~110k★, agent-agnostic (30+ agents) | constitution, spec, plan, tasks (+contracts/data-model) | constitution→specify→clarify→plan→tasks→analyze→implement | `constitution.md` (prose, conventional, not enforced) | **YES (partial)** — preset/extension/bundle/workflow seams map cleanly; this is the chassis |
| **AWS Kiro** | Proprietary agentic IDE, GA 2026 | requirements.md, design.md, tasks.md | Requirements→Design→Tasks | **steering files** (`product/tech/structure.md`, Always/Conditional/Manual activation) | **PARTIAL** — steal the **EARS** requirement notation + steering idea, not the IDE |
| **BMAD-METHOD** | OSS, MIT, ~50k★, multi-agent | PRD + Architecture → sharded epics → **story files** | Planning → SM→Dev→QA dev cycle | BMAD CORE (agents/workflows/policies) | **PARTIAL→YES** — its **TEA** test-architect already speaks NFR/perf vocab and quality-gate decisions |
| **Agent OS** | OSS, MIT, Builder Methods | mission/roadmap/tech-stack + specs + **standards/** | plan→discover-standards→shape-spec→execute-tasks | **standards-as-constitution** (`index.yml`-injected, token-efficient) | **PARTIAL** — best *standards layer* design; zero test machinery |
| **Tessl** | Spec-as-source startup (Snyk founder) | `.spec.md` (capabilities w/ `@test`), spec registry | spec → build → code (regenerable) | n/a (spec is source) | **PARTIAL** — borrow the **test-backed capability format**, not the non-deterministic codegen |
| **Cline/Roo Memory Bank** | Context-engineering convention (OSS) | projectbrief / productContext / systemPatterns / techContext / activeContext / progress / decisionLog | "update memory bank" + Boomerang subtask isolation | memory files = persistent context | **YES** — domain-agnostic plumbing; adopt the `decisionLog` wholesale |

### What each donates to a spec-kit-performance

- **Spec Kit** → the whole chassis: agent-agnostic gated pipeline + presets/extensions/bundles/workflows.
- **Kiro → EARS notation** (Easy Approach to Requirements Syntax, Mavin/Rolls-Royce 2009). Five clause templates turn requirements into checkable `SHALL` assertions and express perf SLOs almost natively:
  > `WHILE 500 concurrent users WHEN load sustained 10 min THE SYSTEM SHALL keep p95 latency < 800 ms`

  This directly closes spec-kit's *verification gap* (prose specs can't self-check). In perf the acceptance criteria are numeric, so EARS + threshold-as-code is the load-bearing combination.
- **BMAD TEA** (Test Architect, workflows `test-design`, `nfr-assess`, `trace`) → risk profiles (P0–P3 = probability×impact), NFR assessment, and **gate decisions PASS / CONCERNS / FAIL / WAIVED**. Caveat: TEA's *automation* layer assumes Playwright/Cypress (functional E2E); only its *design + gating* layers transfer — the codegen needs a Gatling/k6 reskin.
- **Agent OS** → standards-as-constitution injected token-efficiently into every task; `/discover-standards` extracts standards from an existing repo (evidence-based, not speculative).
- **Tessl** → `scenario → @test → assertion` spec shape.
- **Roo/Cline** → `decisionLog` capturing *why* a ramp/threshold/think-time was chosen — rationale that is almost always lost in perf work — plus Boomerang subtask isolation ("build smoke sim → build load sim → analyze" as isolated subtasks).

## 2. Spec artifact types — definitions & layering

| Artifact | Owner | Answers | Scope | Durability | Mutability |
|---|---|---|---|---|---|
| **PRD** (Product Requirements Doc) | Product | *what & why* (problem, goals, value) | one product/feature | durable, evolving | mutable (living) |
| **RFC / design doc** | Eng author | *how* (proposed approach) | one change | ephemeral (deliberation) | frozen after acceptance |
| **ADR** (Architecture Decision Record) | Eng/architect | *what was decided & why* | **one decision** | durable (permanent log) | **immutable** (supersede, don't edit) |
| **Spec / tech spec** | Eng | detailed contract | one component | durable | mutable with code |
| **Agent context** (`AGENTS.md`/`CLAUDE.md`) | whole team | how an agent operates here | repo (+nested) | durable, versioned | mutable; treated as code |

**The chain:** Strategy → **PRD** (problem) → **RFC/design doc** (proposal) → **ADRs** (locked decisions) → **spec** (contract) → **code**, with **AGENTS.md/CLAUDE.md/CONTEXT.md** cutting across as the agent operating manual. Mnemonic: *PRD = problem · RFC = proposal · ADR = decision · Spec = contract · AGENTS.md = operating manual.*

### Per-artifact notes

- **ADR** — Michael Nygard's 2011 format: **Title / Status / Context / Decision / Consequences**, 1–2 pages, value-neutral context, "We will…" decision, *all* consequences (good and bad). **MADR** is the modern markdown template adding explicit Decision Drivers → Considered Options → Pros/Cons. One ADR per architecturally-significant (costly-to-reverse) decision; immutable once accepted. Tooling: adr-tools, log4brains.
- **PRD** — *what/why* from the user/business view, no implementation prescription. Modern practice = a living one-pager (objective, success metrics, personas, user stories, functional + **non-functional** requirements, scope/out-of-scope, open questions). Upstream of the spec.
- **"ARD"** — **not a canonical artifact.** Overwhelmingly a letter-transposition of **ADR**. Plausible-but-weak expansions: *Architecture Requirements Document* (in abbreviation lists, not a TOGAF deliverable), *Architecture Review Document/Record* (loose usage, usually really an RFC/ADR). In formal TOGAF the real quantitative term is **Architecture Requirements Specification (ARS)**, not "ARD". **If someone says "ARD," confirm — they almost always mean ADR** (occasionally a PRD-style requirements doc).
- **RFC (internal-eng sense)** — a pre-work design proposal circulated for feedback (Google "design docs", Uber's tiered planning, Squarespace's Architecture Review). One RFC often spawns several ADRs — the RFC is the deliberation, the ADRs the durable residue. Notably, Uber's RFC template includes a dedicated **load/performance-testing section** — precedent for treating perf as a first-class spec concern.
- **Agent-context files** — **`AGENTS.md`** (agents.md, ~60k+ repos, Linux-Foundation-stewarded, backed by OpenAI Codex/Cursor/Factory/Jules) is the converging cross-tool standard: free-form markdown for build/test commands, style, testing, PR rules. **`CLAUDE.md`** is Claude Code's native file (managed→user→project→local hierarchy, `@path` imports, ~<200 lines, *context not enforced config*). Guidance: write `AGENTS.md`, have `CLAUDE.md` import/symlink it. `CONTEXT.md` / `.context/` (Codebase Context Spec) are complementary, lower adoption — used by the `grill-with-docs` skill as an authoritative glossary.

**How they layer in a spec-kit-performance:**

```
constitution.md (the МНТ / standards)   ← durable, governs everything   [ADR-ish + standards]
   │
spec.md  (perf test charter: what to test / not test, SLOs in EARS)     [PRD + spec hybrid]
   │
plan.md  (workload model, profile, NFR budget, environment, data)       [RFC/design doc]
   │   └─ ADRs for costly-to-reverse choices (open-vs-closed model, tool choice)
tasks.md (ordered build tasks)
   │
scripts + run + report                                                   [the executable artifact]

CLAUDE.md / AGENTS.md  — agent operating manual, cuts across all layers
```

## 3. SDD-for-testing: prior art and the white space

**Bottom line: a spec-kit-style `constitution → specify → plan → tasks` pipeline purpose-built for performance/load testing does not exist as a product or OSS toolkit. The constituent pieces all exist separately.**

| Layer | Functional testing | Performance / load testing |
|---|---|---|
| Spec-kit-style SDD pipeline | ✅ spec-kit; **SpecTest** (Playwright-only) | ❌ **nothing** |
| AI spec-driven *test design* | ✅ BMAD **TEA** | ⚠️ TEA does NFR *planning* only |
| Declarative acceptance-as-code | ✅ assertions | ✅ **k6 thresholds** (CI fail-on-breach), **OpenSLO** |
| Declarative workload spec | n/a | ⚠️ Taurus/Artillery YAML, k6 Operator CRDs (no plan layer) |
| Academic requirements→test pipeline | mature (MBT) | ✅ **PRO-TEST** (research, pre-LLM) |
| AI generate test from NL | ✅ many | ✅ **k6 MCP / `k6 x agent`**, Gatling AI Assistant |

Most relevant prior art:

- **SpecTest** (github.com/speckits/spectest) — SDD for test automation (propose→review→generate→heal→archive), but **Playwright/functional only**.
- **BMAD TEA** — closest agentic *test-design* pattern; `nfr-assess` covers performance but stops at strategy/evidence, no load scripts.
- **PRO-TEST** (Abdeen/Chen/Unterkalmsteiner, *Requirements Engineering* 2023, arXiv:2403.00099) — the academic analogue of requirements→design→tasks for performance: extract perf requirements from NL → model against a taxonomy → verify (flags non-quantified/underspecified requirements) → generate test environments. Validated on 77 SRS / 149 perf requirements. Pre-LLM, not productized — **but proves the pipeline is sound.**
- **k6 thresholds + OpenSLO** — SLOs-as-code with CI gates; the *budget* half of a perf spec, in version control today.
- **k6 MCP / `k6 x agent`** (k6 2.0, 2026) — MCP server + portable skills (planning, smoke/load/browser). The "planning" skill is the closest shipping thing to a plan-first AI perf workflow, but lightweight — not a constitution/specify/plan/tasks pipeline.
- **Perf-test-plan templates** (e.g. perfmatrix) — the artifact exists as a mature *manual* QA deliverable, but nobody treats it as a versioned, AI-consumable spec that drives generation.

### The unoccupied niche

No one has assembled a **spec-first methodology for perf/load testing** that (1) starts from a **constitution** of perf principles + SLO/NFR budgets, (2) produces a reviewable, versioned **performance test charter** (workload + thresholds + environment + data), (3) decomposes it into **tasks**, and (4) drives AI generation of the actual Gatling/k6 scripts with **traceability** back to requirements — then (5) runs them and gates on numeric results.

The verification gap that plagues prose SDD is *more tractable* here than in app-code, because perf acceptance criteria are numeric SLOs and `k6`/Gatling assertions give a real pass/fail exit code. **EARS + threshold-as-code** is the lever that makes a "spec-kit-performance" rigorous where a feature-dev speckit stays advisory.
