#!/usr/bin/env bash
# Shared prelude for the modern Cyberyen Core Guix driver (contrib/guix/guix-build).
# Not used by legacy contrib/guix/guix-build.sh.

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

check_tools cat env readlink dirname basename git

################
# Repository root (portable; no extra shell libraries)
################

git_root() {
	git rev-parse --show-toplevel 2> /dev/null
}

same_dir() {
	[ "$(cd "$1" && pwd -P)" = "$(cd "$2" && pwd -P)" ]
}

if ! same_dir "${PWD}" "$(git_root)"; then
	cat << EOF
ERR: This script must be invoked from the top level of the git repository

Hint: This may look something like:
 env FOO=BAR ./contrib/guix/guix-build
EOF
	exit 1
fi

################
# Version and archive name (must match Gitian: assign_DISTNAME)
################

if [ -n "${FORCE_VERSION:-}" ]; then
	VERSION="${FORCE_VERSION}"
	DISTNAME="cyberyen-${VERSION}"
elif [ -z "${DISTNAME:-}" ]; then
	# shellcheck disable=SC1091
	source "${PWD}/contrib/gitian-descriptors/assign_DISTNAME"
elif [ -z "${VERSION:-}" ]; then
	VERSION="${DISTNAME#cyberyen-}"
fi

################
# Substitute servers (optional; helps CI and local cached builds)
################

if [ -n "${GUIX_SUBSTITUTE_URLS:-}" ]; then
	SUBSTITUTE_URLS="$GUIX_SUBSTITUTE_URLS"
elif [ -z "${SUBSTITUTE_URLS:-}" ]; then
	SUBSTITUTE_URLS="https://ci.guix.gnu.org https://bordeaux.guix.gnu.org"
fi
export SUBSTITUTE_URLS

################
# Pinned Guix: same fork/commit as legacy contrib/guix/guix-build.sh
################

################
# Child Guix revision (minimal time-machine invocation, matches legacy driver)
################
time_machine() {
	# shellcheck disable=SC2086
	guix time-machine \
		--url="${GUIX_GIT_URL:-https://github.com/dongcarl/guix.git}" \
		--commit="${GUIX_GIT_COMMIT:-b066c25026f21fb57677aa34692a5034338e7ee3}" \
		${SUBSTITUTE_URLS:+--substitute-urls="$SUBSTITUTE_URLS"} \
		${ADDITIONAL_GUIX_TIMEMACHINE_FLAGS:-} \
		-- "$@"
}

################
# Common directory layout
################

version_base_prefix="${PWD}/guix-build-"
VERSION_BASE="${version_base_prefix}${VERSION}"

DISTSRC_BASE="${DISTSRC_BASE:-${VERSION_BASE}}"

OUTDIR_BASE="${OUTDIR_BASE:-${VERSION_BASE}/output}"

var_base_basename="var"
VAR_BASE="${VAR_BASE:-${VERSION_BASE}/${var_base_basename}}"

profiles_base_basename="profiles"
PROFILES_BASE="${PROFILES_BASE:-${VAR_BASE}/${profiles_base_basename}}"
