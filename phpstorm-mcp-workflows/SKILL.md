---
name: phpstorm-mcp-workflows
description: "Use whenever PhpStorm MCP tools are available and the task involves IDE-backed code navigation, semantic search, inspections, quick fixes, safe rename, change signature, safe delete, structural search, or refactoring instead of plain text edits."
---

# PhpStorm MCP Workflows

Use this skill when PhpStorm MCP should be the source of truth for code structure: understanding symbols, finding usages semantically, applying inspections and quick fixes, renaming safely, or making syntax-aware refactorings.

## Defaults

- Prefer semantic tools over text tools for symbols: `search_symbol` -> `get_symbol_info` -> `read_file`.
- Prefer `get_inspections` over ad-hoc guessing; it returns locations, severity, and available quick fixes.
- Prefer `apply_quick_fix` only after selecting a specific quick fix from `get_inspections`.
- Prefer `rename_refactoring` over `replace_text_in_file` for identifiers.
- Prefer `search_structural` over regex when the target is a code shape.
- Prefer `read_file` for chunked or surgical reading; use `get_file_text_by_path` only for short files.
- After edits, re-run `get_inspections` on touched files; then use `build_project` for changed files when the edit was non-trivial.
- Use `invoke_ide_action` only when no dedicated tool exists. Many refactoring actions open dialogs or rely on editor selection; treat them as fallback, not default.

## Canonical Workflows

### Investigate a symbol

1. `search_symbol`
2. `get_symbol_info`
3. `read_file` around the declaration or usage

### Fix an inspection-driven issue

1. `get_inspections`
2. If a precise quick fix exists, `apply_quick_fix`
3. Re-run `get_inspections`
4. `build_project` on touched files if the change was meaningful

### Safe rename

1. `search_symbol` or inspect the declaration directly
2. `rename_refactoring`
3. `get_inspections`
4. `build_project`

### Syntax-aware cleanup or migration

1. `search_structural` or `search_regex`
2. Inspect a few hits with `read_file`
3. Make the smallest safe edit: quick fix, targeted replace, or refactoring
4. Re-run inspections and build

### Fallback to IDE actions

1. `search_ide_actions`
2. `invoke_ide_action` with `filePaths` context when applicable
3. Re-run `get_inspections`
4. `build_project`

## Tool Selection Rules

- `search_symbol`: classes, methods, fields, constants, functions, anything name-based and semantic
- `get_symbol_info`: declaration, signature, docs, inferred type, jump target
- `search_text` or `search_regex`: exact or regex search when semantics do not matter
- `search_structural`: AST-shaped PHP patterns, especially method calls, assignments, constructors, inheritance, and suspicious constructs
- `replace_text_in_file`: mechanical text edits only after the target set is bounded
- `rename_refactoring`: any symbol rename with references
- `apply_quick_fix`: inspection-backed exact fix from the IDE
- `build_project`: syntax or compile validation after meaningful edits
- `execute_terminal_command`: last resort when the IDE or MCP toolset cannot validate or transform the code

## Guardrails

- Never text-replace an identifier if `rename_refactoring` can do it.
- Never use regex first for a symbol problem.
- Do not assume `invoke_ide_action` can drive interactive dialogs end-to-end.
- Use `search_structural` before regex for code migrations.
- Reformat only after logic is stable.

Read [playbook.md](references/playbook.md) when you need the detailed decision table, high-value action IDs, structural-search patterns, or validation ladders.
