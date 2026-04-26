#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "find"
require "open3"
require "tmpdir"
require "yaml"

REPO_ROOT = File.expand_path("..", __dir__)
SKILL_NAME = "phpstorm-mcp-workflows"
SOURCE_SKILL_DIR = File.join(REPO_ROOT, SKILL_NAME)
INSTALLER = File.join(REPO_ROOT, "codex", "install-codex-phpstorm-mcp-workflows.sh")
CHECKER = File.join(REPO_ROOT, "scripts", "check-agent-interface-consistency.rb")

class ValidationFailure < StandardError; end

def relative(path)
  path.delete_prefix("#{REPO_ROOT}/")
end

def run_command(*cmd, cwd: REPO_ROOT, env: {}, expect_success: true)
  stdout, stderr, status = Open3.capture3(env, *cmd, chdir: cwd)

  if expect_success && !status.success?
    raise ValidationFailure, "Command failed: #{cmd.join(' ')}\nSTDOUT:\n#{stdout}\nSTDERR:\n#{stderr}"
  end

  if !expect_success && status.success?
    raise ValidationFailure, "Command unexpectedly succeeded: #{cmd.join(' ')}\nSTDOUT:\n#{stdout}\nSTDERR:\n#{stderr}"
  end

  [stdout, stderr, status]
end

def validate_syntax
  run_command("ruby", "-c", relative(CHECKER))
  run_command("ruby", "-c", "scripts/validate-repository.rb")
  run_command("bash", "-n", relative(INSTALLER))
end

def validate_yaml
  yaml_files = Dir.glob(File.join(REPO_ROOT, "{.github,phpstorm-mcp-workflows,scripts}", "**", "*.{yaml,yml}"), File::FNM_EXTGLOB)

  yaml_files.each do |path|
    yaml = YAML.safe_load(File.read(path), permitted_classes: [], aliases: false)
    next if yaml.is_a?(Hash) || yaml.is_a?(Array) || yaml.nil?

    raise ValidationFailure, "#{relative(path)} must contain YAML mapping, sequence, or null."
  rescue Psych::Exception => error
    raise ValidationFailure, "#{relative(path)} contains invalid YAML: #{error.message}"
  end
end

def validate_markdown_links
  markdown_files = Dir.glob(File.join(REPO_ROOT, "**", "*.md"))

  markdown_files.each do |path|
    text = File.read(path)
    text.scan(/\[[^\]]+\]\(([^)]+)\)/).flatten.each do |href|
      next if href.match?(%r{\A(?:https?|mailto):})
      next if href.start_with?("#")

      target = href.split("#", 2).first
      next if target.empty?

      full_target = File.expand_path(target, File.dirname(path))
      next if File.exist?(full_target)

      raise ValidationFailure, "#{relative(path)} links to missing local target: #{href}"
    end
  end
end

def validate_required_skill_files
  required = [
    "SKILL.md",
    "agents/openai.yaml",
    "references/playbook.md",
    "references/toolset-2026-1.md",
    "references/frameworks/laravel.md",
    "references/capabilities/database.md",
    "references/capabilities/debugging.md",
    "references/capabilities/custom-inspections.md"
  ]

  required.each do |path|
    full_path = File.join(SOURCE_SKILL_DIR, path)
    raise ValidationFailure, "Missing required skill file: #{SKILL_NAME}/#{path}" unless File.file?(full_path)
  end
end

def tree_entries(root)
  entries = []

  Find.find(root) do |path|
    next if path == root

    rel = path.delete_prefix("#{root}/")
    stat = File.lstat(path)
    type = if stat.symlink?
      "symlink"
    elsif stat.directory?
      "dir"
    elsif stat.file?
      "file"
    else
      "other"
    end

    entries << [rel, type]
  end

  entries.sort
end

def compare_trees(expected, actual)
  expected_entries = tree_entries(expected)
  actual_entries = tree_entries(actual)

  unless expected_entries == actual_entries
    raise ValidationFailure, "Installed skill tree differs from source tree."
  end

  expected_entries.each do |rel, type|
    next unless type == "file"

    expected_file = File.join(expected, rel)
    actual_file = File.join(actual, rel)
    next if FileUtils.compare_file(expected_file, actual_file)

    raise ValidationFailure, "Installed file differs from source: #{rel}"
  end
end

