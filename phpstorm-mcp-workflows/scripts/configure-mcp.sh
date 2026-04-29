#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
skill_dir="$(cd -- "${script_dir}/.." && pwd)"
template="${skill_dir}/config/mcp.php.dist"
target="${skill_dir}/config/mcp.php"
force=0
mcp_url=""

usage() {
  cat <<'EOF_USAGE'
Usage: phpstorm-mcp-workflows/scripts/configure-mcp.sh [--force] <mcp-url>

Creates phpstorm-mcp-workflows/config/mcp.php from
phpstorm-mcp-workflows/config/mcp.php.dist by replacing template placeholders.

Options:
  --force  Overwrite an existing config.
  --help   Show this help message.
EOF_USAGE
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

php_string_escape() {
  local value="$1"
  local single_quote="'"
  local escaped_single_quote="\\'"

  value="${value//\\/\\\\}"
  value="${value//${single_quote}/${escaped_single_quote}}"
  printf '%s' "${value}"
}

replace_placeholder() {
  local placeholder="$1"
  local replacement="$2"

  content="${content//${placeholder}/${replacement}}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      force=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --*)
      fail "Unknown option: $1"
      ;;
    *)
      [[ -z "${mcp_url}" ]] || fail "Only one MCP URL may be provided."
      mcp_url="$1"
      shift
      ;;
  esac
done

[[ -f "${template}" ]] || fail "Template not found: ${template}"
[[ -n "${mcp_url}" ]] || fail "Missing MCP URL. Usage: phpstorm-mcp-workflows/scripts/configure-mcp.sh [--force] <mcp-url>"

case "${mcp_url}" in
  http://*|https://*)
    ;;
  *)
    fail "MCP URL must start with http:// or https://"
    ;;
esac

if [[ -e "${target}" && "${force}" -ne 1 ]]; then
  fail "Config already exists: ${target}. Re-run with --force to overwrite it."
fi

mcp_type="remote"
mcp_enabled="true"
mcp_protocol_version="2025-03-26"
mcp_client_name="codex-phpstorm-mcp-workflows"
mcp_client_version="0.1.0"
mcp_timeout_seconds="30"

content="$(cat -- "${template}")"
replace_placeholder "__PHPSTORM_MCP_TYPE__" "$(php_string_escape "${mcp_type}")"
replace_placeholder "__PHPSTORM_MCP_URL__" "$(php_string_escape "${mcp_url}")"
replace_placeholder "'__PHPSTORM_MCP_ENABLED__'" "${mcp_enabled}"
replace_placeholder "__MCP_PROTOCOL_VERSION__" "$(php_string_escape "${mcp_protocol_version}")"
replace_placeholder "__MCP_CLIENT_NAME__" "$(php_string_escape "${mcp_client_name}")"
replace_placeholder "__MCP_CLIENT_VERSION__" "$(php_string_escape "${mcp_client_version}")"
replace_placeholder "'__MCP_TIMEOUT_SECONDS__'" "${mcp_timeout_seconds}"

for placeholder in \
  "__PHPSTORM_MCP_TYPE__" \
  "__PHPSTORM_MCP_URL__" \
  "__PHPSTORM_MCP_ENABLED__" \
  "__MCP_PROTOCOL_VERSION__" \
  "__MCP_CLIENT_NAME__" \
  "__MCP_CLIENT_VERSION__" \
  "__MCP_TIMEOUT_SECONDS__"; do
  if [[ "${content}" == *"${placeholder}"* ]]; then
    fail "Placeholder was not replaced: ${placeholder}"
  fi
done

tmp_file="$(mktemp "${target}.tmp.XXXXXX")"
trap 'rm -f -- "${tmp_file}"' EXIT
printf '%s\n' "${content}" > "${tmp_file}"
mv -- "${tmp_file}" "${target}"
trap - EXIT

printf 'Wrote %s\n' "${target}"
