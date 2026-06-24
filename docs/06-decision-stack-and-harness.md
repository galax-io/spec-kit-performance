# Decision — Stack Choice + Harness Model

> Direct answer to the core research question: **build our own, embed into spec-kit, or use something else?** Plus the two mechanics that decide it — spec-kit's **bidirectional review** and its **integration** model — and how to think about the whole thing as a **harness**.

## 1. The answer

**Embed into spec-kit as a *bundle* (preset + extension), driven by spec-kit's workflow engine as the orchestration harness. Do not build a framework from scratch, and do not fork.**

One line: *spec-kit already is the harness you'd otherwise spend months rebuilding; your perf-specific value is ~10 % of the surface and plugs into documented seams.*

## 2. Decision drivers (technical)

1. **The chassis is large and non-differentiating.** spec-kit gives you, for free and battle-tested: author-once-materialize-per-agent across 30+ assistants (§5), a 4-layer template-resolution stack with compose strategies, a deterministic *script ↔ agent* JSON contract, a constitution governance layer, a **bidirectional review loop** (§4), and a **workflow engine** with gates / loops / fan-out / state-persist-and-resume (§6/§7). Rebuilding any one is weeks; all of them is the whole product.
2. **The seams fit the perf need exactly** — no fork required:
   - re-skin the meaning of constitution/specify/plan/tasks/implement → a **preset** (rides the template-resolution layer);
   - add net-new phases (order, sut, run, analyze-gate, report) + lifecycle hooks → an **extension** (`extensions.yml`: `before_specify→sut`, `after_implement→run`);
   - package both by role → a **bundle**;
   - orchestrate the gated pipeline → a **workflow**.
