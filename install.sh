#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="kaggle-operator"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_BASE="${1:-${HOME}/.gemini/antigravity-cli/skills}"
TARGET_DIR="${TARGET_BASE}/${SKILL_NAME}"

mkdir -p "${TARGET_DIR}"
cp -f "${SRC_DIR}/SKILL.md" "${TARGET_DIR}/SKILL.md"

for sub in scripts prototype templates references html; do
  if [[ -d "${SRC_DIR}/${sub}" ]]; then
    mkdir -p "${TARGET_DIR}/${sub}"
    cp -rf "${SRC_DIR}/${sub}/." "${TARGET_DIR}/${sub}/"
  fi
done

chmod +x "${TARGET_DIR}/scripts/"*.py "${TARGET_DIR}/scripts/"*.sh 2>/dev/null || true
echo "✅ Installed ${SKILL_NAME} -> ${TARGET_DIR}"
