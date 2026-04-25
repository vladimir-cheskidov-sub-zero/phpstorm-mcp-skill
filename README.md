# Make AI Agents Better at PHP with PhpStorm MCP

> Give your coding agent PhpStorm's semantic navigation, inspections, structural search, and safe refactorings instead of forcing it to work like a text editor.

This repository is for people who want **higher-quality AI agent work on PHP projects**.

The idea is simple: most agents are better at generating code than at understanding a real PHP codebase safely. PhpStorm already knows how to navigate symbols, run inspections, apply quick fixes, perform safe renames, and reason about code structure. Through MCP, an agent can use that same capability instead of guessing from raw text.

## Why This Exists

AI agents often fail on PHP repositories in predictable ways:

- they search text when they need symbol-aware navigation
- they rename identifiers with string replacement
- they guess at diagnostics instead of reading IDE inspections
- they use regex for syntax-shaped migrations
- they stop at editing instead of validating against real project context

This skill pushes the agent toward safer defaults: semantic discovery, inspection-driven fixing, syntax-aware search, disciplined validation, and framework or capability overlays only when they are actually relevant.

## What This Repository Contains

- [`phpstorm-mcp-workflows/SKILL.md`](phpstorm-mcp-workflows/SKILL.md)
  The core operating rules for using PhpStorm MCP on PHP work.

- [`phpstorm-mcp-workflows/references/playbook.md`](phpstorm-mcp-workflows/references/playbook.md)
  A practical decision guide for choosing the smallest safe MCP tool for a task.

- [`phpstorm-mcp-workflows/references/toolset-2026-1.md`](phpstorm-mcp-workflows/references/toolset-2026-1.md)
  Notes on the current PhpStorm 2026.1 toolset, the public docs baseline, and where real sessions expose more than the docs list explicitly.

- [`phpstorm-mcp-workflows/references/frameworks/laravel.md`](phpstorm-mcp-workflows/references/frameworks/laravel.md)
  An optional Laravel overlay that should be loaded only when the project is clearly Laravel-based.

- [`phpstorm-mcp-workflows/references/capabilities/database.md`](phpstorm-mcp-workflows/references/capabilities/database.md)
  A database overlay for safe schema inspection and cautious SQL execution.

- [`phpstorm-mcp-workflows/references/capabilities/debugging.md`](phpstorm-mcp-workflows/references/capabilities/debugging.md)
  A runtime-debugging overlay for Xdebug-assisted investigation when static tools are not enough.

- [`phpstorm-mcp-workflows/references/capabilities/custom-inspections.md`](phpstorm-mcp-workflows/references/capabilities/custom-inspections.md)
  A migration overlay for repeated structural edits and custom `inspection.kts` workflows.

- [`phpstorm-mcp-workflows/agents/openai.yaml`](phpstorm-mcp-workflows/agents/openai.yaml)
  A ready-to-register interface for OpenAI-compatible agent setups.

- [`codex/install-codex-phpstorm-mcp-workflows.sh`](codex/install-codex-phpstorm-mcp-workflows.sh)
  A Codex-specific installer and updater for copying this skill into the local Codex skills directory.

## Context Budget

The skill is intentionally layered. The base skill stays loaded for common PHP work, while framework and capability overlays are opened only when the task actually needs them.

The numbers below are current repository estimates, measured from the checked-in files and rounded to the nearest token. Real token counts vary by model tokenizer, but the ratios are stable enough for planning.

| Situation | Files Typically Loaded | Estimated Tokens |
| --- | --- | ---: |
| Core PHP task | `SKILL.md` | ~1.3k |
| Core PHP task with detailed tool selection | `SKILL.md` + `references/playbook.md` | ~3.9k |
| Laravel task | `SKILL.md` + `references/frameworks/laravel.md` | ~1.8k |
| Database-assisted task | `SKILL.md` + `references/capabilities/database.md` | ~1.7k |
| Runtime-only debugging task | `SKILL.md` + `references/capabilities/debugging.md` | ~1.7k |
| Large migration campaign | `SKILL.md` + `references/playbook.md` + `references/capabilities/custom-inspections.md` | ~4.3k |
| Full maintenance audit | `SKILL.md` + `references/playbook.md` + `references/toolset-2026-1.md` + one relevant overlay | ~5.5k to 5.7k |

This layering is deliberate:

- effectiveness first: the base skill still contains the common high-value workflows and guardrails
- maintainability second: rarer capability branches live in separate files with clear activation rules
- token weight third: the agent does not pay for database, Xdebug, or custom inspection details unless the task actually needs them

## What the Skill Changes

Instead of treating the repository as plain text, the agent can:

- bootstrap real PHP project context with interpreter, language level, Composer packages, modules, repositories, and run configurations
- navigate code semantically with symbol search and code insight
- read PhpStorm inspections and apply exact quick fixes
- use structural search for repetitive migrations and cleanup
- use safe refactoring paths instead of brittle replacement-based edits
- validate behavior with run configurations and project-aware checks

Typical workflows include:

- `search_symbol -> get_symbol_info -> read_file`
- `get_inspections -> apply_quick_fix -> get_inspections -> build_project`
- `search_symbol -> rename_refactoring -> get_inspections -> build_project`
- `search_structural -> inspect hits -> minimal safe edit -> get_inspections -> build_project`

