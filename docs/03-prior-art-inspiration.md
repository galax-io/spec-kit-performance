# Prior Art & Inspiration — Load-Testing Methodology Patterns (retrospective)

> A catalogue of ideas drawn from mature load-testing practice, included **only as historical, retrospective inspiration** for the spec-kit-performance design. None of this is a system spec-kit-performance integrates with, depends on, or reuses — it is a list of generic patterns worth borrowing. No specific tool, platform, or organisation is named.

## The transferable ideas

1. **Test-type taxonomy** — *max-performance* (stepped ramp to find the limit + a regression reference baseline), *stability/soak* (hold ~80 % of max for hours; catch leaks/degradation), *benchmark* (lightweight per-commit guard that blocks a regressing merge), *spike* (burst then verify self-recovery), *squeeze* (repeat max-perf per replica count → a capacity/scaling law). A sensible base set is max-perf + stability + benchmark.
2. **Objective ladder (L0–L3)** — start low, can't skip: L0 product-profile / release regression · L1 find max throughput + confirm stability · L2 reproduce incidents / stress · L3 capacity / volume / chaos.
3. **Workload modeling** — choose an *open* vs *closed* model to match production behaviour (a closed model on an open system gives artificial results). Load shape parameterised by intensity, ramp duration, stage duration, number of stages. Rate-based (requests per unit time).
4. **Profile derivation from logs** — collect a representative window of production traffic, build an "average-day" model, pick the peak hour, keep the requests that make ~90–95 % of traffic, re-add the business-critical / heavy ones (Pareto). Automatable from access logs + an API spec.
5. **NFR/SLA contract** — named requirement sets with assertions on latency percentiles (p95/p99), max latency, throughput, error rate; thresholds tied to service criticality; a headroom margin (e.g. 25–50 %) over production peak.
6. **Quality gate** — a pass/fail verdict from measured-vs-threshold, optionally a weighted score, floored by service criticality, compared to a baseline (a pinned run or a rolling median).
7. **System-under-test (SUT) definition** — describe what is being tested: prod-vs-test hardware comparison, an architecture diagram with **load-injection points**, declared environment limitations, and monitoring/dashboard links per environment.
8. **Test-data governance** — never use raw production data; classify sensitive data (payment, card, personal); pull secrets from a vault, not the repo.
9. **Scaffolding & CI tiers** — a project scaffold (e.g. a giter8 template) with a *cases → scenarios → simulations* layout; CI tiers bound to triggers (smoke on every run, a per-feature benchmark, release + nightly regression).
10. **Living methodology charter** — a per-project document (system description, participants/roles, goal, SUT, limitations, workload model, load profile, planned tests, data prep, stubs/emulators) kept in version control and approved before any run.
11. **Methodology-as-config pattern** — encode the methodology as fill-in **config files + a prose charter**, split by *authority tier* (documentation-only vs runtime-consumed), auto-published to a docs site, with the runtime files feeding the numeric gate. The author edits the config + prose; the appendix tables and the published site fall out automatically.
12. **Role split** — the perf/methodology side owns the tooling, the methodology and the approval gate; it does not state each service's needs. The service/customer side states the need; it does not invent methodology.

## How spec-kit-performance borrows them

spec-kit-performance adopts **no specific tool or platform**. It treats the list above as *the content a perf constitution + test charter should cover*, and lets the spec-driven pipeline ([doc 04](04-perf-speckit-design.md)) drive that content's authoring generically:

- public, well-known load generators (e.g. **Gatling**, **k6**) for the scripts;
- **EARS** notation + an **NFR/SLA file** for numeric, machine-checkable acceptance;
- a **quality gate** for the pass/fail verdict;
- the **role split** (idea 12) for the actor model (doc 04 §2a).

Everything concrete — exact schemas, weights, file layouts, internal platforms — is intentionally left out: those were the *inspiration*, not the design.
