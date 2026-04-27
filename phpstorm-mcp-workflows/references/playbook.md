# Playbook

This reference is for choosing the smallest trustworthy PhpStorm MCP tool for PHP project context, inspections, refactoring, syntax-aware search, validation, and on-demand framework or capability overlays.

## Toolset Reality

- The public `mcp-server.html` help page is useful, but it is not an exhaustive inventory of the PHP-oriented toolset exposed by recent PhpStorm 2026.1.x builds.
- Actual availability depends on IDE version, enabled plugins, and the agent-side allow-list such as `idea_mcp_allowed_tools`.
- Prefer the tools actually exposed in the current MCP session over any remembered list.

## Decision Order

1. Use the richest PhpStorm MCP answer available for PHP code first: framework-aware tools, `get_inspections`, `search_symbol`, `get_symbol_info`, `search_structural`, safe refactorings, or targeted IDE actions.
2. If the target is already narrowed, use lower-level PhpStorm MCP readers and searchers such as `read_file`, `search_file`, `search_text`, or `search_regex`.
3. Use non-PhpStorm tooling only as a fallback when MCP cannot answer the question or is materially less efficient for that specific step.

Practical rule:

- If you are about to read files or run text search to discover PHP code structure, stop and ask whether a semantic or framework-aware PhpStorm tool can narrow the scope first.

## Start Here

- The task is non-trivial PHP work: `get_php_project_config` -> `get_composer_dependencies` -> `get_project_modules` / `get_repositories` -> `get_run_configurations`
- The target is a symbol: `search_symbol` -> `get_symbol_info` -> `read_file`
- The question is about type, inferred value, or data flow: `get_symbol_info` -> `search_ide_actions` for `ExpressionTypeInfo`, `SliceBackward`, or `SliceForward` -> `invoke_ide_action` only with usable editor and caret context -> bounded `read_file` or `search_structural`
- The target is a file path or filename: `search_file` or `find_files_by_name_keyword`
- The target is a plain text fragment: `search_text`
- The target is a regex pattern: `search_regex`
- The target is a PHP syntax shape: `search_structural`
- The task is a file-level problem list: `get_inspections`
- The task is a symbol rename: `rename_refactoring`
- The task is a known inspection-backed fix: `apply_quick_fix`
- The task is validation after semantic edits: `get_inspections` -> `build_project` -> tests or `execute_run_configuration`
- The task clearly belongs to a known framework: read the matching file under `references/frameworks/`
- The task needs database context: read `references/capabilities/database.md`
- The task is runtime-only and static tools are not enough: read `references/capabilities/debugging.md`
- The task is a large repeated migration or inspection campaign: read `references/capabilities/custom-inspections.md`

## Bootstrap a PHP Project

Use this workflow before making non-trivial edits.

1. `get_php_project_config`
2. `get_composer_dependencies`
3. `get_project_modules`
4. `get_repositories`
5. `get_run_configurations`
6. If needed, `list_directory_tree` or `search_file` for entrypoints and key config files

What this gives you:

- PHP language level versus actual interpreter runtime
- Available Composer packages and exact versions
- Monorepo or multi-module boundaries
- VCS root layout
- Named validation targets you can run later

Practical rule:

- If you do not know the PHP version, interpreter, or test entrypoint yet, you are not ready to refactor confidently.

## On-Demand Overlays

Keep the base playbook framework-agnostic and capability-light.

Load extra references only when project context or the task gives you clear evidence they are needed.

Framework overlays:

- `references/frameworks/laravel.md`

Capability overlays:

- `references/capabilities/database.md`
- `references/capabilities/debugging.md`
- `references/capabilities/custom-inspections.md`

## Canonical Tool Choice

### Project context

- `get_php_project_config`: first stop for PHP runtime, interpreter, language level, extensions, and debuggers
- `get_composer_dependencies`: check available packages and exact versions before generating or editing framework code
- `get_project_modules`: identify modules in multi-module projects
- `get_project_dependencies`: high-level dependency inventory beyond Composer
- `get_repositories`: detect VCS roots in monorepos or nested repositories
- `get_run_configurations`: preferred source for existing validation commands

### Read and navigate

- `read_file`: default bounded reader after semantic narrowing; use slices, ranges, or indentation mode for large files
- `get_file_text_by_path`: only when the file is short, already known, and you want plain text quickly
- `open_file_in_editor`: only when a human-visible editor state or IDE action context matters
- `get_all_open_file_paths`: useful only when current editor state matters

### Find files

- `search_file`: canonical glob-based file search; supports include and exclude path filters
- `find_files_by_name_keyword`: fastest when you know part of a filename
- `find_files_by_glob`: acceptable classic glob search when that is the simplest expression
- `list_directory_tree`: use for folder layout, not for content search

### Search code and symbols

- `search_symbol`: default for code identifiers and declarations
- `get_symbol_info`: declaration, signature, docs, and inferred type at a specific position
- `search_ide_actions` plus `invoke_ide_action`: type and data-flow fallback for IDE-native actions such as `ExpressionTypeInfo`, `SliceBackward`, and `SliceForward` when no dedicated MCP API exists
- `search_text`: default project-wide text search for strings, config keys, docs, templates, and other non-code references; not the first tool for PHP code discovery
- `search_regex`: regex search when semantics do not matter, structural search is not a fit, and plain text really is the target
- `search_in_files_by_text` and `search_in_files_by_regex`: alternatives when directory plus file mask parameters are more convenient than glob paths
- `search_structural`: syntax-aware search; prefer it over regex for API migrations or repeated code shapes
- `get_structural_patterns`: use when you want known-working PHP SSR examples before writing a custom pattern

### Inspect and refactor