def copy_checker_fixture(destination)
  FileUtils.mkdir_p(File.join(destination, "scripts"))
  FileUtils.cp(CHECKER, File.join(destination, "scripts", "check-agent-interface-consistency.rb"))
  FileUtils.cp(File.join(REPO_ROOT, "scripts", "agent-interface-consistency.yaml"), File.join(destination, "scripts", "agent-interface-consistency.yaml"))
  FileUtils.cp_r(SOURCE_SKILL_DIR, File.join(destination, SKILL_NAME))
end

def mutate_prompt(fixture_dir)
  agent_path = File.join(fixture_dir, SKILL_NAME, "agents", "openai.yaml")
  yaml = YAML.safe_load(File.read(agent_path), permitted_classes: [], aliases: false)
  yield yaml.fetch("interface").fetch("default_prompt")
  File.write(agent_path, YAML.dump(yaml))
end

def validate_negative_checker_cases
  Dir.mktmpdir("phpstorm-mcp-skill-checker-") do |dir|
    copy_checker_fixture(dir)
    mutate_prompt(dir) do |prompt|
      prompt.sub!("semantic rename over text replacement", "safe identifier updates")
    end
    run_command("ruby", "scripts/check-agent-interface-consistency.rb", cwd: dir, expect_success: false)
  end

  Dir.mktmpdir("phpstorm-mcp-skill-checker-") do |dir|
    copy_checker_fixture(dir)
    mutate_prompt(dir) do |prompt|
      prompt.prepend("Use non-MCP tooling only when absolutely necessary. ")
    end
    run_command("ruby", "scripts/check-agent-interface-consistency.rb", cwd: dir, expect_success: false)
  end
end

def validate_installer
  run_command("bash", relative(INSTALLER), "--dry-run", "--dest", "", expect_success: false)
  run_command("bash", relative(INSTALLER), "--dry-run", "--dest", "/", expect_success: false)
  run_command("bash", relative(INSTALLER), "--dry-run", "--dest", "/tmp/..", expect_success: false)
  run_command("bash", relative(INSTALLER), "--dry-run", "--dest", "relative-skills", expect_success: false)

  Dir.mktmpdir("phpstorm-mcp-skill-install-") do |dir|
    dest_root = File.join(dir, "skills")
    installed_skill = File.join(dest_root, SKILL_NAME)

    run_command("bash", relative(INSTALLER), "--dry-run", "--dest", dest_root)
    raise ValidationFailure, "Dry run created destination root." if File.exist?(dest_root)

    run_command("bash", relative(INSTALLER), "--dest", dest_root)
    compare_trees(SOURCE_SKILL_DIR, installed_skill)

    run_command("bash", relative(INSTALLER), "--dest", dest_root)
    compare_trees(SOURCE_SKILL_DIR, installed_skill)

    run_command("bash", relative(INSTALLER), "--check", "--dest", dest_root)
  end

  Dir.mktmpdir("phpstorm-mcp-skill-symlink-") do |dir|
    dest_root = File.join(dir, "skills")
    FileUtils.mkdir_p(dest_root)
    File.symlink(SOURCE_SKILL_DIR, File.join(dest_root, SKILL_NAME))

    run_command("bash", relative(INSTALLER), "--dest", dest_root, expect_success: false)
  end

  Dir.mktmpdir("phpstorm-mcp-skill-rollback-") do |dir|
    dest_root = File.join(dir, "skills")
    installed_skill = File.join(dest_root, SKILL_NAME)
    marker = "rollback-marker-#{Time.now.to_i}"

    run_command("bash", relative(INSTALLER), "--dest", dest_root)
    File.write(File.join(installed_skill, "ROLLBACK_MARKER"), marker)

    run_command("bash", relative(INSTALLER), "--dest", dest_root, env: { "CODEX_PHPSTORM_MCP_INSTALL_FAIL_AFTER_BACKUP" => "1" }, expect_success: false)

    restored_marker = File.read(File.join(installed_skill, "ROLLBACK_MARKER"))
    raise ValidationFailure, "Installer rollback did not restore previous installation." unless restored_marker == marker
  end
end

begin
  checks = [
    ["syntax", method(:validate_syntax)],
    ["yaml", method(:validate_yaml)],
    ["markdown links", method(:validate_markdown_links)],
    ["required skill files", method(:validate_required_skill_files)],
    ["agent interface consistency", -> { run_command("ruby", relative(CHECKER)) }],
    ["negative checker cases", method(:validate_negative_checker_cases)],
    ["installer", method(:validate_installer)]
  ]

  checks.each do |label, check|
    check.call
    puts "ok #{label}"
  end

  puts "Repository validation passed."
rescue ValidationFailure => error
  warn "Repository validation failed: #{error.message}"
  exit 1
end
