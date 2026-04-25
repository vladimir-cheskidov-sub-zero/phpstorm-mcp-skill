# Runtime Debugging Capability Overlay

Load this file only for runtime-only bugs that inspections, semantic search, and tests cannot explain.

## When to Load This File

Use this overlay only after one of these is true:

- the issue depends on runtime state, request flow, or environment-dependent values
- static inspection and ordinary validation did not explain the defect
- the current MCP session exposes Xdebug tools and the reproduction path is narrow enough to control

If a cheaper static path still exists, stay on the base workflow.

## Preferred Debugging Order

1. Exhaust inspections, semantic navigation, and run configurations first.
2. Reproduce the smallest possible request or single-file case.
3. If exposed, use `xdebug_request` or `xdebug_single_file` to start from the narrowest reproduction path.
4. Inspect `xdebug_status`, `xdebug_stack`, and `xdebug_context`.
5. Use `xdebug_property_get` or `xdebug_eval` for specific runtime questions.
6. Step only as far as needed: `xdebug_step_into`, `xdebug_step_over`, `xdebug_step_out`, `xdebug_run`.
7. Apply the actual fix through normal editing, inspections, and validation workflows.

## Breakpoint Rules

- Set the fewest breakpoints that can answer the question.
- Prefer line breakpoints close to the suspected divergence point.
- Remove or ignore stale breakpoints before a fresh reproduction.

## Guardrails

- Do not use debugger state changes as the fix.
- Do not start with Xdebug when `get_inspections`, `search_symbol`, or tests can answer the question more cheaply.
- Do not debug a broad request path when a narrower route or single script is available.
- Return to the normal validation ladder after the runtime cause is understood.
