#!/usr/bin/env bash

set -euo pipefail

RETRONAS_ROOT="${RETRONAS_ROOT:-/opt/retronas}"
AN_DEFAULT="${RETRONAS_ROOT}/ansible/retronas_vars.yml.default"
AN_CONFIG="${RETRONAS_ROOT}/ansible/retronas_vars.yml"

read_cfg_value() {
  local key="$1"
  local value=""

  if [ -f "${AN_CONFIG}" ]; then
    value="$(sed -nE "s/^${key}:[[:space:]]*//p" "${AN_CONFIG}" | head -n 1 || true)"
  fi

  # Normalize CRLF and strip YAML quoting/extra whitespace.
  value="$(printf '%s' "${value}" | tr -d '\r' | sed -E "s/^[[:space:]]+|[[:space:]]+$//g; s/^['\"]//; s/['\"]$//")"
  printf '%s' "${value}"
}

# Seed config from defaults on first run.
if [ ! -f "${AN_CONFIG}" ] && [ -f "${AN_DEFAULT}" ]; then
  cp "${AN_DEFAULT}" "${AN_CONFIG}"
fi

# Avoid CRLF artifacts in config files mounted or copied from Windows hosts.
if [ -f "${AN_CONFIG}" ]; then
  sed -i 's/\r$//' "${AN_CONFIG}"
fi

RETRONAS_USER="$(read_cfg_value retronas_user)"
RETRONAS_GROUP="$(read_cfg_value retronas_group)"
RETRONAS_PATH="$(read_cfg_value retronas_path)"

RETRONAS_USER="${RETRONAS_USER:-retronas}"
RETRONAS_GROUP="${RETRONAS_GROUP:-retronas}"
RETRONAS_PATH="${RETRONAS_PATH:-/data/retronas}"

# Fall back to safe defaults if config values are malformed.
if [[ ! "${RETRONAS_USER}" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
  RETRONAS_USER="retronas"
fi

if [[ ! "${RETRONAS_GROUP}" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
  RETRONAS_GROUP="retronas"
fi

# Ensure configured runtime group/user exist.
if ! getent group "${RETRONAS_GROUP}" >/dev/null 2>&1; then
  groupadd --system "${RETRONAS_GROUP}"
fi

if ! id -u "${RETRONAS_USER}" >/dev/null 2>&1; then
  useradd --system --create-home --gid "${RETRONAS_GROUP}" "${RETRONAS_USER}"
fi

mkdir -p "${RETRONAS_PATH}" "${RETRONAS_ROOT}/etc" "${RETRONAS_ROOT}/log" "${RETRONAS_ROOT}/cache"
chown -R "${RETRONAS_USER}:${RETRONAS_GROUP}" "${RETRONAS_PATH}"

# Ensure the agreement file exists to bypass the license prompt.
AGREEMENT_FILE="${RETRONAS_ROOT}/etc/user_agreement"
if [ ! -f "${AGREEMENT_FILE}" ]; then
  touch "${AGREEMENT_FILE}"
fi

# Set Git defaults before any repo init to suppress branch-name hints.
git config --global init.defaultBranch main

# Simulate a Git repository if not in a Git directory.
if [ ! -d "${RETRONAS_ROOT}/.git" ]; then
  git init --initial-branch=main "${RETRONAS_ROOT}"
  git -C "${RETRONAS_ROOT}" config user.name "RetroNAS"
  git -C "${RETRONAS_ROOT}" config user.email "retronas@example.com"
fi

# Predefine terminal selection to avoid interactive prompts.
export TERM="xterm"

exec "$@"