## Why This Still Matters in 2026.1

PhpStorm 2026.1 already ships stronger built-in MCP support and built-in PHP Claude Skills.

This repository is still useful when you want:

- agent guidance that is not tied to a single client product
- explicit PHP-first operating rules instead of generic IDE usage
- a Codex-friendly install and update path
- layered references that trade context only when the task requires it

## Framework and Capability Overlays

The base skill is intentionally framework-agnostic and capability-light.

Framework-specific and rare-task instructions live in separate files and should be loaded only after the framework or task type is identified from Composer dependencies, project layout, user intent, or exposed MCP tools. That keeps the default workflow lean without removing advanced paths.

The repository currently includes:

- a Laravel framework overlay
- a database overlay
- a runtime-debugging overlay
- a custom-inspections overlay

## Out of the Box

On the tested PhpStorm setup, the repository works without installing extra third-party plugins just to get the core PHP MCP workflow.

Actual tool exposure can still vary by PhpStorm build, enabled bundled plugins, and allowed-tools configuration. In practice:

- the core PHP MCP workflow is the stable baseline
- database tooling may depend on whether database features are enabled and exposed in the session
- Laravel-aware tools appear only when the corresponding capabilities are available in the environment
- Xdebug workflows should be treated as optional even when the repository documents them

## Limits

This approach improves agent reliability, but it does not replace:

- tests
- domain knowledge
- architectural judgment
- human review for high-risk changes

What it does do is reduce a specific class of common agent mistakes: unsafe renames, text-based navigation errors, missed IDE-detectable issues, and regex-driven edits where syntax-aware search would be safer.

## Tested With

- **PhpStorm 2026.1.1**
- build **PS-261.23567.149**

The skill was updated against the current PhpStorm 2026.1 documentation, release notes, and the toolset exposed by the tested build.

## Added for Build PS-261.23567.149

The current skill shape is not just a generic 2026.1 rewrite. Several parts were added or tightened specifically because the tested `PS-261.23567.149` environment exposed more MCP capability than the public docs alone would suggest.

Added or expanded for this build:

- PHP project bootstrap as a first-class default through `get_php_project_config` and `get_composer_dependencies`
- inspection-driven fixing through `get_inspections` and exact `apply_quick_fix` selection
- structural-search-first migration guidance through `search_structural` and `get_structural_patterns`
- IDE-action fallback guidance for refactorings that do not have a dedicated MCP tool, via `search_ide_actions` and `invoke_ide_action`
- Laravel-aware discovery as an optional overlay for environments where `laravel_idea_*` tools are exposed
- database and Xdebug workflows as optional capability overlays instead of unconditional base-skill content
- a stricter rule that the actually exposed toolset in the current session is the source of truth, while `mcp-server.html` is treated as the public baseline

This is why the repository now uses a layered layout: the common high-value PHP workflow stays in the base skill, while build-dependent or task-dependent capability families are documented in overlays and loaded only when the tested environment actually exposes them.

## Quick Start

1. Enable and configure **PhpStorm MCP** in your JetBrains environment.
2. Add this repository to the skill set available to your agent platform.
3. Register or expose the `phpstorm-mcp-workflows` skill.
4. Prompt the agent to use the skill for PHP navigation, inspections, refactoring, migrations, or validation.
5. Keep the base skill loaded by default; open the playbook or a framework/capability overlay only when the task actually needs that detail.

For OpenAI-compatible agent setups, see [`phpstorm-mcp-workflows/agents/openai.yaml`](phpstorm-mcp-workflows/agents/openai.yaml).

## Install or Update in Codex

The included installer is specifically for Codex. It installs the skill into `$CODEX_HOME/skills` (or `~/.codex/skills` when `CODEX_HOME` is unset) and updates an existing Codex installation in place:

```bash
./codex/install-codex-phpstorm-mcp-workflows.sh
```

Useful options:

- Preview the changes without writing anything:

  ```bash
  ./codex/install-codex-phpstorm-mcp-workflows.sh --dry-run
  ```

- Install into a custom skills directory:

  ```bash
  ./codex/install-codex-phpstorm-mcp-workflows.sh --dest /path/to/skills
  ```

The script always installs the `phpstorm-mcp-workflows` directory from this repository. If the skill already exists in the target Codex skills directory, it is replaced with the version from the current checkout.

## Repository Structure

```text
phpstorm-mcp-skill/
├── README.md
├── codex/
│   └── install-codex-phpstorm-mcp-workflows.sh
└── phpstorm-mcp-workflows/
    ├── SKILL.md
    ├── agents/
    │   └── openai.yaml
    └── references/
        ├── capabilities/
        │   ├── custom-inspections.md
        │   ├── database.md
        │   └── debugging.md
        ├── frameworks/
        │   └── laravel.md
        ├── playbook.md
        └── toolset-2026-1.md
```

## Reference

- [MCP Server documentation](https://www.jetbrains.com/help/phpstorm/mcp-server.html)
- [PhpStorm 2026.1 release notes](https://blog.jetbrains.com/phpstorm/2026/03/phpstorm-2026-1-is-now-out/)

If you want AI agents to do better work on PHP projects, improving prompts is not enough. Give the agent access to trusted code intelligence, inspections, and refactoring primitives.
