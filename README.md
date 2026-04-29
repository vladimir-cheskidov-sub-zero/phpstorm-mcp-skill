# Make AI Agents Better at PHP with PhpStorm MCP

Give coding agents PhpStorm's semantic navigation, inspections, structural search, and safe refactorings instead of forcing them to operate like plain text editors.

This repository packages a Codex skill named `phpstorm-mcp-workflows`. Its purpose is narrow: improve the quality of agent work on PHP projects by making PhpStorm MCP the default path for project context, diagnostics, refactoring, and validation.

## Quick Start

1. Enable PhpStorm MCP in PhpStorm under Settings | Tools | MCP Server.
2. Install or update the skill for Codex:

   ```bash
   ./codex/install-codex-phpstorm-mcp-workflows.sh
   ```

3. Verify that the installed Codex copy matches this checkout:

   ```bash
   ./codex/install-codex-phpstorm-mcp-workflows.sh --check
   ```

4. Restart Codex so the updated skill is loaded.
5. Ask the agent to use `$phpstorm-mcp-workflows` for PHP navigation, inspections, refactoring, migrations, or validation.

For non-Codex agent setups, expose the `phpstorm-mcp-workflows/` directory through the platform's skill or prompt mechanism. The OpenAI-compatible interface metadata lives in [`phpstorm-mcp-workflows/agents/openai.yaml`](phpstorm-mcp-workflows/agents/openai.yaml).

## What the Skill Changes

AI agents often make PHP mistakes because they start from text search and file reads when the IDE already has richer project knowledge. This skill changes the default order:

1. Use semantic and framework-aware PhpStorm MCP tools first.
2. Use lower-level PhpStorm MCP readers and searchers after the target is narrowed.
3. Use non-MCP shell or filesystem tooling only when the IDE path is unavailable or materially less effective.

The core defaults are:

- bootstrap real PHP project context before non-trivial edits
- prefer inspections and exact quick fixes over diagnostic guesswork
- prefer semantic rename over text replacement for identifiers
- prefer structural search over regex for syntax-shaped PHP migrations
- audit strings, templates, route names, service IDs, config keys, and docs after semantic refactors
- validate behavior changes with tests or run configurations, not `build_project` alone
- load framework or capability overlays only when the task proves the need

## Repository Contents

- [`phpstorm-mcp-workflows/SKILL.md`](phpstorm-mcp-workflows/SKILL.md): normative workflow and guardrails.
- [`phpstorm-mcp-workflows/references/playbook.md`](phpstorm-mcp-workflows/references/playbook.md): expanded tool-choice guidance and workflow recipes.
- [`phpstorm-mcp-workflows/references/toolset-2026-1.md`](phpstorm-mcp-workflows/references/toolset-2026-1.md): observational notes about public docs, tested builds, and optional exposed capabilities.
- [`phpstorm-mcp-workflows/references/frameworks/laravel.md`](phpstorm-mcp-workflows/references/frameworks/laravel.md): optional Laravel overlay.
- [`phpstorm-mcp-workflows/references/capabilities/database.md`](phpstorm-mcp-workflows/references/capabilities/database.md): optional database overlay.
- [`phpstorm-mcp-workflows/references/capabilities/debugging.md`](phpstorm-mcp-workflows/references/capabilities/debugging.md): optional Xdebug/runtime-debugging overlay.
- [`phpstorm-mcp-workflows/references/capabilities/custom-inspections.md`](phpstorm-mcp-workflows/references/capabilities/custom-inspections.md): optional repeated-migration and custom-inspection overlay.
- [`phpstorm-mcp-workflows/config/mcp.php.dist`](phpstorm-mcp-workflows/config/mcp.php.dist): template for local PhpStorm MCP endpoint settings.
- [`phpstorm-mcp-workflows/scripts/lib/SkillMcpClient.php`](phpstorm-mcp-workflows/scripts/lib/SkillMcpClient.php): dependency-free Streamable HTTP MCP client for helper scripts.
- [`phpstorm-mcp-workflows/scripts/configure-mcp.sh`](phpstorm-mcp-workflows/scripts/configure-mcp.sh): local MCP config generator.
- [`phpstorm-mcp-workflows/scripts/mcp-tool.php`](phpstorm-mcp-workflows/scripts/mcp-tool.php): one-off MCP tool caller and exposed-tool lister.
- [`phpstorm-mcp-workflows/scripts/phpstorm-project-bootstrap.php`](phpstorm-mcp-workflows/scripts/phpstorm-project-bootstrap.php): batched PHP project bootstrap for field work.
- [`phpstorm-mcp-workflows/scripts/phpstorm-batch-inspections.php`](phpstorm-mcp-workflows/scripts/phpstorm-batch-inspections.php): batched `get_inspections` runner for known file lists.
- [`codex/install-codex-phpstorm-mcp-workflows.sh`](codex/install-codex-phpstorm-mcp-workflows.sh): Codex installer, updater, and installed-copy verifier.