- `get_inspections`: default diagnostic tool whenever quick fixes might matter
- `get_file_problems`: lighter read-only diagnostics when quick-fix metadata is irrelevant
- `apply_quick_fix`: requires the exact quick-fix name from `get_inspections`
- `rename_refactoring`: default for identifiers; do not emulate rename with text replacement
- `replace_text_in_file`: mechanical edits only after semantic discovery has bounded the target set
- `search_ide_actions` and `invoke_ide_action`: fallback for refactorings with no dedicated MCP tool
- `reformat_file`: use after logic is stable, not as a discovery step

### Validation and execution

- `build_project`: structural or compile validation after meaningful edits; prefer targeted files over full rebuilds
- `execute_run_configuration`: preferred behavior validation when a project already defines the right run target
- `execute_terminal_command`: last resort when the IDE toolset cannot validate the change or the project relies on CLI-only workflows

## Workflow Recipes

### Investigate a symbol or code path

1. `search_symbol`
2. `get_symbol_info`
3. `read_file` around the declaration and a few key usages
4. `search_text` only for non-code references

### Investigate a type or data-flow question

1. `get_symbol_info`
2. `get_inspections` if the question is tied to a warning or error
3. `search_ide_actions` for `ExpressionTypeInfo`, `SliceBackward`, or `SliceForward`
4. `invoke_ide_action` only when the session already has a reliable editor and caret target at the expression; otherwise treat these IDE actions as manual-only fallback
5. `read_file` or `search_structural` only after the semantic or IDE-assisted step has narrowed the target

### Fix an inspection-driven issue

1. `get_inspections`
2. If a suitable quick fix exists, use `apply_quick_fix`
3. Re-run `get_inspections`
4. `build_project`
5. If behavior changed, run the nearest tests or `execute_run_configuration`

### Safe rename with post-audit

1. `search_symbol`
2. `rename_refactoring`
3. `get_inspections`
4. `build_project`
5. `search_text` for comments, strings, config keys, routes, templates, and docs the semantic rename may not cover
6. Run behavior validation for public APIs and framework entrypoints

### Change signature

1. Inspect the callable and likely call sites
2. Prefer a dedicated refactoring path if your client exposes one directly
3. Otherwise use `search_ide_actions` for `ChangeSignature`
4. `invoke_ide_action` only when the context is straightforward and the action is likely to finish unattended
5. Re-run `get_inspections`
6. `build_project`
7. Run tests or `execute_run_configuration`

### Safe delete

1. Inspect declaration and usages
2. `search_ide_actions` for `SafeDelete`
3. `invoke_ide_action` only when the context is simple
4. Re-run `get_inspections`
5. `build_project`
6. Run tests or the nearest validation target

### Syntax-aware migration or cleanup

1. `search_structural`
2. Inspect representative hits with `read_file`
3. If repetition is high, consider `references/capabilities/custom-inspections.md`
4. Apply the smallest edit that preserves behavior
5. Re-run inspections and build
6. Run behavior validation for public or framework-facing changes

### Project-wide inspection or migration campaign

1. Bootstrap the project context
2. Define the scope narrowly
3. Start with a representative sample
4. Prefer reusable patterns or inspection-driven fixes over one-off edits
5. Apply the change set
6. Re-run inspections on touched files
7. Build touched files
8. Run the relevant run configuration or test command

### Framework-specific investigation

1. Detect the framework from Composer packages or recognizable project files
2. Read the matching file under `references/frameworks/`
3. Follow that overlay for discovery
4. Return to the core edit and validation workflow afterward

## Validation Ladders

Use the narrowest validation that can still catch the likely failure mode.

### Static-only edit

- `get_inspections`

### Single-file semantic edit

- `get_inspections` -> `build_project`

### Cross-file rename or refactor

- `get_inspections` on touched files -> `build_project` on touched files -> `search_text` audit for non-code references

### Behavior change

- `get_inspections` -> `build_project` -> `execute_run_configuration` or project test command

### Database-affecting change

- Static validation first
- Read `references/capabilities/database.md`
- Run mutating SQL only when the user explicitly wants it and the target connection is safe

## IDE Action Fallback

Always search for the action ID first with `search_ide_actions`.

High-value actions for PHP work:

- `ChangeSignature`
- `SafeDelete`
- `RenameElement`
- `ExtractMethod`
- `Inline`
- `ExtractInterface`
- `ExtractSuperclass`
- `PhpExtractClassAction`
- `Unwrap`
- `OptimizeImports`

Practical rule:

- Use `invoke_ide_action` confidently for non-dialog cleanup actions.
- Use it cautiously for dialog-heavy refactorings.
- If an action depends on editor selection or modal input, prefer a dedicated MCP tool or a smaller manual edit followed by inspections.

## Anti-patterns

- Starting with `search_regex` when `search_symbol` or `search_structural` would be safer
- Starting with `read_file`, `search_text`, or external shell search when `get_inspections`, `search_symbol`, framework-aware tools, or `search_structural` could narrow the target first
- Using `replace_text_in_file` to rename a symbol
- Using external CLI search or read commands before equivalent PhpStorm MCP tools without a clear efficiency reason
- Stopping at `build_project` after a behavior change
- Ignoring strings, templates, config keys, and docs after a semantic refactor
- Treating `apply_quick_fix` as a generic substitute for all intention actions
- Depending on `invoke_ide_action` for dialog-heavy refactorings without a fallback plan
- Loading framework or capability overlays before they are actually needed
- Trusting the public docs page as an exhaustive tool inventory for 2026.1 builds
- Running mutating SQL without a safe connection and explicit user intent
- Starting a debugger before cheaper static or behavioral validation has failed
- Reformatting too early and hiding the meaningful diff
