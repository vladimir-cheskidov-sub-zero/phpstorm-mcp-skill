---
name: phpstorm-mcp-workflows
description: "Use whenever PhpStorm MCP is available for PHP project context, semantic navigation, inspections, structural search, refactoring, validation, and on-demand framework or capability overlays instead of plain text edits."
---

# PhpStorm MCP Workflows

Use this skill when PhpStorm MCP should be the source of truth for PHP project context, code structure, inspections, search, refactoring, and validation on PHP work.

## Reality Check

- Prefer the tools actually exposed in the current session over any memorized inventory.
- Tool exposure varies by IDE version, enabled plugins, and allow-list settings such as `idea_mcp_allowed_tools`.
- Start from project context on non-trivial PHP tasks.
- Keep the base workflow framework-agnostic and capability-light. Load overlays only when the task or project proves they are needed.

## Core Defaults

- Bootstrap PHP project context first: `get_php_project_config` -> `get_composer_dependencies` -> `get_project_modules` / `get_repositories` -> `get_run_configurations`.
- Prefer semantic tools over text tools for code: `search_symbol` -> `get_symbol_info` -> `read_file`.
- Prefer `get_inspections` over ad-hoc guessing.
- Use `apply_quick_fix` only after selecting an exact quick fix from `get_inspections`.
- Prefer `rename_refactoring` over `replace_text_in_file` for identifiers.
- Prefer `search_structural` over regex when the target is a PHP code shape.
- Inspect representative hits before bulk edits, even when the pattern looks obvious.
- After semantic refactors, audit strings, templates, route names, service IDs, config keys, and docs with `search_text`.
- For behavior changes, do not stop at `build_project`; run `execute_run_configuration` or the nearest project test path.
- Use `search_ide_actions` and `invoke_ide_action` only when no dedicated MCP tool exists and the action context is likely to complete safely.
- If a tool named here is unavailable, choose the next smallest safe tool and state the fallback explicitly.

## Core Workflows

### Bootstrap a PHP project

1. `get_php_project_config`
2. `get_composer_dependencies`
3. `get_project_modules` and `get_repositories`
4. `get_run_configurations`
5. If needed, `list_directory_tree` or `search_file` for entrypoints and config files
6. If Composer packages or layout identify a framework, load the matching file under `references/frameworks/`

### Investigate a symbol or code path

1. `search_symbol`
2. `get_symbol_info`
3. `read_file` around the declaration and key usages
4. Use `search_text` only for non-code references

### Fix an inspection-driven issue

1. `get_inspections`
2. If a precise quick fix exists, `apply_quick_fix`
3. Re-run `get_inspections`
4. `build_project` on touched files when the change is meaningful
5. Run behavior validation if the fix can affect runtime behavior

### Safe rename or bounded refactor

1. Inspect the declaration and likely usages with semantic tools
2. `rename_refactoring` for identifiers, or `search_ide_actions` before a dialog-driven refactor
3. Re-run `get_inspections`
4. `build_project`
5. `search_text` for non-code references the semantic change may not cover
6. Run behavior validation if a public API, framework entrypoint, or call pattern changed

### Syntax-aware cleanup or migration

1. `search_structural` or, if absent, `search_regex`
2. Inspect representative hits with `read_file`
3. Make the smallest safe edit: quick fix, targeted replace, or refactor
4. Re-run inspections and build
5. Escalate to reusable inspection tooling only when repetition is high

## Escalation Paths

Load additional references only when the task calls for them.

- Framework-specific discovery: `references/frameworks/`
- Database-assisted tasks: `references/capabilities/database.md`
- Runtime-only debugging: `references/capabilities/debugging.md`
- Large migration or repeated structural fixes: `references/capabilities/custom-inspections.md`
- Detailed tool-choice tables and refactoring fallbacks: `references/playbook.md`
- Version and documentation gap notes: `references/toolset-2026-1.md`

## Validation Ladder

Use the narrowest validation that can still catch the likely failure mode.

- Static-only edit: `get_inspections`
- Single-file semantic edit: `get_inspections` -> `build_project`
- Cross-file rename or refactor: `get_inspections` on touched files -> `build_project` on touched files -> `search_text` audit
- Behavior change: `get_inspections` -> `build_project` -> `execute_run_configuration` or project test command

## Guardrails

- Never text-replace an identifier if `rename_refactoring` can do it.
- Never treat `build_project` as enough validation for behavior changes.
- Never assume semantic refactoring covers strings, comments, templates, or config text.
- Never default to regex for a symbol or syntax-shaped problem.
- Never run mutating SQL through MCP unless the user intent and the target connection are both safe.
- Do not assume `invoke_ide_action` can drive modal dialogs end-to-end.
- Do not load framework or capability overlays speculatively.
- Reformat only after logic is stable.
- Prefer actual exposed tools over stale documentation snapshots.
