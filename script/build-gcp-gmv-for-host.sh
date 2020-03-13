#!/usr/bin/env bash

# Builds a patched version of coreutils with support for progress reporting for `cp` and `mv`.
# See https://github.com/jarun/advcpmv

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

usage() {
	echo "Usage: script/build-gcp-gmv-for-host.sh <build dir> <output dir>"
}

if ! [[ $# -eq 2 ]]; then
	usage
	exit 1
fi

declare -r BUILD_DIR="$1"
declare -r OUT_DIR="$2"

declare -r SRC_CACHE=cache
declare -r COREUTILS_VER=coreutils-8.31
declare -r PATCH_URL='https://raw.githubusercontent.com/jarun/advcpmv/master/advcpmv-0.8-8.31.patch'
declare -r SRC_DIR="$SRC_CACHE/$COREUTILS_VER"

declare -ra COREUTILS_CONF_ENV=(
  ac_cv_c_restrict=no
  ac_cv_func_chown_works=yes
  ac_cv_func_euidaccess=no
  ac_cv_func_fstatat=yes
  ac_cv_func_getdelim=yes
  ac_cv_func_getgroups=yes
  ac_cv_func_getgroups_works=yes
  ac_cv_func_getloadavg=no
  ac_cv_func_lstat_dereferences_slashed_symlink=yes
  ac_cv_func_lstat_empty_string_bug=no
  ac_cv_func_strerror_r_char_p=no
  ac_cv_func_strnlen_working=yes
  ac_cv_func_strtod=yes
  ac_cv_func_working_mktime=yes
  ac_cv_have_decl_strerror_r=yes
  ac_cv_have_decl_strnlen=yes
  ac_cv_lib_getloadavg_getloadavg=no
  ac_cv_lib_util_getloadavg=no
  ac_fsusage_space=yes
  ac_use_included_regex=no
  am_cv_func_working_getline=yes
  fu_cv_sys_stat_statfs2_bsize=yes
  gl_cv_func_getcwd_null=yes
  gl_cv_func_getcwd_path_max=yes
  gl_cv_func_gettimeofday_clobber=no
  gl_cv_func_fstatat_zero_flag=no
  gl_cv_func_link_follows_symlink=no
  gl_cv_func_re_compile_pattern_working=yes
  gl_cv_func_svid_putenv=yes
  gl_cv_func_tzset_clobber=no
  gl_cv_func_working_mkstemp=yes
  gl_cv_func_working_utimes=yes
  gl_getline_needs_run_time_check=no
  gl_cv_have_proc_uptime=yes
  utils_cv_localtime_cache=no
  PERL=missing
  MAKEINFO=true
)

declare -ra COREUTILS_CONF_OPTS=(
  --disable-acl
  --disable-libcap
  --disable-rpath
  --disable-single-binary
  --disable-xattr
  --without-gmp
)

check_deps() {
  if ! which autoreconf > /dev/null; then
    echo 'Please install automake'
    exit 1
  fi
  if ! which bison > /dev/null; then
    echo 'Please install bison'
    exit 1
  fi
}

download_and_patch() {
  if [[ -d $SRC_DIR ]]; then
    return
  fi
  set -x
  mkdir -p "$SRC_CACHE"
  cd "$SRC_CACHE"
  wget "http://ftp.gnu.org/gnu/coreutils/$COREUTILS_VER.tar.xz"
  tar xvJf "$COREUTILS_VER.tar.xz"
  rm "$COREUTILS_VER.tar.xz"
  cd "$COREUTILS_VER/"
  \curl "$PATCH_URL" -o advcmp.patch
  patch -p1 -i advcmp.patch
  cd ../..
}

cp_to_build() {
  mkdir -p "$BUILD_DIR"
  cp -rf "$SRC_DIR/"* "$BUILD_DIR/"
}

build() {
  cd "$BUILD_DIR"
  autoreconf
  env "${COREUTILS_CONF_ENV[@]}" ./configure "${COREUTILS_CONF_OPTS[@]}"
  make -j "$(getconf _NPROCESSORS_ONLN)"
  cd -
}

cp_to_out() {
  cp "$BUILD_DIR/src/cp" "$OUT_DIR/gcp"
  cp "$BUILD_DIR/src/mv" "$OUT_DIR/gmv"
}

main() {
  check_deps
  set -x
  if ! [[ -f "$OUT_DIR/gcp" ]]; then
    download_and_patch
    cp_to_build
    build
    cp_to_out
  fi
}

main