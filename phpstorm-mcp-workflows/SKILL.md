---
name: phpstorm-mcp-workflows
description: "Use whenever PhpStorm MCP is available for PHP project context, semantic-first navigation, inspections, structural search, refactoring, validation, and on-demand overlays before falling back to low-level or external tooling."
---

# PhpStorm MCP Workflows

Use this skill when PhpStorm MCP should be the source of truth for PHP project context, code structure, inspections, search, refactoring, and validation on PHP work.

## Reality Check

- Prefer the tools actually exposed in the current session over any memorized inventory.
- Tool exposure varies by IDE version, enabled plugins, and allow-list settings such as `idea_mcp_allowed_tools`.
- Start from project context on non-trivial PHP tasks.
- For PHP code, start with the richest PhpStorm answer available: framework-aware tools, semantic navigation, inspections, structural search, or IDE actions before low-level reads or text search.
- When semantics are exhausted and low-level access is still needed, prefer PhpStorm MCP readers and searchers over shell commands or raw filesystem tooling when the cost is comparable.
- Keep the base workflow framework-agnostic and capability-light. Load overlays only when the task or project proves they are needed.

## Core Defaults

- Bootstrap PHP project context first. For repeated field work, prefer `scripts/phpstorm-project-bootstrap.php` to run `get_php_project_config`, `get_composer_dependencies`, `get_project_modules`, `get_repositories`, and `get_run_configurations` in one MCP session.
- For PHP code, ask the strongest question first: framework-aware tools, `get_inspections`, `search_symbol`, `get_symbol_info`, or `search_structural` before `read_file`, `search_text`, or regex.
- Prefer semantic tools over text tools for code: `search_symbol` -> `get_symbol_info` -> `read_file`.
- Prefer lower-level PhpStorm MCP tools such as `read_file`, `search_file`, `search_text`, and `search_regex` over external shell or filesystem tools when both can solve the task with similar effort.
- Prefer `get_inspections` over ad-hoc guessing.
- Use `apply_quick_fix` only after selecting an exact quick fix from `get_inspections`.
- Prefer `rename_refactoring` over `replace_text_in_file` for identifiers.
- Prefer `search_structural` over regex when the target is a PHP code shape.
- Treat external CLI search or read tooling as fallback only when PhpStorm MCP lacks the capability or is materially less effective.
- For high-volume batches, use MCP for bootstrap, representative sampling, inspections, and disputed cases rather than every identical occurrence.
- Keep MCP endpoint settings in `config/mcp.php`; create or overwrite it with `scripts/configure-mcp.sh <mcp-url>` and do not hard-code the PhpStorm stream URL in scripts.
- When a repeated MCP sequence costs multiple agent cycles, add a PHP 7.4-compatible script under `scripts/` and use it for the current batch.
- If any helper script exits with an error, stop that execution path immediately, surface the script error, and give concrete remediation steps before continuing.
- Inspect representative hits before bulk edits, even when the pattern looks obvious.
- After semantic refactors, audit strings, templates, route names, service IDs, config keys, and docs with `search_text`.
- For behavior changes, do not stop at `build_project`; run `execute_run_configuration` or the nearest project test path.
- Use `search_ide_actions` and `invoke_ide_action` only when no dedicated MCP tool exists and the action context is likely to complete safely.
- If a tool named here is unavailable, choose the next smallest safe tool and state the fallback explicitly.

## Core Workflows

### Bootstrap a PHP project

1. Prefer `scripts/phpstorm-project-bootstrap.php --project-path <path>` for field work.
2. Otherwise call `get_php_project_config`
3. `get_composer_dependencies`
4. `get_project_modules` and `get_repositories`
5. `get_run_configurations`
6. If needed, `list_directory_tree` or `search_file` for entrypoints and config files
7. If Composer packages or layout identify a framework, load the matching file under `references/frameworks/`

### Investigate a symbol or code path

1. `search_symbol`
2. `get_symbol_info`
3. `read_file` around the narrowed declaration and key usages
4. Use `search_text` only for non-code references

### Investigate a type or data-flow question

1. `get_symbol_info`
2. `get_inspections` if a diagnostic is involved
3. `search_ide_actions` for `ExpressionTypeInfo`, `SliceBackward`, or `SliceForward` if no dedicated MCP tool answers the question directly
4. `invoke_ide_action` only when the session already has a reliable editor and caret target at the expression; otherwise treat these IDE actions as manual-only fallback
5. `read_file` or `search_structural` only after the semantic or IDE-assisted step has narrowed the target

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

### High-volume field automation

1. Create or overwrite MCP connection settings with `scripts/configure-mcp.sh <mcp-url>`.
2. Store only concrete local settings in `config/mcp.php`; keep `config/mcp.php.dist` as a placeholder template.
3. Use `scripts/mcp-tool.php` for one-off direct tool calls from shell scripts.
4. Use `scripts/phpstorm-project-bootstrap.php` for project bootstrap in one request cycle.
5. Use `scripts/phpstorm-batch-inspections.php` to run `get_inspections` over a known file list in one MCP session.
6. If a repeated MCP sequence is missing, add a small PHP 7.4-compatible script in `scripts/` instead of repeating manual tool calls.
7. Keep scripts dry-run/reporting by default when they can mutate files or influence a batch decision.

### Script failure handling

1. Treat any non-zero exit from `scripts/` helpers as a hard stop for that workflow branch.
2. Report the original stderr or exception text instead of masking it with a fallback action.
3. Give the smallest corrective action that can unblock the user, then resume only after that prerequisite is satisfied.
4. If `config/mcp.php` is missing or contains unresolved placeholders, tell the user to run `scripts/configure-mcp.sh <mcp-url>` before retrying.

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
- Never start PHP code investigation with text search, regex, or file reads if a semantic or framework-aware PhpStorm path can answer it first.
- Never bypass equivalent PhpStorm MCP readers or searchers with external shell tooling unless the IDE path is unavailable or materially less effective.
- Never treat `build_project` as enough validation for behavior changes.
- Never assume semantic refactoring covers strings, comments, templates, or config text.
- Never default to regex for a symbol or syntax-shaped problem.
- Never run mutating SQL through MCP unless the user intent and the target connection are both safe.
- Do not assume `invoke_ide_action` can drive modal dialogs end-to-end.
- Do not load framework or capability overlays speculatively.
- Reformat only after logic is stable.
- Prefer actual exposed tools over stale documentation snapshots.
