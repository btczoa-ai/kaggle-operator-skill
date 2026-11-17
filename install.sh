#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="kaggle-operator"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="${HOME}/.gemini/antigravity-cli/skills/${SKILL_NAME}"

mkdir -p "${TARGET_DIR}"
cp -f "${SRC_DIR}/SKILL.md" "${TARGET_DIR}/SKILL.md"
echo "✅ Installed ${SKILL_NAME} to ${TARGET_DIR}"
