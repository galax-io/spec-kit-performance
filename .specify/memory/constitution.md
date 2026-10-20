<!--
Sync Impact Report
- Version change: (template) -> 1.0.0
- Bump rationale: MAJOR, first ratified constitution of this repository (replaces the
  uncustomized Spec Kit placeholder).
- Sections: Precedence; Core Principles (I. This file governs the repository, not the
  shipped methodology; II. Everything through the Specify CLI; III. Generic methodology,
  pluggable backend; IV. Numeric, traceable acceptance; V. The shared kit is the
  template's; VI. Published identifiers and formats are contracts; VII. Secrets and data
  stay out); Distribution and Release; Development Workflow and Quality Gates; Governance.
- Templates checked: .specify/templates/plan-template.md (Constitution Check reads the
  principles below; no edit needed), spec-template.md, tasks-template.md,
  checklist-template.md (no edit needed; they are kit files owned by
  spec-kit-galaxio-bootstrap and must not be edited here).
- Follow-up: CLAUDE.md, README.md and docs/README.md still say the constitution is the
  unratified placeholder; that wording now refers to the shipped perf methodology
  (Principle I) and should be corrected in a separate docs change.
-->

# spec-kit-performance Constitution

## Precedence

1. The maintainer's direct instruction.
2. The ecosystem constitution (`galax-io/galaxio-sdlc-backlog`, `.specify/memory/constitution.md`).
3. This constitution.
4. `CLAUDE.md` of this repository (the working guide: pipeline, commands, release steps).

This constitution MAY tighten the ecosystem principles and MUST NOT contradict them. Where
`CLAUDE.md` conflicts with this file, this file wins.

## Core Principles

### I. This file governs the repository, not the shipped methodology

- This file MUST hold only the invariants of the `spec-kit-performance` repository.
- The load-testing methodology the product ships (test taxonomy, workload model, NFR/SLA
  contract, quality gate, SUT, role split; `docs/03-prior-art-inspiration.md`) MUST live in
  the preset's constitution template (`presets/perf/templates/constitution-template.md`, as
  planned in `docs/07-impl-plan-phase1.md`), never in this file.
- A change that edits one of the two MUST NOT be justified by the other.

Rationale: the product is itself "a constitution for performance testing"
(`docs/04-perf-speckit-design.md` §2a, two levels of constitution). Mixing the repository's
rules with the methodology users install would ship this repository's process to every
adopter.

### II. Everything through the Specify CLI

- Every capability the product offers MUST be expressed as a Spec Kit preset override, an
  extension command or hook, a workflow, or catalog metadata, and MUST be discoverable,
  installable and runnable through `specify` (`specify preset|extension search|add`,
  `specify init --preset`, `specify workflow run`, `/speckit.*`).
- The product MUST NOT ship bespoke installers, out-of-band binaries, or manual file copying
  as a supported install path. The only exception is MCP connectors and the agent invoked
  inside Spec Kit commands (`CLAUDE.md`, "HARD RULE").
- The product MUST ride Spec Kit's documented seams and MUST NOT fork Spec Kit core
  (`docs/adr/0001-perf-testing-sdd-approach.md`, option C).

Rationale: the decided packaging is a bundle (preset + extension) automated by a workflow;
a side channel would bypass template resolution and catalog discovery.

### III. Generic methodology, pluggable backend

- Shipped content (preset, extension, templates, workflow) MUST NOT name or depend on a
  specific organisation, internal platform or proprietary system. Public tools and notations
  (Gatling, k6, EARS, OpenSLO) MAY be named as examples only.
- The execution backend (load generator, CI, results and quality-gate backend) MUST stay
  pluggable: no command may require one specific backend to work.
- Shipped content MUST be grep-clean of proprietary names before release
  (`docs/07-impl-plan-phase1.md`, WS-B acceptance).

Rationale: `docs/03-prior-art-inspiration.md` and `docs/04-perf-speckit-design.md` §7 make
the methodology retrospective inspiration only. The `galaxio.io/plans.docker-images`
relation in `catalog-info.yaml` is one planned backend, not a hard dependency.

### IV. Numeric, traceable acceptance

- Every NFR MUST be quantified (a number, a load level and a duration) before it gates
  anything, compiled to an EARS SLO and then to the machine-readable NFR/SLA file
  (`nfr.yml`).
- The requirement id MUST propagate unchanged order -> NFR -> SLO -> NFR/SLA file ->
  measured value -> report row.
- The gate verdict MUST be computed from measured values against those thresholds and
  surfaced as PASS / CONCERNS / FAIL / WAIVED. Customers state needs in plain language; they
  MUST NOT be required to supply numbers.
- Changing this chain requires a new or superseding ADR in `docs/adr/`.

