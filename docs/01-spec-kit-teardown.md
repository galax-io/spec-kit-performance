# Spec-Kit, Cover to Cover

> How GitHub's [spec-kit](https://github.com/github/spec-kit) actually works — the mental model, the file layers, the command pipeline, and the exact "who calls whom" call graph. Study notes for building a perf-testing variant.

## 1. The thesis (Spec-Driven Development)

Spec-kit inverts the normal AI-coding loop. Instead of prompting an agent ad-hoc and letting code be the source of truth, **the specification is the source of truth and code is a generated artifact**. The flow is a chain of *durable, reviewable markdown documents*, each produced by a dedicated slash command, each gated by a human before the next runs.

The product is not a runtime library — it is a **package of prompt templates + shell scripts + a CLI scaffolder**. The "intelligence" lives in the markdown command templates that an AI agent (Claude Code, Copilot, Gemini…) reads and executes. The shell scripts only do deterministic plumbing (make dirs, number features, emit JSON paths). Nothing in spec-kit "runs" your code; it orchestrates an agent to write documents and then code.

## 2. Repository anatomy

```
spec-kit/
├── src/specify_cli/          # the `specify` Python CLI (Typer app)
│   ├── commands/init.py      #   `specify init` — scaffolds a project
│   ├── integrations/         #   30+ agent adapters (claude, copilot, gemini, cursor…)
│   ├── presets/              #   preset install/resolve logic
│   ├── extensions/           #   extension install/register logic
│   ├── bundler/              #   bundle = preset+extensions packaged by role
│   └── workflows/            #   the workflow ENGINE (engine.py + steps/)
│
├── templates/                # the heart: authored ONCE, materialized per agent
│   ├── commands/*.md         #   the 10 slash-command prompt templates
│   ├── constitution-template.md
│   ├── spec-template.md
│   ├── plan-template.md
│   ├── tasks-template.md
│   └── checklist-template.md
│
├── scripts/bash/*.sh         # deterministic plumbing (+ powershell/ mirror)
│   ├── common.sh             #   shared functions: repo-root, feature-paths, template-resolve
│   ├── create-new-feature.sh
│   ├── setup-plan.sh
│   ├── setup-tasks.sh
│   └── check-prerequisites.sh
│
├── presets/                  # shippable presets (lean, scaffold, self-test)
├── extensions/               # shippable extensions (git, bug, agent-context)
├── workflows/                # shippable workflows (speckit = full SDD cycle)
└── .specify/memory/constitution.md   # spec-kit's OWN constitution
```

After `specify init`, a *consuming* project gets a `.specify/` directory holding copies of the templates, scripts, memory (constitution), workflows, plus an agent-specific command dir (`.claude/`, `.github/`, etc.).

## 3. `specify init` — the scaffolder

End-to-end, `specify init <name>` does:

1. Create project dir (or `--here`).
2. Pick the **AI agent integration** (interactive prompt or `--integration claude`).
3. Pick script flavor (POSIX `sh` vs PowerShell `ps`).
4. Verify the agent's CLI is installed (unless `--ignore-agent-tools`).
5. Call the integration's `.setup()` → scaffolds agent dirs (e.g. `.claude/skills/…`).
6. Install **shared infra**: copy bundled `templates/` + `scripts/<variant>/` into `.specify/`, resolving `__SPECKIT_COMMAND_<NAME>__` placeholders using the integration's `invoke_separator`. Tracks every file in `speckit.manifest.json`.
7. Copy `constitution-template.md` → `.specify/memory/`.
8. Install the built-in **speckit workflow** → `.specify/workflows/speckit/`.
9. Persist `.specify/init-options.json` (`ai`, `integration`, `script`, `ai_skills`).
10. Auto-install the `agent-context` extension, wired to the integration's context file (e.g. `CLAUDE.md`).
11. If `--preset X`, install it from catalog / bundled / local.
12. `chmod +x` the scripts. Print next-steps panel.

No network needed — templates are bundled in the pip package.

## 4. The command pipeline

Ten authored command templates under `templates/commands/`. Canonical order and artifacts:

