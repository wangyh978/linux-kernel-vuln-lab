#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

case_name="${1:?case name required}"
template_dir="${CASES_DIR}/template"
target_dir="${CASES_DIR}/${case_name}"

[[ -d "${template_dir}" ]] || die "template case not found: ${template_dir}"
[[ ! -e "${target_dir}" ]] || die "case already exists: ${target_dir}"

mkdir -p "${target_dir}"
rsync -a "${template_dir}/" "${target_dir}/"

msg "new case created: ${target_dir}"
msg "edit ${target_dir}/overlay/root/repro.sh"
