#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

required=(bash tar xz bzip2 make gcc bison flex bc cpio gzip rsync file qemu-system-x86_64 gdb)

msg "checking host tools"
for cmd in "${required[@]}"; do need_cmd "${cmd}"; done

if command -v wget >/dev/null 2>&1; then
  msg "wget detected: resilient downloads enabled"
elif command -v curl >/dev/null 2>&1; then
  warn "wget not found, will use curl fallback with retry and resume"
else
  die "missing downloader: install wget or curl"
fi

msg "host tools are ready"