| # | Command | Calls script | Reads template | Writes artifact | Asks user? |
|---|---------|--------------|----------------|-----------------|------------|
| 1 | `/speckit.constitution` | — | `constitution-template.md` | `.specify/memory/constitution.md` | refines principles |
| 2 | `/speckit.specify` | (branch via git ext.) | `spec-template.md` | `specs/NNN-slug/spec.md` + `checklists/requirements.md`, `.specify/feature.json` | ≤3 `[NEEDS CLARIFICATION]` |
| 3 | `/speckit.clarify` | `check-prerequisites.sh --json --paths-only` | — | updates `spec.md` | **≤5 sequential questions** |
| 4 | `/speckit.plan` | `setup-plan.sh --json` | `plan-template.md` | `plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md` | no |
| 5 | `/speckit.tasks` | `setup-tasks.sh --json` | `tasks-template.md` | `tasks.md` | no |
| 6 | `/speckit.analyze` | `check-prerequisites.sh --json --require-tasks --include-tasks` | — | **read-only** consistency report | offers fixes |
| 7 | `/speckit.checklist` | `check-prerequisites.sh --json` | `checklist-template.md` | `checklists/<domain>.md` | ≤5 questions |
| 8 | `/speckit.implement` | `check-prerequisites.sh --json --require-tasks --include-tasks` | — | **application code**; marks `tasks.md` `[X]` | confirms on incomplete checklists |
| 9 | `/speckit.converge` | `check-prerequisites.sh …` | — | **appends** `## Phase N: Convergence` to `tasks.md` | no |
| 10 | `/speckit.taskstoissues` | `check-prerequisites.sh …` | — | GitHub issues (dedup) | no |

The artifacts accrete inside one feature directory:

```
specs/NNN-slug/
├── spec.md            ← specify  (WHAT & WHY — user stories, FR-xxx, SC-xxx, [NEEDS CLARIFICATION])
├── checklists/
│   ├── requirements.md
│   └── <domain>.md    ← checklist
├── research.md        ← plan  (Phase 0)
├── data-model.md      ← plan  (Phase 1)
├── contracts/         ← plan  (Phase 1)
├── quickstart.md      ← plan  (Phase 1)
├── plan.md            ← plan  (HOW — tech approach)
└── tasks.md           ← tasks (ordered, dependency-aware; [X] as implemented)
```

## 5. The script contract — who calls whom

The agent never guesses paths. Each command shells out to a script that prints **JSON** the agent parses. The plumbing brain is `common.sh`:

- `get_repo_root()` — finds `.specify/` marker upward, honors `SPECIFY_INIT_DIR`.
- `get_feature_paths()` — emits `REPO_ROOT, CURRENT_BRANCH, FEATURE_DIR, FEATURE_SPEC, IMPL_PLAN, TASKS, RESEARCH, DATA_MODEL, QUICKSTART, CONTRACTS_DIR`.
- `read_feature_json_feature_directory()` — reads `.specify/feature.json` (jq → python3 → grep/sed fallback) to know the "current feature".
- `resolve_template(name)` — walks the layering stack (§6).
- `format_speckit_command(name)` — picks `.` vs `-` separator from `.specify/integration.json`.

Per-script JSON outputs (the contract surface):

```
create-new-feature.sh  "desc"  → { BRANCH_NAME, SPEC_FILE, FEATURE_NUM }   ; mkdir specs/NNN-slug, write spec.md, persist feature.json
setup-plan.sh                   → { FEATURE_SPEC, IMPL_PLAN, SPECS_DIR, BRANCH }
setup-tasks.sh                  → { FEATURE_DIR, AVAILABLE_DOCS[], TASKS_TEMPLATE }
check-prerequisites.sh          → { FEATURE_DIR, AVAILABLE_DOCS[] }         ; --paths-only → { REPO_ROOT, BRANCH, FEATURE_DIR, FEATURE_SPEC, IMPL_PLAN, TASKS }
```

Feature numbering: scan `specs/` for highest `^\d{3,}-` prefix, `+1`, `printf %03d` → `001-slug` (or `--timestamp` → `YYYYMMDD-HHMMSS-slug`). Branch name = `NNN-<3–4 meaningful words, stop-words filtered>`, ≤244 bytes.

**Control flow of a single command (e.g. `/speckit.plan`):**

```
user types /speckit.plan
   │
   ▼
agent reads templates/commands/plan.md   (the prompt template)
   │  step 1: run scripts/bash/setup-plan.sh --json
   ▼
setup-plan.sh
   │  source common.sh → get_feature_paths() → resolve_template("plan-template")
   │  mkdir -p FEATURE_DIR ; create plan.md from template
   └─▶ prints { FEATURE_SPEC, IMPL_PLAN, SPECS_DIR, BRANCH }
   │
   ▼
agent parses JSON, reads FEATURE_SPEC + constitution + plan-template
   │  fills plan.md, emits research.md / data-model.md / contracts/ / quickstart.md
   ▼
agent suggests next: /speckit.tasks
```

Every command follows the same shape: **read prompt template → run plumbing script → parse JSON → read inputs → write markdown → suggest next command.** The "call graph" is therefore a fixed pipeline, not dynamic dispatch.

## 6. Template resolution layering

Templates and commands are not hard-coded — they resolve through a priority stack (implemented identically in Python `PresetResolver`, Bash `resolve_template`, PowerShell `Resolve-Template`):

