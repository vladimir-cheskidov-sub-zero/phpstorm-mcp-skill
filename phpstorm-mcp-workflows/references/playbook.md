# Playbook

This reference is for choosing the smallest trustworthy PhpStorm MCP tool for inspections, refactoring, and syntax-aware code search.

## Start Here

- The target is a symbol: `search_symbol` -> `get_symbol_info` -> `read_file`
- The target is a file path or filename: `find_files_by_name_keyword` or `search_file`
- The target is a plain text fragment: `search_text`
- The target is a regex pattern: `search_regex`
- The target is a PHP syntax shape: `search_structural`
- The task is a file-level problem list: `get_inspections`
- The task is a symbol rename: `rename_refactoring`
- The task is a known IDE quick fix: `apply_quick_fix`
- The task is validation after edits: `get_inspections` -> `build_project`

## Canonical Tool Choice

### Read and navigate

- `read_file`: default reader; use slices, ranges, or indentation mode for large files.
- `get_file_text_by_path`: only when the file is short and you want plain text quickly.
- `open_file_in_editor`: only when a human-visible editor state or IDE action context matters.
- `get_all_open_file_paths`: useful only when current editor state matters.

### Find files

- `find_files_by_name_keyword`: fastest when you know part of a filename.
- `search_file`: canonical glob-based file search; supports include and exclude path filters.
- `find_files_by_glob`: acceptable classic glob search when that is the simplest expression.
- `list_directory_tree`: use for folder layout, not for content search.

### Search code and symbols

- `search_symbol`: default for code identifiers and declarations.
- `get_symbol_info`: enriches a symbol hit with declaration, signature, docs, and type info.
- `search_text`: default project-wide text search.
- `search_regex`: default project-wide regex search.
- `search_in_files_by_text` and `search_in_files_by_regex`: legacy alternatives when directory-plus-fileMask parameters are more convenient than path globs.
- `search_structural`: syntax-aware search; prefer it over regex for code migrations or API usage patterns.
- `get_structural_patterns`: use when you want known-working SSR examples before writing a custom pattern.

### Inspect and fix

- `get_inspections`: default diagnostic tool. Prefer this whenever you might want to apply quick fixes.
- `get_file_problems`: lighter read-only diagnostic view; use only when quick fixes are irrelevant.
- `apply_quick_fix`: requires the exact quick-fix name from `get_inspections`, plus its line and column.
- `apply_quick_fix` covers inspection-backed quick fixes, not arbitrary `Alt+Enter` intention actions.
- `reformat_file`: use after logic is stable, not as a discovery step.
- `build_project`: use after meaningful edits, especially cross-file or refactoring-heavy ones. Prefer `filesToRebuild` over a full rebuild.

## Refactoring Rules

- `rename_refactoring` is the default for identifiers. Do not emulate rename with text replacement.
- `rename_refactoring` should be treated as code-aware rename. If comments, strings, or text files also matter, audit them separately with `search_text` after the rename.
- `replace_text_in_file` is for mechanical edits, strings, comments, config keys, or tightly bounded code changes after semantic discovery.
- `search_structural` plus targeted edit is the default path for repetitive syntax-shaped migrations.
- `invoke_ide_action` is a fallback for refactorings that have no dedicated MCP tool.

## IDE Action Fallback

Always search for the action ID first with `search_ide_actions`. Then call `invoke_ide_action` with `filePaths` context when possible.

High-value action IDs available in the current IDE:

- `RenameElement`: fallback rename action; use `rename_refactoring` first when possible
- `ChangeSignature`: can rename a callable, change return type, add or remove parameters, reorder parameters, and update call sites; often dialog-driven
- `SafeDelete`: usage-aware delete; likely to open usages or confirmation dialogs
- `ExtractMethod`: usually needs a precise editor selection; unreliable unattended
- `Inline`: inline method or variable; context-sensitive and often interactive
- `PhpExtractClassAction`: PHP extract-class refactoring; likely interactive
- `ExtractInterface`: likely interactive
- `ExtractSuperclass`: likely interactive
- `ExtractModule`: likely interactive
- `ExtractInclude`: extract selected code to an include file; selection-dependent
- `Unwrap`: can be useful for safe removal of wrapping constructs
- `OptimizeImports`: safe cleanup after edits
- `Refactorings.QuickListPopupAction`: opens the context refactoring popup; useful for discovery, not automation