## Context Model

The skill is layered for context economy. The base `SKILL.md` carries the common PHP workflow. The playbook and overlays are loaded only when the task needs more detail.

Use the base skill for ordinary PHP work. Open the playbook for detailed tool selection. Open framework or capability overlays only after project context, user intent, or the exposed MCP toolset proves they are relevant.

## MCP Helper Scripts

The skill includes PHP 7.4-compatible helper scripts for stable MCP sequences that would otherwise cost multiple interactive agent/tool cycles. They use the PhpStorm Streamable HTTP MCP endpoint configured in a local `config/mcp.php` file.

Create the local config before using the helper scripts for the first time:

```bash
phpstorm-mcp-workflows/scripts/configure-mcp.sh <phpstorm-mcp-url>
```

The command copies `config/mcp.php.dist`, replaces placeholders using the provided PhpStorm MCP URL, and writes `config/mcp.php` with default MCP client settings. If `config/mcp.php` already exists, pass `--force` when you intentionally want to replace the old config:

```bash
phpstorm-mcp-workflows/scripts/configure-mcp.sh --force <phpstorm-mcp-url>
```

Use it after installing the skill, after moving to another machine, or whenever PhpStorm exposes MCP on a different endpoint. Keep machine-specific values out of `config/mcp.php.dist`; it is a placeholder template. `config/mcp.php` should be treated as machine-local state, and `.gitignore` excludes newly created copies.

Useful commands:

```bash
php phpstorm-mcp-workflows/scripts/mcp-tool.php --list-tools
php phpstorm-mcp-workflows/scripts/phpstorm-project-bootstrap.php --project-path /absolute/path/to/php-project
php phpstorm-mcp-workflows/scripts/phpstorm-batch-inspections.php --project-path /absolute/path/to/php-project --files-json /absolute/path/to/files.json
```

Use `phpstorm-mcp-workflows/scripts/mcp-tool.php --tool <name> --args-json '{...}'` for shell-driven one-off calls. If a helper exits non-zero, treat that workflow branch as blocked until the reported config, connection, or tool error is fixed.

## Install Options

Preview without writing:

```bash
./codex/install-codex-phpstorm-mcp-workflows.sh --dry-run
```

Install into a custom absolute skills directory:

```bash
./codex/install-codex-phpstorm-mcp-workflows.sh --dest /absolute/path/to/skills
```

Verify an installed copy:

```bash
./codex/install-codex-phpstorm-mcp-workflows.sh --check --dest /absolute/path/to/skills
```

The installer rejects empty, relative, and root destination paths. It also refuses to replace an existing symlink at the target skill path.

## Tested With

- PhpStorm 2026.1.1
- Build `PS-261.23567.149`

PhpStorm MCP tool exposure still varies by IDE build, enabled plugins, and allow-list settings such as `idea_mcp_allowed_tools`. The skill therefore treats the tools exposed in the current session as the source of truth.

## Limits

This skill improves agent reliability, but it does not replace tests, domain knowledge, architecture judgment, or human review for high-risk changes.

It specifically reduces common agent failure modes: unsafe renames, text-based PHP navigation mistakes, missed IDE-detectable issues, and regex-driven edits where syntax-aware search is safer.

## References

- [JetBrains PhpStorm MCP Server documentation](https://www.jetbrains.com/help/phpstorm/mcp-server.html)
- [PhpStorm 2026.1 release notes](https://blog.jetbrains.com/phpstorm/2026/03/phpstorm-2026-1-is-now-out/)