```
highest ┌─ .specify/templates/overrides/<name>.md      (project one-off)
        ├─ .specify/presets/<id>/templates/<name>.md    (sorted by priority)
        ├─ .specify/extensions/<id>/templates/<name>.md
lowest  └─ .specify/templates/<name>.md                 (core default)
```

Composition strategies per layer: `replace` (default), `prepend`, `append`, `wrap` (lower layer substituted into `{CORE_TEMPLATE}`). **This is the single most important hook for a perf variant** — you reshape spec/plan/tasks meaning without forking core.

## 7. Integrations (one author, many agents)

An **integration** is an adapter that materializes the once-authored command into a specific agent's native format:

- **invoke_separator** — `.` (Markdown agents → `/speckit.specify`) vs `-` (skills agents → `/speckit-specify`).
- **arg placeholder** — `$ARGUMENTS` (Markdown) vs `{{args}}` (TOML).
- **context_file** — `CLAUDE.md`, `GEMINI.md`, etc.
- **setup()** — writes files to the right place (`.claude/skills/…/SKILL.md`, `.gemini/…/specify.toml`, `.copilot/*.prompt.md`).

Families: `SkillsIntegration` (Claude), `MarkdownIntegration` (Copilot/Cursor/Windsurf), `TomlIntegration` (Gemini/Qwen/Tabnine), plus `generic`. 30+ agents supported.

## 8. Presets vs Extensions vs Bundles

| Concept | Does what | Mechanism | Example |
|---------|-----------|-----------|---------|
| **Preset** | Reshapes existing commands/templates (terminology, format, gates) | Overrides via the layering stack + `strategy` | `lean` (minimal prompts/artifacts) |
| **Extension** | Adds NEW commands + lifecycle hooks | `extension.yml` → `provides.commands`, `hooks.before_*/after_*` | `git` (`/speckit.git.commit`, `before_specify`→branch), `bug` (`/speckit.bug.assess/.fix/.test`) |
| **Bundle** | Packages a preset + extensions by role, versioned | `bundle.yml` | `business-analyst`, `product-manager`, `security-researcher` |

`extension.yml` shape (abridged):

```yaml
extension: { id: git, name: ..., version: 1.0.0 }
requires: { speckit_version: ">=0.2.0", tools: [{name: git, required: false}] }
provides:
  commands:
    - { name: speckit.git.feature, file: commands/speckit.git.feature.md }
  config:
    - { name: git-config.yml, template: config-template.yml }
hooks:
  before_specify: { command: speckit.git.feature, optional: false }
  after_specify:  { command: speckit.git.commit, optional: true, prompt: "Commit?" }
```

Commands follow `speckit.<ext-id>.<cmd>`. Hooks fire automatically around core phases.

## 9. The workflow engine (automation layer)

`workflow.yml` turns the manual command sequence into an automated, gated pipeline. The shipped `speckit` workflow:

```yaml
steps:
  - { id: specify,     command: speckit.specify, input: { args: "{{inputs.spec}}" } }
  - { id: review-spec, type: gate, message: "Review the generated spec…", on_reject: abort }
  - { id: plan,        command: speckit.plan }
  - { id: review-plan, type: gate, on_reject: abort }
  - { id: tasks,       command: speckit.tasks }
  - { id: implement,   command: speckit.implement }
```

`engine.py` executes step types: **command, prompt, shell, init, gate** (human pause/resume), **if/switch** (branch), **while/do-while** (loop, `max_iterations`), **fan_out/fan_in** (per-item dispatch + aggregate, `max_concurrency`). State saved per step to `.specify/workflows/runs/<run_id>/state.json`; gates pause until `specify workflow resume`. Expressions: `{{ steps.plan.output.file }}`, filters (`default`, `join`, `contains`, `map`, `from_json`).

This is the primitive that lets a perf pipeline auto-chain *specify → plan → tasks → implement → **run → analyze → gate*** with review gates and a `do-while` retest loop.

## 10. The one-paragraph summary

Spec-kit = **(a)** a CLI that scaffolds `.specify/` into your repo for your chosen agent, **(b)** ten markdown command-prompts that drive the agent through a constitution → spec → clarify → plan → tasks → implement chain, each writing a durable artifact into `specs/NNN-slug/`, **(c)** small bash scripts that do deterministic numbering/pathing and hand the agent JSON, **(d)** a four-layer template-resolution stack (overrides > presets > extensions > core) so you can re-skin the whole thing for a new domain, and **(e)** a workflow engine that can run the chain automatically with human gates and loops. The extensibility points — **preset** (reshape), **extension** (add commands+hooks), **bundle** (package), **workflow** (automate) — are exactly the seams a performance-testing variant plugs into.
