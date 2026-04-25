# PhpStorm MCP Toolset Notes for 2026.1

This repository was reviewed against PhpStorm 2026.1.1, build `PS-261.23567.149`.

## What Was Compared

Three sources were used:

1. The public help page for the integrated MCP server: `mcp-server.html`
2. The PhpStorm 2026.1 release notes
3. The toolset exposed by the tested PhpStorm MCP environment

## Main Finding

The public help page is now a much better baseline than it was in early 2026, but it still does not read like a complete PHP-oriented tool inventory for recent PhpStorm 2026.1.x sessions.

The help page covers the integrated server setup and a meaningful supported-tools list, but current PhpStorm MCP environments can expose additional PHP-specific capabilities for:

- inspections and quick fixes
- PHP project bootstrap and environment discovery
- structural search for PHP
- IDE action discovery and invocation
- optional Xdebug-assisted debugging
- optional framework-aware workflows such as Laravel Idea integration

In practice, this means a current skill should use the public docs as the baseline and the actually exposed toolset as the source of truth.

## Publicly Documented on `mcp-server.html`

The current help page documents the integrated MCP server, client setup, and a supported-tools list that includes core file, project, search, refactoring, execution, and database tools.

That public page is sufficient to explain how the built-in server works and to justify the general MCP workflow, but it still does not enumerate every PHP-specific tool family that can appear in a recent PhpStorm session.

## Confirmed in Recent 2026.1 Sessions

### General MCP tools

Recent PhpStorm MCP sessions expose a broad general toolset including tools such as:

- `create_new_file`, `find_files_by_glob`, `find_files_by_name_keyword`, `get_all_open_file_paths`, `get_file_problems`, `get_project_dependencies`, `get_project_modules`, `get_repositories`, `get_run_configurations`, `list_directory_tree`, `open_file_in_editor`, `read_file`, `reformat_file`, `build_project`
- `search_symbol`, `search_file`, `search_text`, `search_regex`, `search_in_files_by_text`, `search_in_files_by_regex`
- `get_symbol_info`, `rename_refactoring`, `replace_text_in_file`
- `execute_run_configuration`, `execute_terminal_command`

### PHP-specific tools

Recent PhpStorm MCP sessions can also expose PHP-specific capabilities such as:

- `get_inspections`
- `apply_quick_fix`
- `get_php_project_config`
- `get_composer_dependencies`
- `get_structural_patterns`
- `search_structural`
- `search_ide_actions`
- `invoke_ide_action`

### Optional debugger tools

When the environment exposes Xdebug support, recent sessions can include tools such as:

- `xdebug_start_debugger_session`
- `xdebug_start_server`
- `xdebug_status`
- `xdebug_request`
- `xdebug_single_file`
- `xdebug_stack`
- `xdebug_context`
- `xdebug_eval`
- `xdebug_property_get`
- `xdebug_property_set`
- `xdebug_set_breakpoint`
- `xdebug_breakpoint_list`
- `xdebug_breakpoint_remove`
- `xdebug_run`
- `xdebug_pause`
- `xdebug_step_into`
- `xdebug_step_over`
- `xdebug_step_out`
- `xdebug_stop`
- `xdebug_detach`
- `xdebug_stop_server`

Some environments also expose generic aliases such as `breakpoint_*`, `context_get`, `property_get`, `property_set`, `stack_get`, and `step_*`.

### Optional database tools

When database tooling is enabled, recent sessions can include tools such as:

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

### Optional Laravel-aware tools

PhpStorm 2026.1 release notes note built-in PHP Claude Skills and Laravel Idea MCP support. In integrations that expose Laravel-specific MCP capabilities, the session may also contain tools such as:

- `laravel_idea_get_routes`
- `laravel_idea_get_eloquent_model`
- `laravel_idea_get_view_meta`
- `laravel_idea_get_blade_component`
- `laravel_idea_generate_helper_code`

## Why This Repository Still Matters

PhpStorm 2026.1 already ships stronger built-in MCP and agent guidance than earlier releases, including built-in PHP Claude Skills.

This repository remains useful because it is:

- vendor-neutral rather than tied to a single agent product
- explicit about safer PHP defaults such as inspections, semantic navigation, and refactoring-first edits
- layered for context economy, so framework and capability overlays are loaded only when needed
- packaged for Codex installation and maintenance

## Practical Guidance

- Trust actual exposed tools first.
- Use the public docs as a baseline, not as the last word.
- If a tool you expect is missing, check IDE version, enabled plugins, and allow-list settings such as `idea_mcp_allowed_tools`.
