#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
chmod +x "${ROOT_DIR}/lab.sh"
find "${ROOT_DIR}/scripts" -name "*.sh" -exec chmod +x {} \;
find "${ROOT_DIR}/cases" -type f \( -name "init" -o -name "*.sh" \) -exec chmod +x {} \;
echo "[+] permissions repaired"