Practical rule:

- Use `invoke_ide_action` confidently for non-dialog cleanup actions.
- Use it cautiously for dialog-heavy refactorings.
- If an action depends on editor selection or modal input, prefer a dedicated MCP tool or a smaller manual edit followed by inspections.
- If you need a full UI-driven refactoring preview or conflict resolution flow, do not assume `invoke_ide_action` can drive it unattended.

## Inspection Workflow

1. Run `get_inspections` on the touched file.
2. If needed, narrow with `minSeverity`: `ERROR`, `WARNING`, `WEAK_WARNING`, or `INFORMATION`.
3. If a suitable quick fix exists, use `apply_quick_fix` with the exact quick-fix name.
4. Re-run `get_inspections`.
5. If the edit changed executable code, run `build_project` on the touched files.

Use `get_file_problems` only when you want a quicker read-only error list and do not need quick-fix metadata.

## Structural Search Recipes

Use `fileType: PHP` and a narrow directory scope whenever possible.

Good starting patterns for PHP:

- Instance method call: `$a$->$b$()`
- Static method call: `$a$::$b$()`
- Constructor call: `new $b$()`
- Assignment: `$a$ = $b$`
- Field access: `$a$->$b$`
- Inheritance: `class $a$ extends $b$ {}`
- Interface implementation: `class $a$ implements $b$ {}`
- Instance check: `$a$ instanceof $b$`

Useful constraints:

- `regex`: restrict a variable by text, for example method names like `^get.*`
- `invertRegex`: invert the regex condition
- `minCount` and `maxCount`: bound repeated variables
- `exprType`: constrain expression types where supported

Known caveats from the MCP tool description:

- Some PHP modifiers and complex nested patterns may not match as you first expect.
- Prefer a built-in pattern from `get_structural_patterns` when one is close.
- Validate a few hits manually before making repeated edits.

Workflow:

1. Start from a built-in pattern from `get_structural_patterns` if one is close.
2. Search a narrow area first.
3. Inspect several hits with `read_file`.
4. Apply the smallest edit that preserves behavior.
5. Re-run inspections.

## Custom Inspection Authoring

These tools are not for routine editing. Use them only when you need to author or validate a custom inspection script.

- `generate_inspection_kts_api`: reference for the inspection KTS API
- `generate_inspection_kts_examples`: starter examples
- `generate_psi_tree`: understand the PSI shape of a PHP, Java, or Kotlin snippet
- `run_inspection_kts`: compile and run a custom inspection against a target file

## Validation Ladder

Use the narrowest validation that can still catch the likely failure mode.

- Single-file fix: `get_inspections`
- Single-file semantic edit or quick fix: `get_inspections` -> `build_project` for that file
- Cross-file rename or repeated migration: `get_inspections` on touched files -> `build_project` on touched files
- Only if IDE tools are insufficient: `execute_run_configuration` or `execute_terminal_command`

## Anti-patterns

- Starting with `search_regex` when `search_symbol` would identify the declaration and references semantically
- Using `replace_text_in_file` to rename a symbol
- Treating `apply_quick_fix` as a generic substitute for all intention actions
- Running `build_project` before you have looked at `get_inspections`
- Reading a very large file whole when `read_file` can slice exactly what you need
- Depending on `invoke_ide_action` for selection-heavy extract or inline refactorings without a fallback plan
- Reformatting too early and hiding the meaningful diff

## Usually Irrelevant for This Skill

- `laravel_idea_*` tools: ignore unless the task is explicitly Laravel-specific
- `execute_terminal_command`: last resort, not a first-line MCP choice
- `execute_run_configuration`: use when a named IDE run configuration is the intended validation mechanism
- `create_new_file`: fine for creating files, but not relevant to inspections or refactoring workflows
