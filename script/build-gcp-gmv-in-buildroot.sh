#!/usr/bin/env bash

# Builds a patched version of coreutils with support for progress reporting for `cp` and `mv`.
# See https://github.com/jarun/advcpmv

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

usage() {
	echo "Usage: script/build-gcp-gmv-in-buildroot.sh <output dir>"
}

if ! [[ $# -eq 1 ]]; then
	usage
	exit 1
fi

OUT_DIR="$1"
OLD_BUILDROOT=0

if ! [[ -d $BUILDROOT ]]; then
  echo "Please set the BUILDROOT environment variable"
  exit 1
fi

if ! [[ -f $BUILDROOT/output/host/bin/ ]]; then
  OLD_BUILDROOT=1
fi

declare -r BUILDROOT_BUILD_DIR="$BUILDROOT/output/build/coreutils-advcp-8.31"

add_buildroot_package() {
  rm -rf "$BUILDROOT/package/coreutils-advcp"
  cp -r script/buildroot-coreutils-advcp "$BUILDROOT/package/coreutils-advcp"
  if (( $OLD_BUILDROOT )); then
    sed -i 's/_OPTS/_OPT/g' "$BUILDROOT/package/coreutils-advcp/coreutils-advcp.mk"
  fi
}

build_buildroot_package() {
  cd "$BUILDROOT"
  make coreutils-advcp-build
  cd -
}

cp_to_out() {
  cp "$BUILDROOT_BUILD_DIR/src/cp" "$OUT_DIR/gcp"
  cp "$BUILDROOT_BUILD_DIR/src/mv" "$OUT_DIR/gmv"
}

main() {
  set -x
  if ! [[ -f "$OUT_DIR/gcp" ]]; then
    add_buildroot_package
    build_buildroot_package
    cp_to_out
  fi
}

main