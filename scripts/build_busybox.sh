#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

src_dir="$(busybox_src_dir)"
install_dir="$(busybox_install_dir)"
jobs="${JOBS:-$(nproc_safe)}"

[[ -d "${src_dir}" ]] || die "busybox source not found: ${src_dir}"
mkdir -p "${install_dir}"

if [[ -f "${install_dir}/bin/busybox" ]]; then
  msg "busybox already built: ${install_dir}/bin/busybox"
  exit 0
fi

config_file="${src_dir}/.config"

config_enable() {
  local key="$1"
  if grep -q "^# ${key} is not set" "${config_file}"; then
    sed -i "s/^# ${key} is not set/${key}=y/" "${config_file}"
  elif grep -q "^${key}=" "${config_file}"; then
    sed -i "s/^${key}=.*/${key}=y/" "${config_file}"
  else
    echo "${key}=y" >> "${config_file}"
  fi
}

config_disable() {
  local key="$1"
  if grep -q "^${key}=" "${config_file}"; then
    sed -i "s/^${key}=.*/# ${key} is not set/" "${config_file}"
  elif ! grep -q "^# ${key} is not set" "${config_file}"; then
    echo "# ${key} is not set" >> "${config_file}"
  fi
}

config_set_value() {
  local key="$1"
  local value="$2"
  if grep -q "^# ${key} is not set" "${config_file}"; then
    sed -i "s/^# ${key} is not set/${key}=${value}/" "${config_file}"
  elif grep -q "^${key}=" "${config_file}"; then
    sed -i "s/^${key}=.*/${key}=${value}/" "${config_file}"
  else
    echo "${key}=${value}" >> "${config_file}"
  fi
}

msg "configuring minimal busybox for initramfs lab"
make -C "${src_dir}" distclean >/dev/null 2>&1 || true
make -C "${src_dir}" allnoconfig

config_enable CONFIG_STATIC
config_enable CONFIG_INSTALL_NO_USR
config_enable CONFIG_BUSYBOX

# shell
config_enable CONFIG_SH_IS_ASH
config_enable CONFIG_ASH
config_enable CONFIG_ASH_OPTIMIZE_FOR_SIZE
config_enable CONFIG_ASH_INTERNAL_GLOB
config_enable CONFIG_ASH_BASH_COMPAT
config_enable CONFIG_ASH_ECHO
config_enable CONFIG_ASH_PRINTF
config_enable CONFIG_ASH_TEST
config_enable CONFIG_ASH_GETOPTS
config_enable CONFIG_ASH_CMDCMD
config_enable CONFIG_ASH_EXPAND_PRMT
config_enable CONFIG_FEATURE_SH_MATH
config_enable CONFIG_FEATURE_SH_MATH_64
config_enable CONFIG_FEATURE_SH_MATH_BASE
config_enable CONFIG_FEATURE_SH_READ_FRAC
config_enable CONFIG_FEATURE_SH_HISTFILESIZE
config_enable CONFIG_FEATURE_EDITING
config_enable CONFIG_FEATURE_TAB_COMPLETION
config_set_value CONFIG_FEATURE_EDITING_HISTORY 64
config_set_value CONFIG_FEATURE_EDITING_MAX_LEN 1024

# basic applets
for key in \
  CONFIG_CAT CONFIG_CHMOD CONFIG_CHOWN CONFIG_CP CONFIG_CUT CONFIG_DATE CONFIG_DD CONFIG_DMESG \
  CONFIG_ECHO CONFIG_ENV CONFIG_FALSE CONFIG_FIND CONFIG_GREP CONFIG_GUNZIP CONFIG_GZIP CONFIG_HEAD \
  CONFIG_HOSTNAME CONFIG_KILL CONFIG_LN CONFIG_LS CONFIG_MKDIR CONFIG_MKNOD CONFIG_MOUNT CONFIG_MOUNTPOINT \
  CONFIG_MV CONFIG_PRINTF CONFIG_PS CONFIG_PWD CONFIG_RESET CONFIG_RM CONFIG_RMDIR CONFIG_SED \
  CONFIG_SEQ CONFIG_SLEEP CONFIG_SORT CONFIG_STAT CONFIG_STTY CONFIG_SWITCH_ROOT CONFIG_SYNC \
  CONFIG_TAIL CONFIG_TAR CONFIG_TEE CONFIG_TEST CONFIG_TIMEOUT CONFIG_TOUCH CONFIG_TRUE CONFIG_TR \
  CONFIG_UMOUNT CONFIG_UNAME CONFIG_UNIQ CONFIG_USLEEP CONFIG_VI CONFIG_WC CONFIG_XARGS \
  CONFIG_CPIO CONFIG_HEXDUMP CONFIG_OD CONFIG_DF CONFIG_FREE CONFIG_CLEAR \
  CONFIG_INSMOD CONFIG_RMMOD CONFIG_LSMOD CONFIG_MODPROBE_SMALL
do
  config_enable "${key}"
done

# optional network helpers
for key in CONFIG_IFCONFIG CONFIG_IP CONFIG_ROUTE CONFIG_PING CONFIG_PING6 CONFIG_NETSTAT CONFIG_NSLOOKUP; do
  config_disable "${key}"
done

# disable console/kd.h-related tools
for key in \
  CONFIG_CHVT CONFIG_DEALLOCVT CONFIG_DUMPKMAP CONFIG_FGCONSOLE CONFIG_KBD_MODE \
  CONFIG_LOADFONT CONFIG_LOADKMAP CONFIG_OPENVT CONFIG_SETCONSOLE CONFIG_SETKEYCODES \
  CONFIG_SETLOGCONS CONFIG_SHOWKEY
do
  config_disable "${key}"
done

# resolve remaining symbols non-interactively
yes "" | make -C "${src_dir}" oldconfig >/dev/null || true

if command -v musl-gcc >/dev/null 2>&1; then
  msg "building static busybox with musl-gcc"
  make -C "${src_dir}" -j"${jobs}" CC=musl-gcc
else
  warn "musl-gcc not found, building dynamic busybox"
  make -C "${src_dir}" -j"${jobs}"
fi

msg "installing busybox"
rm -rf "${install_dir}"
mkdir -p "${install_dir}"
make -C "${src_dir}" CONFIG_PREFIX="${install_dir}" install

[[ -f "${install_dir}/bin/busybox" ]] || die "busybox build failed"
msg "busybox build complete"

