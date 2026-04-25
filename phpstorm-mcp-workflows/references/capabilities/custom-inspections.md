# Custom Inspection Capability Overlay

Load this file only when repeated manual edits are no longer the smallest safe path.

## When to Load This File

Use this overlay when one of these is true:

- dozens of structurally similar edits are required
- the migration rule is stable enough to encode once and apply many times
- the team would benefit from turning a repeated mistake into a machine-checkable inspection

If the change is small or one-off, stay on the base workflow.

## Tooling Path

1. `search_structural` to confirm the shape and sample the matches
2. `get_structural_patterns` when a known-working PHP SSR pattern might already fit
3. `generate_inspection_kts_examples` to choose a starting template
4. `generate_inspection_kts_api` only when implementation details are needed
5. `generate_psi_tree` when the AST shape is unclear
6. `run_inspection_kts` against a representative file before scaling up

## Practical Rule

Encode the rule only after you can describe the target shape, exclusions, and expected replacement precisely. Otherwise the custom inspection will be harder to trust than the manual edit.

## Validation Pattern

1. Run the custom inspection on a narrow sample
2. Inspect hits and false positives
3. Apply the chosen fix path
4. Re-run `get_inspections`
5. `build_project`
6. Run behavior validation when public APIs or framework entrypoints are touched
