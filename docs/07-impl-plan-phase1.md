# Phase-1 Implementation Plan

> First buildable slice: **bundle/install skeleton (integration) → constitution preset → order intake**. Design ref: [doc 04](04-perf-speckit-design.md), mechanism map [doc 06 §9](06-decision-stack-and-harness.md). Build generic — no org/tool names (doc 03 rule).

## Naming & license
- **Repo + dir name:** `spec-kit-performance` — `spec-kit` prefix (canonical spelling) signals heritage + that it's an **addon** to spec-kit, matching the ecosystem convention (`spec-kit-preset-*` / `spec-kit-extension-*`). `repository:` URL uses a placeholder org (`https://github.com/<org>/spec-kit-performance`) — no specific org named.
- **License:** **Apache-2.0** for all manifests (`license: Apache-2.0`) + a root `LICENSE` (full Apache 2.0 text) + `NOTICE` (copyright/attribution).

## Repo layout (the bundle source = this repo)

```
bundles/spec-kit-performance/bundle.yml
presets/perf/preset.yml
              commands/speckit.constitution.md      # override of core constitution
              templates/constitution-template.md     # perf methodology content
extensions/perf/extension.yml
                commands/speckit.perf.order.md        # order intake
                templates/order-template.md           # order.md skeleton
```

## WS-A — Integration & bundle scaffold (POPULATED)  *(foundation; blocks B, C, D)*
> "Integration" = wiring our bundle so commands materialise in the agent. spec-kit's per-agent adapters are **inherited**, not rewritten.
> **Hard rule:** the scaffold fills BOTH the preset AND the extension immediately — no empty `provides`, no placeholder-only state at any commit.

- `git init` (trunk `main`, per CLAUDE.md release rules).
- `bundles/spec-kit-performance/bundle.yml` — `provides.presets:[perf]` + `provides.extensions:[perf]`, `requires.speckit_version`, `requires.mcp:[atlassian]`.
- `presets/perf/preset.yml` — **populated** `provides`: the constitution-template + `speckit.constitution` override (content delivered in WS-B; the preset is never empty — at minimum a working stub that already produces a perf constitution).
- `extensions/perf/extension.yml` — **populated** `provides.commands:[speckit.perf.order]` (content in WS-C; never an empty command list).
- So WS-B and WS-C fill the same preset/extension this WS creates — they are always in a valid, non-empty state. A delivers the populated skeleton; B/C deepen the content.
- Dev install loop: `specify preset add --dev <path>` / `specify extension add --dev <path>` (or `specify init --here --preset perf`); confirm both materialise for Claude (`process_template` placeholders resolve, `invoke_separator` `.`).
- **Acceptance:** preset AND extension both install and list non-empty; `/speckit.constitution` (perf) and `/speckit.perf.order` are invokable; no schema/registration errors.

## WS-B — Constitution preset  *(user feature)*
- `presets/perf/templates/constitution-template.md` — perf methodology content from the generic patterns ([doc 03](03-prior-art-inspiration.md)): test taxonomy, workload model, NFR/SLA contract, quality gate, SUT, data governance, role split, CI tiers. Two levels: org methodology vs per-repo instantiation (criticality → gate threshold).
- `presets/perf/preset.yml` → `provides.templates`: `{type: template, name: constitution-template, replaces: constitution-template}` + `{type: command, name: speckit.constitution, file: commands/speckit.constitution.md, replaces: speckit.constitution}`.
- `presets/perf/commands/speckit.constitution.md` — override of the core command (same frontmatter/structure), preset to emit the perf principles + pin this service's criticality.
- **Acceptance:** `/speckit.constitution` writes a perf `constitution.md` with the methodology sections + criticality pin; generic (grep clean of proprietary names).

## WS-C — Order intake  *(user feature)*
- `extensions/perf/commands/speckit.perf.order.md` — low-friction, wiki-aware intake. Frontmatter `description`; body: identify repo/branch → search wiki/issue tracker via **Atlassian MCP** → gentle plain-language questions (system, what to test / what NOT, repo+branch, arch-diagram/requirements link, rough load *optional*) → draft `order.md`. **No numbers required; plain language only.**
- `extensions/perf/templates/order-template.md` — order skeleton: service, repo, branch, concern, in/out-of-scope, source links, load expectation in user's words.
- `extensions/perf/extension.yml` → `provides.commands:[speckit.perf.order]`, `requires.mcp:[atlassian]`. (Hook `before_specify→perf.sut` deferred to a later phase.)
- **Acceptance:** `/speckit.perf.order` runs the gentle Q-loop, optionally pulls wiki context, writes a plain-language `order.md`.

## WS-D — Discoverability via `specify` (publish path; do early-ish, parallel to B/C)
> Hard rule: everything through the spec-kit CLI (CLAUDE.md). This WS makes the bundle install/search via `specify`.
- Per-component: README + LICENSE (Apache-2.0) + semver + a **GitHub Release** whose archive zip is the `download_url`.
- Local dev loop: `specify preset add --dev <path>` · `specify preset resolve <tmpl>` · `specify preset info <id>` · `specify extension add --dev <path>`.
- Catalog submission: PR adding entries (alphabetical by `id`) to spec-kit's `presets/catalog.community.json` + `extensions/catalog.community.json` + rows in `docs/community/*.md`. Verified → appears in `specify ... search`.
- IDs: descriptive, lowercase-hyphen. Bundle id `spec-kit-performance` (so `specify init --preset spec-kit-performance`); preset id `performance-methodology`; extension id `performance`. Repo `spec-kit-performance` holds all three (one repo, per-component release zips — like multi-preset repos in the catalog).
- **Acceptance:** `specify preset add --dev` installs locally; entries valid for catalog schema; after a (mock) catalog entry, `specify preset search perf` would list it.

## Order & dependencies
A → then B, C, D in parallel. Defer: spec/clarify/plan presets, sut/run/analyze/report extension commands, the workflow, fleet layer.

## Open check
Confirm "integration" = this bundle/install wiring (agent adapters inherited). If a *custom agent integration* is intended instead, WS-A changes scope.
