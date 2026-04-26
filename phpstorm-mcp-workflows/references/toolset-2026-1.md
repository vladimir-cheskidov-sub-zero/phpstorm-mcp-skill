# PhpStorm MCP Toolset Notes for 2026.1

This reference is observational. It helps an agent reason about PhpStorm MCP capability drift, but it is not the normative workflow. The normative workflow lives in `../SKILL.md`.

## Review Metadata

- Tested IDE: PhpStorm 2026.1.1
- Tested build: `PS-261.23567.149`
- Session capture date: 2026-04-27
- Public baseline: JetBrains PhpStorm MCP Server documentation and PhpStorm 2026.1 release notes
- Rule for agents: prefer the tools actually exposed in the current MCP session over this file

## Evidence Levels

Use these categories when reading tool claims:

1. **Public baseline**: described by JetBrains public documentation or release notes.
2. **Observed in tested session**: exposed by the tested PhpStorm MCP environment used for this repository.
3. **Optional capability**: may appear only with specific plugins, IDE builds, project types, configured interpreters, debug support, database support, or MCP allow-list settings.

Do not treat optional tools as guaranteed. If a tool is missing, use the fallback guidance in `playbook.md` and the base skill.

## Public Baseline

JetBrains' public PhpStorm MCP Server documentation covers integrated server setup, client configuration, and supported IDE/MCP capabilities across file, project, search, refactoring, execution, and database-oriented workflows.

PhpStorm 2026.1 release notes also describe stronger AI-agent support, including PHP-focused agent guidance, inspections and quick fixes, structural search, IDE actions, and Laravel Idea MCP integration.

These public sources justify the repository's general MCP-first workflow, but they should not be read as a complete inventory for every possible PhpStorm MCP session.

## Observed in the Tested Session

The tested session exposed general project and file tools such as:

- `create_new_file`, `find_files_by_glob`, `find_files_by_name_keyword`, `get_all_open_file_paths`, `get_file_problems`, `get_project_dependencies`, `get_project_modules`, `get_repositories`, `get_run_configurations`, `list_directory_tree`, `open_file_in_editor`, `read_file`, `reformat_file`, `build_project`
- `search_symbol`, `search_file`, `search_text`, `search_regex`, `search_in_files_by_text`, `search_in_files_by_regex`
- `get_symbol_info`, `rename_refactoring`, `replace_text_in_file`
- `execute_run_configuration`, `execute_terminal_command`

The same tested session exposed PHP-oriented tools such as:

- `get_php_project_config`
- `get_composer_dependencies`
- `get_inspections`
- `apply_quick_fix`
- `get_structural_patterns`
- `search_structural`
- `search_ide_actions`
- `invoke_ide_action`

The same tested session exposed Xdebug-oriented tools such as:

- `xdebug_start_server`, `xdebug_status`, `xdebug_request`, `xdebug_single_file`, `xdebug_stack`, `xdebug_context`, `xdebug_eval`, `xdebug_property_get`, `xdebug_property_set`, `xdebug_set_breakpoint`, `xdebug_breakpoint_list`, `xdebug_breakpoint_remove`, `xdebug_run`, `xdebug_pause`, `xdebug_step_into`, `xdebug_step_over`, `xdebug_step_out`, `xdebug_stop`, `xdebug_detach`, `xdebug_stop_server`

## Optional Capabilities

Database tools may appear when database support is enabled and exposed in the MCP session. Examples include:

- `list_database_connections`
- `test_database_connection`
- `list_database_schemas`
- `list_schema_object_kinds`
- `list_schema_objects`
- `get_database_object_description`
- `preview_table_data`
- `list_recent_sql_queries`
- `execute_sql_query`
- `cancel_sql_query`

Laravel-aware tools may appear in environments where Laravel Idea MCP capabilities are available and exposed. Examples include:

- `laravel_idea_get_routes`
- `laravel_idea_get_eloquent_model`
- `laravel_idea_get_view_meta`
- `laravel_idea_get_blade_component`
- `laravel_idea_generate_helper_code`

Treat database, debugger, and framework-aware tool families as capability overlays. Load the matching overlay only after the project or task proves the need.

## Practical Guidance

- Trust the current session's exposed tools first.
- Use public documentation as a baseline, not as a complete inventory.
- If a tool you expect is missing, check IDE version, enabled bundled plugins, project setup, and allow-list settings such as `idea_mcp_allowed_tools`.
- If a documented or observed tool is unavailable, choose the next smallest safe workflow from `playbook.md` and state the fallback.
