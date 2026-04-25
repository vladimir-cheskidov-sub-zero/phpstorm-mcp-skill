# Database Capability Overlay

Load this file only when the task genuinely needs database context or SQL execution.

## When to Load This File

Use this overlay only after one of these is true:

- the user explicitly asks for schema, table, or query work
- application behavior depends on inspecting live database state
- the current MCP session exposes database tools and the chosen connection is known to be safe

If those signals are absent, stay on the base workflow.

## Discovery Order

1. `list_database_connections`
2. `test_database_connection`
3. `list_database_schemas`
4. `list_schema_object_kinds`
5. `list_schema_objects`
6. `preview_table_data` or `get_database_object_description`
7. `list_recent_sql_queries` only when recent IDE-side DB activity matters

## Default Safety Model

- Treat database access as read-only by default.
- Prefer schema and sample-data inspection before SQL execution.
- Assume production-like connections are unsafe until proven otherwise.
- Use `execute_sql_query` only when the user intent clearly allows it and the target connection is explicitly safe.
- If a task can be answered from code, migrations, or ORM metadata, do that first.

## Mutation Gate

Run mutating SQL only when all of the following are true:

1. The user clearly wants a state-changing database action.
2. The target connection is identified and safe.
3. Static validation or code inspection has already narrowed the change.
4. The query scope is bounded and reviewable.

## Validation Pattern

1. Static validation in code first
2. Read-only DB inspection second
3. Mutating SQL only if explicitly requested and safe
4. Re-run application validation if the change affects behavior or expectations
