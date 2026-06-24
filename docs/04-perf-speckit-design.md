# spec-kit-performance — The Proposed Technology

> A spec-driven methodology for **performance/load testing**, built on the spec-kit chassis. It encodes generic load-testing methodology patterns (see [doc 03](03-prior-art-inspiration.md), retrospective inspiration) as a ratified constitution, and drives AI generation of load-test scripts with traceability from a stated need to a numeric pass/fail. This is the "how to do it right" — deliberately kept generic; no specific platform or tool is assumed.

## 1. The target flow (4 phases, 2 front-door actors)

The load engineer owns the perf repo and does the heavy lifting; the customer does exactly one thing — files an order through a skill.

```
[ org methodology ratified ]  ── precondition, perf-methodology owner (central, rare) ──┐
                                                                                          │
  PHASE A — BOOTSTRAP THE PERF REPO                          actor: LOAD ENGINEER ────────▼
     empty repo → instantiate the methodology for THIS service (what / how we test;
     how a release & a nightly-regress run are defined)  ───►  ASSEMBLE THE SUT  ◄─ focus
                                                       │
  PHASE B — ORDER INTAKE                                ▼            actor: CUSTOMER
     a low-friction skill: identify the repo/branch → search the wiki → what to test / what NOT
        → draft the order (plain language)  ───────────────────────►  flies to the load engineers
                                                       │
  PHASE C — SPEC & PLAN                                 ▼            actor: LOAD ENGINEERS
     check the order against the methodology + SLA → spec.md (charter, NFRs in plain language)
        → clarify (quantify) → plan.md (EARS SLOs + load profile + script blueprint)
                                                       │
  PHASE D — BUILD & RUN                                 ▼   actor: LOAD ENGINEERS + AI; quality gate
        tasks → implement (load-test scripts) → run → analyze/gate → report
```

The customer answers a few gentle questions; the load engineers formalise the result into a spec + plan checked against the ratified methodology; everything downstream is generated from, and traceable to, those documents.

## 2. Phase ↔ command ↔ actor ↔ artifact mapping

| Phase | Command / skill | Actor | Reshaped from | Artifact |
|---|---|---|---|---|
| **A · bootstrap** | `specify init --preset spec-kit-performance` + `/speckit.constitution` + `/speckit.perf.sut` *(new)* | **Load engineer** | core + extension | per-repo `constitution.md` · SUT definition |
| **B · order** | `/speckit.perf.order` *(new skill, wiki-aware)* | **Customer** | extension | `order.md` — a plain-language order |
| **C · specify** | `/speckit.specify` | Load engineers | preset | `spec.md` = test charter (scope in/out, **NFRs in plain language**) |
| **C · clarify** | `/speckit.clarify` | Load engineers | preset | quantified NFRs (resolves `[NEEDS CLARIFICATION]`) |
| **C · plan** | `/speckit.plan` | Load engineers | preset | `plan.md` (EARS SLOs + an NFR/SLA file + a load profile + script blueprint) |
| **D · tasks** | `/speckit.tasks` | Load engineers | preset | `tasks.md` — ordered build backlog |
| **D · implement** | `/speckit.implement` | Load engineers (+AI) | preset | **load-test scripts** (e.g. Gatling/k6) + CI wiring |
| **D · run** | `/speckit.perf.run` *(new)* | Load engineers | extension | a test run in CI; a run id |
| **D · analyze** | `/speckit.perf.analyze` *(new)* | quality gate | extension | verdict vs the NFR/SLA file |
| **D · report** | `/speckit.perf.report` *(new)* | Load engineers | extension | `report.md` |

**Reshaped (preset)** = the meaning of the core commands changes for the perf domain. **New (extension)** = phases that don't exist in core spec-kit (order, sut, run, analyze, report). Packaged as a **bundle** (`spec-kit-performance`). Rationale → [ADR-0001](adr/0001-perf-testing-sdd-approach.md).

## 2a. Separation of duties — who performs each phase

Three actors, three cadences. The customer's only active step is filing the order; everything else is the load engineer's. (Borrowed from the role-split idea — doc 03 §12.)

| Actor | Owns | Cadence |
|---|---|---|
| **Perf-methodology owner** | the *org* methodology (the shared handbook shipped in the preset: test taxonomy, workload rules, gate thresholds, data governance) | once; amended rarely — a **precondition** |
| **Load engineer** | Phase A (bootstrap repo + **assemble SUT**) · Phase C (spec & plan) · Phase D (build, run, gate, report). *The role that makes the repository.* | per repo, then per campaign |
| **Customer** | Phase B only — files a plain-language order | per request |

**Two levels of constitution.** The *org methodology* is ratified centrally by the perf-methodology owner and ships as the preset's `constitution-template.md` — one source of truth across services. The *per-project* `constitution.md` is a thin **instantiation** the load engineer fills in Phase A: it imports the org methodology and pins this service's facts (criticality → gate threshold, environments, how release & nightly-regress runs are bound to CI triggers). The customer never touches methodology or scripts; the per-test cycle only **asserts** the constitution exists (gate `g0`).