3. **Verification is inherited.** The analyze/converge loop already carries stable traceability IDs (FR-###/SC-###, `source-ref`, `gap-type`). You map `SLO-###` onto that plumbing and get need→result traceability without building it.

## 3. Options weighed

| Option | Technical verdict |
|---|---|
| **Embed as bundle (preset+extension)** ✅ | Each concern lands in its intended seam; rides documented APIs; stays agent-agnostic; upgrades with upstream. Chosen. |
| **Build own framework (greenfield)** | Total control, but you rebuild + own the chassis forever (integrations, template resolution, hooks, workflow, resume) and lose 30+ agent support. Justified *only* if perf needs something spec-kit's model fundamentally can't express — it doesn't; the model is domain-generic. |
| **Fork spec-kit** | Gets the chassis but every upstream release becomes a merge conflict. The preset/extension seams exist precisely so you don't fork. Avoid. |
| **Other SDD framework** | *Kiro* — closed IDE, no. *BMAD/TEA* — closest test vocabulary, but its automation layer assumes functional E2E (Playwright); heavier multi-agent runtime; you'd reskin for load anyway. *Agent-OS* — clean standards layer, zero test machinery. None is agent-agnostic + extensible like spec-kit. **Borrow their ideas (EARS from Kiro, PASS/CONCERNS/FAIL/WAIVED from BMAD), not their runtime.** |

**When you would build own instead:** if the project becomes a long-running, multi-tenant **control plane** — a service that schedules and manages many concurrent campaigns across teams, with a queue, a UI, and shared result storage. spec-kit is a *per-repo CLI harness*, not a multi-tenant service. Start with the bundle; graduate to a separate control plane only if fleet scale demands it (§7).

## 4. How spec-kit's bidirectional review works (technical)

Review runs in **two directions**, both anchored on the constitution as the non-negotiable authority.

**Forward — `/speckit.analyze` (spec → artifacts → coverage), read-only.** After `tasks.md` exists, it:
- builds a **requirements inventory** (one stable key per `FR-###` / `SC-###` / user-story acceptance scenario) and a **task-coverage map** (each task → the requirement(s) it satisfies, by ID or keyword);
- runs detection passes: duplication, ambiguity (vague adjectives, placeholders), underspecification, **constitution alignment**, **coverage gaps in both directions** (requirements with zero tasks *and* tasks with no mapped requirement), and inconsistency (terminology drift, contradictory choices, ordering violations);
- assigns severity (CRITICAL = constitution MUST violation or zero-coverage of baseline; HIGH/MEDIUM/LOW) and emits a report — **never edits**, only offers remediation.

**Backward — `/speckit.converge` (code → spec reconciliation), append-only.** After `implement` runs, it:
- reads spec/plan/tasks as the *sole source of intent*, assesses the **actual current code**, and emits a `Finding` only where a gap exists, classified by **gap-type**: `missing` / `partial` / `contradicts` / `unrequested`;
- **appends** each actionable finding as a new traceable task (`- [ ] T042 <work> per <source-ref> (<gap-type>)`) under a fresh `## Phase N: Convergence` — never rewrites existing tasks, never touches code;
- if the code already satisfies everything, leaves `tasks.md` byte-for-byte unchanged and reports *converged*.

**The loop:** `implement → converge → implement → … → converged`, with `analyze` as the forward consistency gate before each implement and **human review gates** in the workflow between phases. Stable IDs (`FR-/SC-/source-ref/gap-type`) make it a closed, traceable loop rather than prose review. *For perf, the same loop gates on numbers:* `SLO-###` becomes a `source-ref`, and "p95 over budget" is a `partial`/`contradicts` finding.

## 5. How integration works (technical)

A command is authored **once** as a markdown template with placeholders; spec-kit materialises it into every agent's native format.

**The template** (`templates/commands/<cmd>.md`) carries: YAML frontmatter with `description` + `scripts.sh`/`scripts.ps`; body placeholders `$ARGUMENTS`/`{ARGS}`, `{SCRIPT}`, `__AGENT__`, `__CONTEXT_FILE__`, and `__SPECKIT_COMMAND_<NAME>__`.

**The transform** (`process_template()`, 8 steps): extract the script command from frontmatter → replace `{SCRIPT}` → strip the `scripts:` block → replace args with the agent's placeholder → replace `__AGENT__` / `__CONTEXT_FILE__` → rewrite project-relative paths (`scripts/` → `.specify/scripts/`) → resolve `__SPECKIT_COMMAND_X__` to `/speckit.x` or `/speckit-x` using the integration's **`invoke_separator`** (`.` vs `-`).

**The adapter** = an `IntegrationBase` subclass — `MarkdownIntegration` (Claude/Cursor/Copilot), `TomlIntegration` (Gemini/Tabnine), `YamlIntegration` (Goose), `SkillsIntegration` (skills layout). Each sets `key`, `config`, `registrar_config`, `context_file`, `invoke_separator`; `setup()` writes each command into the agent's dir/format and **records every file in a hash-tracked manifest** so install/upgrade/uninstall are idempotent and stale files are cleaned safely.

**Dispatch** (used by the workflow engine): `dispatch_command()` → `build_command_invocation()` (builds `"/speckit.specify <args>"`) → `build_exec_args()` (e.g. `claude -p "<prompt>" --output-format json`) → runs the agent CLI **non-interactively**, returning `{exit_code, stdout, stderr}`. The agent context file (e.g. `CLAUDE.md`) is managed as a section between `<!-- SPECKIT START -->` / `<!-- SPECKIT END -->` markers.

Net: you write a perf command once; it works in Claude, Copilot, Gemini, … unchanged. That portability is the single biggest reason not to build your own.

## 6. Key technical traits (the признаки)

1. **Prompt-as-program** — commands are markdown templates with a deterministic placeholder pipeline; the agent is the interpreter; small shell scripts do the deterministic plumbing and hand back **JSON** (a stable script↔agent contract).
2. **Author-once, materialise-per-agent** — integration adapters + a hash-tracked manifest → idempotent, agent-agnostic install.
3. **Four-layer template resolution** — overrides > presets > extensions > core, with `replace`/`prepend`/`append`/`wrap` compose strategies → re-skinnable without forking.
4. **Extensions + lifecycle hooks** — `extensions.yml` declares `before_/after_<phase>` hooks; each command has pre/post hook blocks that read it at runtime.
5. **Constitution as governing layer** — non-negotiable; enforced by analyze/converge (violations are auto-CRITICAL).
6. **Bidirectional review loop** — forward (analyze) + backward (converge) on stable traceability IDs.
7. **Workflow engine = the harness** — typed steps (command/gate/if/switch/while/do-while/fan_out/fan_in/shell/prompt/init), an expression engine, **state persistence + resume**, human gates, non-interactive agent dispatch.

## 7. Harness thinking — managing the whole project

Treat spec-kit's **workflow engine as the orchestration harness**: the deterministic control layer that drives a campaign and dispatches the agent per step. Two levels:

**Campaign harness (one test campaign)** = the spec-kit-performance workflow:
`g0 (repo bootstrapped?) → specify → clarify → g1 → plan → g2 → tasks → implement → run → [do-while: analyze-gate → fix] → report`.
State is persisted per step; gates pause and `resume`; the retest loop is a real control-flow primitive, not prose. This is doc 04 §5.

**Fleet harness (many campaigns / services)** = a thin layer *above* the campaign:
- `fan_out` the campaign workflow across services (each its own repo / feature dir), `fan_in` the gate verdicts;
- schedule nightly-regress runs (cron → `specify workflow run`);
- aggregate PASS/CONCERNS/FAIL across the fleet into one board.
You can prototype this with the workflow engine itself. Only if it must become a shared, multi-tenant, always-on service do you add a **separate control plane** (queue + scheduler + result store + UI) — and then the per-repo bundle becomes its *authoring front-end*, not a throwaway.

**The management substrate is the artifacts, not a separate tracker.** What you actually steer the project with:
- the **constitution** (governs every campaign),
- the **order → NFR → SLO → NFR-file → result** ID chain (traceability),
- the **analyze/converge loop** (consistency + gap closure),
- the **manifest** (what's installed where),
- the **workflow run-state** (where each campaign is, resumable).

Manage those and you manage the project. That is the harness mindset: a deterministic outer loop (workflow engine) driving a non-deterministic inner worker (the agent), with every decision gated, traceable, and resumable.

## 8. Bottom line

Build **on** spec-kit (bundle), not **instead of** it. Use the workflow engine as the campaign harness now; add a fleet control plane only when multi-tenant scale forces it. Borrow ideas from Kiro/BMAD, runtime from neither.

## 9. Mechanism map — each piece → its seam

It is **not** preset *or* extension — it is a **composition**. Nothing is "built from scratch" except the perf-domain *content*.

| spec-kit-performance piece | spec-kit mechanism |
|---|---|
| Reshape constitution / specify / clarify / plan / tasks / implement for the perf domain | **Preset** (template-resolution overrides + `replace/prepend/append/wrap`) |
| Constitution content (the methodology) | the preset's `constitution-template.md` |
| New phases: order, sut, run, analyze-gate, report | **Extension** commands `speckit.perf.*` |
| Auto-wiring (`before_specify→sut`, `after_implement→run`, assert-constitution before run) | **Hooks** in `extensions.yml` |
| Order intake (customer, wiki-aware) | an **extension command/skill** (`perf.order`) + Atlassian MCP |
| Package it all by role, versioned | **Bundle** (`bundle.yml`) |
| Drive the gated pipeline end-to-end | **Workflow** (`workflow.yml`) |
| Run in Claude / Copilot / Gemini unchanged | **Integration** — inherited free, you build nothing |
| Per-service tweaks | **template overrides** layer (top of the resolution stack) |

"Something of your own" = only if it grows into a multi-tenant **control plane** (fleet, §7) — never for the per-campaign mechanics.

### The loops
1. **Clarify loop** — ≤5 questions inside `/clarify`, repeat until every NFR is quantified.
2. **Retest loop** — workflow `do-while`: `analyze-gate → fix → rerun` until PASS (`max_iterations`).
3. **Converge loop** — spec-kit native backward review: `implement → converge (append gap tasks) → implement → …` until *converged* (§4).
4. **Review gates** — human approve/reject `g0/g1/g2`, pause + `resume` between phases.