Rationale: these are the cross-cutting decisions locked in ADR-0001 and the reason the
product exists (`docs/04-perf-speckit-design.md` §3, "real pass/fail").

### V. The shared kit is the template's

- `.claude/skills/`, `.agents/skills/` and the kit files under `.specify/` MUST match
  `.specify/speckit-kit.sha256` byte for byte (`scripts/check-speckit.sh`, CI job `speckit`).
- Kit changes MUST arrive from `spec-kit-galaxio-bootstrap` via `copier update`; a pull
  request MUST NOT edit them by hand.
- `specify extension`, `preset` or `integration` commands MUST NOT be run against this
  repository's working tree. Development installs of this product's own preset and extension
  target a separate project.
- Only `.specify/memory/` (this constitution) and `.specify/feature.json` are the
  repository's own.

Rationale: `catalog-info.yaml` declares `dependsOn: component:default/spec-kit-galaxio-bootstrap`
("process: created from the template, takes process updates via copier update").

### VI. Published identifiers and formats are contracts

- Once published to the Spec Kit catalog, the bundle, preset and extension ids, the
  `speckit.perf.*` command names, the order template and the NFR/SLA file format are public
  contracts. Renaming or removing one, or changing a format incompatibly, MUST be a MAJOR
  version of the affected component, with an ADR.
- The bundle MUST declare the Spec Kit versions it supports (`requires.speckit_version`).
- The preset and extension MUST be versioned together; a release MUST NOT pair versions that
  were not tested together.
- From their first commit, the preset and the extension MUST be non-empty (populated
  `provides`), never placeholder-only (`docs/07-impl-plan-phase1.md`, WS-A).

Rationale: adopters install through `specify` and their generated specs depend on these
names and formats; ADR-0001 lists Spec Kit version drift as the main cost of the bundle.

### VII. Secrets and data stay out

- No secret, token or credential MAY be committed (`.gitignore` excludes `.env*`, `*.pem`,
  `*.key`, `secrets.*`).
- `BACKLOG_READ_TOKEN` MUST be used only in `.github/workflows/linkage.yml`, a workflow of
  its own that checks out without persisted credentials and installs nothing; no build or
  third-party code may run in that job.
- Shipped templates MUST direct adopters to keep raw production data out of tests and to
  take secrets from a vault, never from the repository (`docs/03-prior-art-inspiration.md`,
  idea 8).

Rationale: the backlog is private, and a performance pipeline handles production traffic
profiles and credentials of the system under test.

## Distribution and Release

- Distribution is the Spec Kit catalog: this public repository, a GitHub Release whose
  archive is the component's `download_url`, and a PR to the catalog's
  `catalog.community.json` (`CLAUDE.md`; `docs/07-impl-plan-phase1.md`, WS-D). It is not
  Maven Central; the sbt release rules in `CLAUDE.md` apply only to a compiled helper library,
  if one is ever added.
- Version tags `vX.Y.Z` MUST be cut only on `release/*` branches, never on `main`, never on
  a red pipeline. A published version MUST NOT be reused and its tag MUST NOT be deleted.
- A release tag MUST pass `scripts/check-linkage.sh --for-tag` (the `.githooks/pre-push`
  gate): its milestone is ready.

## Development Workflow and Quality Gates

- Every PR carries a milestone of this repository and `Part of galax-io/galaxio-sdlc-backlog#N`;
  `scripts/check-linkage.sh --pr` (CI job `linkage`) fails it otherwise.
- Every PR passes `scripts/check-speckit.sh` (CI job `speckit`).
- Repository scripts are tested first by hermetic bash suites (`scripts/*_test.sh`,
  `.claude/hooks/*_test.sh`, `.githooks/*_test.sh`) that use stubs, no network and no
  credentials; a script change without a failing-then-passing case is not accepted.
- Shipped commands and templates, when added, MUST come with an acceptance check that
  installs them through `specify` into a scratch project (`docs/07-impl-plan-phase1.md`
  acceptance criteria).
- Design decisions that are costly to reverse are recorded as ADRs in `docs/adr/`; design
  documents are indexed in `docs/README.md` and the reading order of `README.md`.
- A plan's Constitution Check answers each principle above with yes or no; a "no" is listed
  under Complexity Tracking with its justification.

## Governance

- Amendments are made by pull request to this repository, with the maintainer's explicit
  approval and an updated Sync Impact Report at the top of this file.
- The version follows semver: MAJOR removes or redefines a principle, MINOR adds a principle
  or section or materially expands one, PATCH clarifies wording.
- A complexity exception to a principle MUST name an owner and a removal date, and is
  recorded in the plan's Complexity Tracking.
- Reviews of specs and plans that affect this repository check them against this file and
  the ecosystem constitution.

**Version**: 1.0.0 | **Ratified**: 2026-10-20 | **Last Amended**: 2026-10-20
