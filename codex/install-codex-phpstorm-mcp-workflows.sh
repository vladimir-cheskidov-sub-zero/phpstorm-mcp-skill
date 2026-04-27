#!/usr/bin/env bash
set -euo pipefail

skill_name="phpstorm-mcp-workflows"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"
source_dir="${repo_root}/${skill_name}"
codex_home="${CODEX_HOME:-${HOME}/.codex}"
dest_root="${codex_home}/skills"
dest_dir="${dest_root}/${skill_name}"
dry_run=0
check_only=0
staging_root=""
backup_parent=""
backup_dir=""

usage() {
  cat <<'EOF_USAGE'
Usage: codex/install-codex-phpstorm-mcp-workflows.sh [--dry-run] [--check] [--dest DIR]

Installs, updates, or verifies the phpstorm-mcp-workflows skill for Codex from
this repository into $CODEX_HOME/skills (defaults to ~/.codex/skills).

Options:
  --dry-run   Print the planned install/update actions without changing anything.
  --check     Verify that the installed skill matches this repository checkout.
  --dest DIR  Override the destination skills directory. Must be absolute.
  --help      Show this help message.
EOF_USAGE
}

log() {
  printf '%s\n' "$*"
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

run() {
  if [[ "${dry_run}" -eq 1 ]]; then
    printf '[dry-run] %s\n' "$*"
    return 0
  fi

  "$@"
}

normalize_dest_root() {
  local path="$1"
  local IFS="/"
  local -a parts=()
  local -a stack=()
  local part
  local normalized="/"

  [[ -n "${path}" ]] || fail "Destination skills directory must not be empty."
  [[ "${path}" = /* ]] || fail "Destination skills directory must be an absolute path: ${path}"

  read -r -a parts <<< "${path}"
  for part in "${parts[@]}"; do
    case "${part}" in
      ""|.)
        ;;
      ..)
        if [[ "${#stack[@]}" -gt 0 ]]; then
          unset "stack[$((${#stack[@]} - 1))]"
        fi
        ;;
      *)
        stack+=("${part}")
        ;;
    esac
  done

  for part in "${stack[@]}"; do
    normalized="${normalized%/}/${part}"
  done

  [[ "${normalized}" != "/" ]] || fail "Refusing to use a destination skills directory that normalizes to /: ${path}"

  dest_root="${normalized}"
  dest_dir="${dest_root}/${skill_name}"
}

count_source_files() {
  find "${source_dir}" -type f | wc -l | tr -d '[:space:]'
}

source_revision() {
  git -C "${repo_root}" rev-parse --short HEAD 2>/dev/null || true
}

validate_destination() {
  normalize_dest_root "${dest_root}"

  if [[ -e "${dest_root}" && ! -d "${dest_root}" ]]; then
    fail "Destination skills path exists but is not a directory: ${dest_root}"
  fi

  if [[ -L "${dest_dir}" ]]; then
    fail "Destination skill path is a symlink; refusing to replace it: ${dest_dir}"
  fi

  if [[ -e "${dest_dir}" && ! -d "${dest_dir}" ]]; then
    fail "Destination skill path exists but is not a directory: ${dest_dir}"
  fi
}

compare_installed_skill() {
  [[ -d "${dest_dir}" ]] || fail "Installed skill not found: ${dest_dir}"

  local diff_output
  if ! diff_output="$(diff -qr -- "${source_dir}" "${dest_dir}")"; then
    printf '%s\n' "${diff_output}" >&2
    fail "Installed skill does not match source checkout."
  fi

  log "Installed ${skill_name} matches source checkout at ${dest_dir}"
}

cleanup_temp() {
  if [[ -n "${staging_root}" && -d "${staging_root}" ]]; then
    rm -rf -- "${staging_root}"
  fi

  if [[ -n "${backup_parent}" && -d "${backup_parent}" ]]; then
    rm -rf -- "${backup_parent}"
  fi
}

restore_backup() {
  if [[ -n "${backup_dir}" && -d "${backup_dir}" && ! -e "${dest_dir}" ]]; then
    mv -- "${backup_dir}" "${dest_dir}"
  fi
}

on_error() {
  local status=$?
  trap - ERR
  restore_backup
  cleanup_temp
  exit "${status}"
}

inject_failure_after_backup() {
  if [[ "${CODEX_PHPSTORM_MCP_INSTALL_FAIL_AFTER_BACKUP:-0}" == "1" ]]; then
    printf 'Error: Injected failure after backup.\n' >&2
    return 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run=1
      shift
      ;;
    --check|--verify)
      check_only=1
      shift
      ;;
    --dest)
      [[ $# -ge 2 ]] || fail "Missing value for --dest"
      dest_root="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail "Unknown argument: $1"
      ;;
  esac
done

[[ "${dry_run}" -eq 0 || "${check_only}" -eq 0 ]] || fail "--check cannot be combined with --dry-run."
[[ -d "${source_dir}" ]] || fail "Skill source directory not found: ${source_dir}"
[[ -f "${source_dir}/SKILL.md" ]] || fail "Missing SKILL.md in ${source_dir}"

validate_destination

if [[ "${check_only}" -eq 1 ]]; then
  compare_installed_skill
  exit 0
fi

if [[ -e "${dest_dir}" ]]; then
  action="Updating"
else
  action="Installing"
fi

log "${action} ${skill_name}"
log "Source: ${source_dir}"
log "Destination: ${dest_dir}"

run mkdir -p -- "${dest_root}"

if [[ "${dry_run}" -eq 1 ]]; then
  staging_root="${dest_root}/.${skill_name}.tmp.DRY-RUN"
  backup_parent="${dest_root}/.${skill_name}.backup.DRY-RUN"
else
  staging_root="$(mktemp -d "${dest_root}/.${skill_name}.tmp.XXXXXX")"
  backup_parent="$(mktemp -d "${dest_root}/.${skill_name}.backup.XXXXXX")"
  trap 'on_error' ERR
fi

staging_dir="${staging_root}/${skill_name}"
backup_dir="${backup_parent}/${skill_name}"

run cp -R -- "${source_dir}" "${staging_dir}"

if [[ -e "${dest_dir}" ]]; then
  run mv -- "${dest_dir}" "${backup_dir}"
fi

inject_failure_after_backup

run mv -- "${staging_dir}" "${dest_dir}"
cleanup_temp

if [[ "${dry_run}" -eq 0 ]]; then
  trap - ERR
fi

log "${skill_name} is available at ${dest_dir}"
log "Installed files: $(count_source_files)"
revision="$(source_revision)"
if [[ -n "${revision}" ]]; then
  log "Source revision: ${revision}"
fi
log "Restart Codex to pick up the updated skill."
