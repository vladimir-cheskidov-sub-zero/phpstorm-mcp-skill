#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"

REPO_ROOT = File.expand_path("..", __dir__)
SKILL_PATH = File.join(REPO_ROOT, "phpstorm-mcp-workflows", "SKILL.md")
CONFIG_PATH = File.join(REPO_ROOT, "scripts", "agent-interface-consistency.yaml")
AGENTS_GLOB = File.join(REPO_ROOT, "phpstorm-mcp-workflows", "agents", "*.{yaml,yml}")

def fail_with(errors)
  $stderr.puts "Agent interface prompt consistency check failed:"
  errors.each do |error|
    $stderr.puts "- #{error}"
  end
  exit 1
end

def normalize(text)
  text.to_s.gsub(/\s+/, " ").strip.downcase
end

def describe_psych_error(error)
  return error.problem if error.respond_to?(:problem) && error.problem

  error.message
end

def load_yaml_mapping(path, errors)
  yaml = YAML.safe_load(File.read(path), permitted_classes: [], aliases: false)

  unless yaml.is_a?(Hash)
    errors << "#{path} must contain a top-level mapping."
    return nil
  end

  yaml
rescue Psych::Exception => error
  errors << "#{path} contains invalid YAML: #{describe_psych_error(error)}."
  nil
end

def load_invariants(errors)
  config = load_yaml_mapping(CONFIG_PATH, errors)
  return [[], []] if config.nil?

  order = config["order"]
  unless order.is_a?(Array) && order.all? { |id| id.is_a?(String) && !id.empty? }
    errors << "#{CONFIG_PATH} must contain an order array of invariant ids."
    return [[], []]
  end

  invariant_map = config["invariants"]
  unless invariant_map.is_a?(Hash)
    errors << "#{CONFIG_PATH} must contain an invariants mapping."
    return [[], []]
  end

  invariants = invariant_map.map do |id, raw|
    raw = invariant_map[id]
    unless raw.is_a?(Hash)
      errors << "#{CONFIG_PATH} is missing invariants.#{id}."
      next
    end

    skill_locator = raw["skill_locator"]
    skill_required = raw["skill_required"]
    prompt_required = raw["prompt_required"]

    unless skill_locator.is_a?(String) && !skill_locator.empty?
      errors << "#{CONFIG_PATH} invariant #{id} must define skill_locator."
      next
    end

    unless skill_required.is_a?(Array) && skill_required.all? { |part| part.is_a?(String) && !part.empty? }
      errors << "#{CONFIG_PATH} invariant #{id} must define a non-empty skill_required array."
      next
    end

    unless prompt_required.is_a?(Array) && prompt_required.all? { |part| part.is_a?(String) && !part.empty? }
      errors << "#{CONFIG_PATH} invariant #{id} must define a non-empty prompt_required array."
      next
    end

    {
      id: id,
      skill_locator: skill_locator,
      skill_required: skill_required,
      prompt_required: prompt_required
    }
  end

  invariant_ids = invariants.compact.map { |invariant| invariant[:id] }
  missing_order_ids = order - invariant_ids
  errors << "#{CONFIG_PATH} order references unknown invariant ids: #{missing_order_ids.join(', ')}." unless missing_order_ids.empty?

  [invariants.compact, order]
end

def locate_ordered_parts(text, parts, start_at = 0)
  normalized_text = normalize(text)
  cursor = start_at
  positions = []

  parts.each do |part|
    normalized_part = normalize(part)
    position = normalized_text.index(normalized_part, cursor)
    return [nil, part] if position.nil?

    positions << position
    cursor = position + normalized_part.length
  end

  [positions, nil]
end

def collect_skill_positions(skill_text, invariants, errors)
  positions = {}
  normalized_skill = normalize(skill_text)

  invariants.each do |invariant|
    locator = normalize(invariant[:skill_locator])
    locator_position = normalized_skill.index(locator)

    if locator_position.nil?
      errors << "Base skill is missing the #{invariant[:id]} locator #{invariant[:skill_locator].inspect}; update #{CONFIG_PATH} or #{SKILL_PATH}."
      next
    end

    part_positions, missing_part = locate_ordered_parts(skill_text, invariant[:skill_required], locator_position)
    if part_positions.nil?
      errors << "Base skill is missing #{missing_part.inspect} for #{invariant[:id]} after #{invariant[:skill_locator].inspect}."
      next
    end

    positions[invariant[:id]] = locator_position
  end

  positions
end

def collect_prompt_positions(prompt_text, invariants, label, errors)
  positions = {}

  invariants.each do |invariant|
    part_positions, missing_part = locate_ordered_parts(prompt_text, invariant[:prompt_required])
    if part_positions.nil?
      errors << "#{label} is missing #{missing_part.inspect} for #{invariant[:id]}."
      next
    end

    positions[invariant[:id]] = part_positions.first
  end

  positions
end

def assert_monotonic_order(label, positions, ordered_ids, errors)
  ordered_ids.each_cons(2) do |left, right|
    next if positions[left] < positions[right]

    errors << "#{label} violates workflow order: #{left} must appear before #{right}."
  end
end

errors = []
invariants, ordered_ids = load_invariants(errors)
skill_text = File.read(SKILL_PATH)

skill_positions = collect_skill_positions(skill_text, invariants, errors)
assert_monotonic_order(SKILL_PATH, skill_positions, ordered_ids, errors) if ordered_ids.all? { |id| skill_positions.key?(id) }

agent_files = Dir.glob(AGENTS_GLOB).sort
errors << "No agent interface YAML files matched #{AGENTS_GLOB}." if agent_files.empty?

agent_files.each do |agent_file|
  yaml = load_yaml_mapping(agent_file, errors)
  next if yaml.nil?

  interface = yaml["interface"]
  unless interface.is_a?(Hash)
    errors << "#{agent_file} must contain an interface mapping."
    next
  end

  prompt = interface["default_prompt"]
  unless prompt.is_a?(String) && !prompt.empty?
    errors << "#{agent_file} is missing interface.default_prompt."
    next
  end

  label = "#{agent_file} interface.default_prompt"
  positions = collect_prompt_positions(prompt, invariants, label, errors)
  next unless errors.empty? || errors.none? { |error| error.start_with?(label) || error.start_with?(agent_file) }

  assert_monotonic_order(label, positions, ordered_ids, errors) if ordered_ids.all? { |id| positions.key?(id) }
end

fail_with(errors) unless errors.empty?

puts "Agent interface prompts are consistent with base skill defaults."