## 3. Phase-by-phase

### Phase A — Bootstrap the perf repo *(load engineer)*

Trigger: an **empty, uninitialised project**. `specify init --preset spec-kit-performance` scaffolds `.specify/`, then:

- **A.1 Instantiate the methodology** (`/speckit.constitution`). Produces the per-repo `constitution.md`: what the service is, how it is tested, and how each test kind is defined — notably the **release** run and the **nightly / regress** run, plus the per-feature benchmark. Imports the org methodology; pins this service's criticality → gate threshold.
- **A.2 Assemble the SUT** (`/speckit.perf.sut`) — **the focus.** Records the system-under-test: service, business operations, tech stack, prod-vs-test comparison, an **architecture diagram with load-injection points**, environment limitations, monitoring links. Uses the grill-with-docs pattern so the SUT is concrete, not hand-waved. A weak SUT poisons everything downstream.

Output: a repo whose constitution + SUT are **in master** — the precondition the per-campaign cycle asserts (`g0`).

### Phase B — Order intake *(customer, via a skill)*

A customer who wants load testing does **not** write a spec. They invoke the **order skill** (`/speckit.perf.order`) — the front door, deliberately **low-friction**. The customer is not a perf engineer, so the questions are plain, comfortable, one at a time, each skippable:

- What system / service is this?
- What do you want to be sure holds up — and what's explicitly **out of scope**?
- Which **repository** and **branch**?
- Is there an **architecture diagram**, requirements, or an SLA written down somewhere (a wiki link)?
- Roughly how much load do you expect — *if* you happen to know? (numbers optional)

The skill identifies the repo, searches the wiki/issue tracker (via an Atlassian/Confluence MCP connector) for context, and drafts `order.md` in **plain natural language** — no numbers required. "It should survive Black Friday" is an acceptable answer. The order is attached to the work item and **flies to the load engineers**. The customer's job ends here.

### Phase C — Spec & Plan *(load engineers)*

The load engineers turn the order into the concrete harness, validating each step against the methodology + SLA.

- **C.1 Specify** (`/speckit.specify`). Consumes `order.md`. The preset replaces the spec template with a **perf charter** = methodology charter sections (doc 03 §10) + an explicit **In-Scope / Out-of-Scope** block. At this stage SLA/NFR stay in **plain natural language** — the engineer transcribes intent into clear sentences, *not* numbers:

  ```
  NFR-001  Checkout must stay responsive at the Black Friday peak (~2× last year's
           traffic) — no error spikes, no creeping latency. Last year it fell over near 3×.
  NFR-002  The overnight regression run must not get slower release-over-release.
  NFR-003  After a sudden burst the service should recover on its own.
  ```

  Vague spots are marked `[NEEDS CLARIFICATION: "responsive" not quantified]`. Reviewed at gate `g1`.

- **C.2 Clarify** (`/speckit.clarify`) — the interrogation engine, run by the load engineers. **This is where the prose NFRs get quantified.** A ≤5-question loop fusing brainstorming (one question at a time, multiple-choice biased, scope-guard first), grill-me (walk each branch, recommend an answer), grill-with-docs (challenge against the constitution + SUT + the wiki sources), and a PRO-TEST-style hard gate: every NFR must end with a **number, a load level, and a duration** (the engineer supplies these from the methodology + SUT, not the customer).

- **C.3 Plan** (`/speckit.plan`). Turns the charter into the design. First it **compiles each quantified NFR into an EARS SLO**, then into a machine-readable NFR/SLA file:

  ```
  NFR-001  →  SLO-001  WHILE 500 rps sustained for 30 min, THE checkout-service SHALL keep p95 ≤ 400 ms.
  ```

  Plus: the **workload model** (open vs closed, load shape per test type), a **load profile**, the **environment & data plan** (no raw prod data; secrets from a vault), and the **tool & script blueprint** (e.g. Gatling vs k6, justified; an ADR if costly-to-reverse). Approved at gate `g2`. Output: *how to test, and the blueprint for the scripts.*

### Phase D — Build & Run *(load engineers + AI; quality gate)*

- **D.1 Tasks** (`/speckit.tasks`) — an ordered, dependency-aware backlog (scaffold → scenarios → simulations → CI jobs for the release / nightly-regress / feature triggers).
- **D.2 Implement** (`/speckit.implement`) — **the scripts.** Generates the actual load-test scripts (e.g. Gatling/k6) and CI wiring, with assertions traceable back to `SLO-xxx` ids.
- **D.3 Run** (`/speckit.perf.run`) — runs a smoke test first, then the requested test type, in CI; captures a run id. Refuses to run if the constitution/SUT/NFR file aren't in master.
- **D.4 Analyze/Gate** (`/speckit.perf.analyze`) — computes the quality-gate verdict against the NFR/SLA file, floored by service criticality, compared to a baseline. Emits **PASS / CONCERNS / FAIL / WAIVED**, each SLO traced to its measured value. Numeric → a *real* gate with a CI exit code.
- **D.5 Report** (`/speckit.perf.report`) — `report.md`: score, percentile table, leak/recovery per test type, comparison to baseline, dashboard links.

