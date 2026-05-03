#!/usr/bin/env bash
# Shared definitions for the modern Cyberyen Core Guix driver (contrib/guix/guix-build).
# Do not source this from legacy contrib/guix/guix-build.sh.

export LC_ALL=C
set -e -o pipefail

################
# Required non-builtin commands should be invocable
################

check_tools() {
	for cmd in "$@"; do
		if ! command -v "$cmd" > /dev/null 2>&1; then
			echo "ERR: This script requires that '$cmd' is installed and available in your \$PATH"
			exit 1
		fi
	done
}

################
# SOURCE_DATE_EPOCH should not unintentionally be set
################

check_source_date_epoch() {
	if [ -n "${SOURCE_DATE_EPOCH:-}" ] && [ -z "${FORCE_SOURCE_DATE_EPOCH:-}" ]; then
		cat << EOF
ERR: Environment variable SOURCE_DATE_EPOCH is set which may break reproducibility.

 Aborting...

Hint: You may want to:
 1. Unset this variable: \`unset SOURCE_DATE_EPOCH\` before rebuilding
 2. Set the 'FORCE_SOURCE_DATE_EPOCH' environment variable if you insist on
 using your own epoch
EOF
		exit 1
	fi
}

check_tools cat mkdir env dirname basename git

################
# Repository root check (no contrib/shell helpers; portable pwd -P)
################

git_repo_root() {
	git rev-parse --show-toplevel
}

same_dir() {
	local a b
	a="$(cd "$1" && pwd -P)"
	b="$(cd "$2" && pwd -P)"
	[ "$a" = "$b" ]
}

if ! same_dir "${PWD}" "$(git_repo_root)"; then
	cat << EOF
ERR: This script must be invoked from the top level of the git repository

Hint:
  cd "\$(git rev-parse --show-toplevel)"
  ./contrib/guix/guix-build
EOF
	exit 1
fi

################
# Version and distribution archive name (Gitian parity)
################
#
# Default naming matches contrib/gitian-descriptors/assign_DISTNAME so that
# Guix-produced tarballs align with the Gitian naming convention.

if [ -n "${FORCE_VERSION:-}" ]; then
	VERSION="${FORCE_VERSION}"
	DISTNAME="cyberyen-${VERSION}"
elif [ -z "${DISTNAME:-}" ]; then
	# shellcheck disable=SC1091
	source "${PWD}/contrib/gitian-descriptors/assign_DISTNAME"
elif [ -z "${VERSION:-}" ]; then
	# DISTNAME was set manually; derive VERSION for path layout.
	VERSION="${DISTNAME#cyberyen-}"
fi

################
# Guix time-machine pin (same baseline as legacy guix-build.sh for toolchain parity)
################
#
# Override with GUIX_GIT_URL / GUIX_GIT_COMMIT only for deliberate experiments.

GUIX_GIT_URL="${GUIX_GIT_URL:-https://github.com/dongcarl/guix.git}"
GUIX_GIT_COMMIT="${GUIX_GIT_COMMIT:-b066c25026f21fb57677aa34692a5034338e7ee3}"

################
# Substitute servers (modern driver only; improves CI reliability vs flaky mirrors)
################
#
# GUIX_SUBSTITUTE_URLS overrides SUBSTITUTE_URLS when set (e.g. in GitHub Actions).
# Otherwise, if SUBSTITUTE_URLS is unset, default to the official Guix build farms.
# Legacy guix-build.sh does not source this file.

if [ -n "${GUIX_SUBSTITUTE_URLS:-}" ]; then
	SUBSTITUTE_URLS="$GUIX_SUBSTITUTE_URLS"
elif [ -z "${SUBSTITUTE_URLS:-}" ]; then
	SUBSTITUTE_URLS="https://ci.guix.gnu.org https://bordeaux.guix.gnu.org"
fi
export SUBSTITUTE_URLS

################
# Execute "$@" in a pinned revision of Guix for reproducibility across time.
################

time_machine() {
	# Same minimal invocation as contrib/guix/guix-build.sh (child Guix revision).
	# Passes SUBSTITUTE_URLS to time-machine and (via guix-build) to shell/environment.
	# shellcheck disable=SC2086
	guix time-machine \
		--url="$GUIX_GIT_URL" \
		--commit="$GUIX_GIT_COMMIT" \
		${SUBSTITUTE_URLS:+--substitute-urls="$SUBSTITUTE_URLS"} \
		${ADDITIONAL_GUIX_TIMEMACHINE_FLAGS:-} \
		-- "$@"
}

################
# Common directory layout (versioned output under the repository tree)
################

version_base_prefix="${PWD}/guix-build-"
VERSION_BASE="${version_base_prefix}${VERSION}"

DISTSRC_BASE="${DISTSRC_BASE:-${VERSION_BASE}}"
OUTDIR_BASE="${OUTDIR_BASE:-${VERSION_BASE}/output}"

var_base_basename="var"
VAR_BASE="${VAR_BASE:-${VERSION_BASE}/${var_base_basename}}"

profiles_base_basename="profiles"
PROFILES_BASE="${PROFILES_BASE:-${VAR_BASE}/${profiles_base_basename}}"
