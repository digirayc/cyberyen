#!/usr/bin/env bash
# Fast local smoke tests for the modern Cyberyen Core Guix path (contrib/guix/guix-build).
# Does not run a full release build. Safe for CI-style quick validation.

export LC_ALL=C

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly REPO_TOP="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"

# Colors (disable if not a TTY)
if [ -t 1 ]; then
	readonly _R='\033[0;31m'
	readonly _G='\033[0;32m'
	readonly _Y='\033[1;33m'
	readonly _B='\033[1;34m'
	readonly _N='\033[0m'
else
	readonly _R='' _G='' _Y='' _B='' _N=''
fi

pass() {
	echo -e "${_G}[PASS]${_N} $*"
}

fail() {
	echo -e "${_R}[FAIL]${_N} $*"
}

info() {
	echo -e "${_B}[INFO]${_N} $*"
}

failures=0
record_fail() {
	failures=$((failures + 1))
	fail "$1"
}

cd "${REPO_TOP}" || exit 1

echo ""
info "Cyberyen Core — modern Guix smoke tests"
echo ""

# Repository root
if ! git rev-parse --show-toplevel > /dev/null 2>&1; then
	record_fail "Not a git repository."
	exit 1
fi
if [ "$(git rev-parse --show-toplevel)" != "$(pwd -P)" ]; then
	record_fail "Run from repository root (expected: $(git rev-parse --show-toplevel))"
	exit 1
fi
pass "Working directory is git repository root."

# Bash syntax
info "Checking bash syntax (bash -n)..."
for f in \
	contrib/guix/guix-build \
	contrib/guix/libexec/prelude.bash \
	contrib/guix/autotools-build.sh \
	contrib/guix/guix-clean; do
	if bash -n "${REPO_TOP}/${f}" 2>/tmp/test-modern-bash-err.$$; then
		pass "bash -n ${f}"
	else
		record_fail "bash -n ${f}: $(cat /tmp/test-modern-bash-err.$$)"
	fi
done
rm -f /tmp/test-modern-bash-err.$$

# guix-build --help
info "Checking contrib/guix/guix-build --help..."
if out="$(./contrib/guix/guix-build --help 2>&1)" && [ -n "${out}" ]; then
	pass "guix-build --help prints usage"
else
	record_fail "guix-build --help produced no output or non-zero exit"
fi

# assign_DISTNAME
info "Checking VERSION / DISTNAME via contrib/gitian-descriptors/assign_DISTNAME..."
# shellcheck disable=SC1091
if source "${REPO_TOP}/contrib/gitian-descriptors/assign_DISTNAME" 2>/tmp/test-modern-assign.$$; then
	if [ -n "${VERSION:-}" ] && [ "${DISTNAME:-}" = "cyberyen-${VERSION}" ]; then
		pass "DISTNAME=${DISTNAME} VERSION=${VERSION}"
	else
		record_fail "Unexpected VERSION/DISTNAME (DISTNAME=${DISTNAME:-} VERSION=${VERSION:-})"
	fi
else
	record_fail "Could not source assign_DISTNAME: $(cat /tmp/test-modern-assign.$$)"
fi
rm -f /tmp/test-modern-assign.$$

# Manifest evaluation via guix time-machine (requires guix + network/substitutes may be used)
info "Checking manifest.scm via guix time-machine shell --pure..."
GUIX_URL="${GUIX_GIT_URL:-https://github.com/dongcarl/guix.git}"
GUIX_COMMIT="${GUIX_GIT_COMMIT:-b066c25026f21fb57677aa34692a5034338e7ee3}"

if ! command -v guix > /dev/null 2>&1; then
	record_fail "guix not in PATH; install Guix to run manifest evaluation."
else
	pass "guix found: $(command -v guix)"
	export HOST=x86_64-linux-gnu
	if guix time-machine \
		--url="${GUIX_URL}" \
		--commit="${GUIX_COMMIT}" \
		${GUIX_SUBSTITUTE_URLS:+--substitute-urls="${GUIX_SUBSTITUTE_URLS}"} \
		--fallback \
		shell \
		--manifest="${REPO_TOP}/contrib/guix/manifest.scm" \
		--pure \
		-- true 2>/tmp/test-modern-guix.$$; then
		pass "guix time-machine shell --pure -- manifest.scm"
	else
		record_fail "Manifest evaluation failed: $(tail -20 /tmp/test-modern-guix.$$)"
	fi
	rm -f /tmp/test-modern-guix.$$
fi

echo ""
if [ "${failures}" -eq 0 ]; then
	echo -e "${_G}All modern Guix local checks PASSED${_N}"
	exit 0
else
	echo -e "${_R}FAILED — ${failures} check(s) failed${_N}"
	exit 1
fi
