# PhpStorm MCP Skill & Workflows

> **Keywords:** PhpStorm MCP, JetBrains, Skill, IDE Automation, Semantic Search, Refactoring, Inspections, Quick Fix, Structural Search, Safe Rename, Code Navigation, Machine Control Protocol

This repository provides a **PhpStorm MCP Skill** for automating and orchestrating workflows in JetBrains PhpStorm using the Machine Control Protocol (MCP). The skill is designed for tasks involving IDE-backed code navigation, semantic search, inspections, quick fixes, safe renaming, signature changes, structural search, and refactoring.

## Description

**PhpStorm MCP Skill** enables advanced code automation by leveraging the full power of JetBrains PhpStorm's Machine Control Protocol. Use this skill to:
- Understand and navigate code symbols and relationships
- Perform semantic and structural code search
- Apply inspections and quick fixes programmatically
- Safely rename identifiers and refactor code
- Automate syntax-aware code migrations and cleanups

## Key Features
- **IDE-backed navigation:** Semantic symbol search, usage analysis, and code structure awareness
- **Automated inspections:** Run and apply IDE inspections and quick fixes
- **Safe refactoring:** Use safe rename, change signature, and structural refactoring tools
- **Structural search:** Find and transform code using AST-based patterns
- **MCP integration:** Connects directly to PhpStorm's MCP server for robust automation

## Canonical Workflows
- **Investigate a symbol:** `search_symbol` → `get_symbol_info` → `read_file`
- **Fix an inspection-driven issue:** `get_inspections` → `apply_quick_fix` → re-inspect → `build_project`
- **Safe rename:** `search_symbol` → `rename_refactoring` → inspection → build
- **Syntax-aware cleanup or migration:** `search_structural` → review → minimal safe edit → inspection and build
- **Fallback to IDE actions:** `search_ide_actions` → `invoke_ide_action` → inspection → build

## How to Connect This Skill

1. Ensure you have JetBrains PhpStorm with MCP (Machine Control Protocol) support enabled.
2. Clone or copy this repository into your project or skill directory.
3. Register the skill in your MCP-compatible orchestrator or agent platform, referencing the `phpstorm-mcp-workflows` directory.
4. Make sure the MCP server for PhpStorm is running and accessible (see [PhpStorm MCP Documentation](https://www.jetbrains.com/help/phpstorm/machine-control-protocol.html)).
5. The skill will automatically use the tools and workflows described in [SKILL.md](phpstorm-mcp-workflows/SKILL.md) and [playbook.md](phpstorm-mcp-workflows/references/playbook.md).

You can now invoke this skill for any workflow that benefits from IDE-backed code navigation, inspections, refactoring, and semantic search in PhpStorm.

## Reference Materials
- [SKILL.md](phpstorm-mcp-workflows/SKILL.md) — detailed workflows and tool selection rules
- [playbook.md](phpstorm-mcp-workflows/references/playbook.md) — tool selection guide, structural search recipes, and anti-patterns
- [openai.yaml](phpstorm-mcp-workflows/agents/openai.yaml) — skill interface and dependencies

## Useful Links
- [PhpStorm MCP Documentation](https://www.jetbrains.com/help/phpstorm/machine-control-protocol.html)

---

> For detailed scenarios and solutions, see [playbook.md](phpstorm-mcp-workflows/references/playbook.md).
