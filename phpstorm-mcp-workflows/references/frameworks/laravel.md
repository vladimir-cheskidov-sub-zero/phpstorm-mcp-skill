# Laravel Overlay

Load this file only when the project is clearly Laravel-based.

## When to Load This File

Use this overlay only after you have strong evidence such as:

- `composer.json` or `composer.lock` contains `laravel/framework`
- the project contains `artisan`
- the project contains `bootstrap/app.php`
- the project contains `routes/web.php` or `routes/api.php`
- the MCP session exposes `laravel_idea_*` tools and the repository layout matches Laravel

If those signals are absent, stay on the base workflow.

## Laravel Discovery Order

Prefer Laravel-aware discovery before generic text search.

1. `laravel_idea_get_routes` for route-to-controller or route-to-page mapping
2. `laravel_idea_get_eloquent_model` for fields, relations, migrations, policies, factories, resources, and related artifacts
3. `laravel_idea_get_view_meta` for Blade view lookup and passed variables
4. `laravel_idea_get_blade_component` for Blade and Livewire component mapping
5. `read_file` on the resolved source files
6. Only then use generic search or refactoring tools

## When Laravel Tools Matter Most

- route investigation
- Eloquent model changes
- Blade or Livewire component work
- view parameter tracing
- helper regeneration after macro or model metadata changes

## Laravel Guardrails

- Do not start with `search_text` for routes, Blade components, or Eloquent relationships if `laravel_idea_*` tools are available.
- After semantic refactors, still audit route names, config keys, translation keys, env names, Blade strings, and queue names with `search_text`.
- Treat framework entrypoints such as routes, events, jobs, listeners, policies, commands, and Blade components as behavior-critical. Run tests or the nearest run configuration after edits.
- Use `laravel_idea_generate_helper_code` only after meaningful Laravel metadata changes and only when helper regeneration is part of the project workflow.

## Laravel Validation Pattern

1. Framework-aware discovery through `laravel_idea_*`
2. Core edit workflow from the base skill
3. `get_inspections`
4. `build_project`
5. tests, run configurations, or the project's Laravel CLI validation path