## 4. Acceptance-as-code — closing the verification gap

The chain **starts in natural language** and only hardens to numbers downstream:

```
NFR (spec.md, prose)   ──quantify (C.2)──►  EARS SLO (plan)   ──compile (C.3)──►  NFR/SLA file  ──run──►  measured  ──gate──►  PASS/FAIL
 NFR-001 "survive 2× peak"                   SLO-001 p95≤400ms@500rps               assertion             p95=380ms          PASS
```

The id propagates **order → NFR (natural) → SLO (EARS) → NFR/SLA file (machine) → measured → report row**. The customer speaks prose; the load engineers turn it into numbers; the gate is numeric. This is the **traceability** prose-based feature-SDD lacks, feasible *only because perf criteria ultimately reduce to numbers*. Optionally express the budget half in **OpenSLO** / **k6 thresholds** for portability.

## 5. Automating the chain (workflow engine)

Phase A (bootstrap) is a one-time precondition; Phase B (order) is the customer's skill, run async. The per-campaign workflow is run by the load engineers and starts once an order exists:

```yaml
inputs:
  order: { type: string, required: true, prompt: "Path to the order (order.md)" }
steps:
  - { id: g0, type: gate, message: "Repo bootstrapped? constitution + SUT in master?", on_reject: abort }
  - { id: specify, command: speckit.specify, input: { args: "{{ inputs.order }}" } }
  - { id: clarify, command: speckit.clarify }
  - { id: g1, type: gate, message: "Approve test charter?", on_reject: abort }
  - { id: plan,    command: speckit.plan }
  - { id: g2, type: gate, message: "Approve workload + NFR + script blueprint?", on_reject: abort }
  - { id: tasks,   command: speckit.tasks }
  - { id: impl,    command: speckit.implement }
  - { id: run,     command: speckit.perf.run }
  - { id: retest:
      type: do-while
      condition: "{{ steps.analyze.output.verdict != 'PASS' }}"
      max_iterations: 3
      body:
        - { id: analyze, command: speckit.perf.analyze }
        - { id: fix, type: gate, message: "Gate not green — adjust & rerun?", options: [rerun, accept, abort] } }
  - { id: report,  command: speckit.perf.report }
```

Run manually phase-by-phase, or `specify workflow run spec-kit-performance` for the gated pipeline.

## 6. The layered stack

```
┌─────────────────────────────────────────────────────────────────────┐
│ CLAUDE.md / AGENTS.md      — agent operating manual (cross-cutting)   │
├─────────────────────────────────────────────────────────────────────┤
│ constitution.md            — ratified methodology (governs all)       │
├─────────────────────────────────────────────────────────────────────┤
│ bundle: spec-kit-performance                                                  │
│   ├─ PRESET    reshapes constitution/specify/clarify/plan/tasks/impl  │
│   └─ EXTENSION adds  perf.order / perf.sut / perf.run / .analyze / .report
├─────────────────────────────────────────────────────────────────────┤
│ spec-kit core: CLI · scripts · template-resolution · workflow engine  │
├─────────────────────────────────────────────────────────────────────┤
│ connectors:  Atlassian MCP (wiki / issue tracker)  ← order skill      │
├─────────────────────────────────────────────────────────────────────┤
│ execution backend (pluggable): a load generator (Gatling/k6) · CI ·   │
│                    a results / quality-gate backend                   │
└─────────────────────────────────────────────────────────────────────┘
```

## 7. Why this is the right shape

1. **Generic & non-prescriptive** — borrows methodology *patterns* (doc 03), not a specific platform; the execution backend is pluggable.
2. **Numeric verification** — EARS + an NFR/SLA file + a quality gate give a real pass/fail, defeating the prose-spec weakness that makes feature-dev SDD merely advisory.
3. **Right actor for each phase** — bootstrap + SUT + spec/plan/build are the load engineer's; the customer only files a plain-language order; the org methodology is a separate precondition. One methodology, many campaigns (§2a).
4. **Low-friction intake** — the customer doesn't learn the methodology or write a spec; the order skill drafts the order in plain language, numbers are the load engineers' job.
5. **Agent-agnostic & non-invasive** — preset + extension + bundle ride spec-kit's documented seams; no fork; portable across Claude/Copilot/Gemini.
6. **Human-gated** — approval gates (charter, NFR) preserve a review step.
7. **Fills a real white space** — no existing tool does spec-first perf testing end-to-end (doc 02 §3).
