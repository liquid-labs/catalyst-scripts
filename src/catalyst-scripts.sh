#!/usr/bin/env bash

# bash strict settings
set -o errexit # exit on errors
set -o nounset # exit on use of uninitialized variable
set -o pipefail

ACTION="$1"; shift

import echoerr
import find_exec
import lists
source ./lib/pretest.sh
source ./lib/test.sh

SCRIPTS_INSTALL="$(npm explore @liquid-labs/catalyst-scripts -- pwd)"
CONFIG_PATH="${SCRIPTS_INSTALL}/config"
# TODO: support 'JS_DIR' and deprecate 'JS_SRC'
# TODO: deprecate auto-build of js directory since we prefer to use 'src' as default, but don't want to auto-build src
if [[ -z "${NO_BUILD:-}" ]]; then
  if [[ -n "${JS_SRC:-}" ]] && [[ -n "${JS_FILE:-}" ]]; then
    echoerrandexit "Cannot specify both 'JS_SRC' and 'JS_FILE'"
  fi
  # maintain (soon to be deprecated) default 'js' build
  [[ -n "${JS_FILE:-}" ]] || [[ -n "${JS_SRC:-}" ]] || JS_SRC='js'
  # now we set up the references that we need for the build and lint commands
  if [[ -n "${JS_FILE:-}" ]]; then
    JS_BUILD_TARGET="${JS_FILE}"
    JS_LINT_TARGET="${JS_FILE}"
  elif [[ -d "${JS_SRC}" ]]; then
    ! [[ -f "${JS_SRC}/index.js" ]] || JS_BUILD_TARGET="${JS_SRC}/index.js"
    ! [[ -f "${JS_SRC}/index.mjs" ]] || JS_BUILD_TARGET="${JS_SRC}/index.mjs"
    [[ -n "${JS_BUILD_TARGET:-}" ]] || {
      echo "Could not determine index file from JS_SRC: $JS_SRC" >&2
      exit 1
    }
  fi
fi

_ADD_SCRIPT_WARNING=false
function add_script() {
  KEY="${1:-}"
  VALUE="${2:-}"
  if [[ -z "$KEY" ]] || [[ -z "$VALUE" ]] || [[ -z "$ADDSCRIPT" ]]; then
    echo "INTERNAL ERROR: add script called without requried args." >&2
    exit 255
  fi

  $ADDSCRIPT -k "$KEY" -v "$VALUE" >/dev/null 2>/dev/null || (_ADD_SCRIPT_WARNING=true && $ADDSCRIPT -f -k "$KEY" -v "$VALUE" >/dev/null)
}

function test_all() {
  test -z "${TEST_TYPES:-}" || ( test_unit && test_integration )
}

function test_unit() {
  [[ -z "${TEST_TYPES:-}" ]] || echo "$TEST_TYPES" | grep -qE '(^|, *| +)unit?(, *| +|$)'
}

function test_integration() {
  [[ -z "${TEST_TYPES:-}" ]] || echo "$TEST_TYPES" | grep -qE '(^|, *| +)int(egration)?(, *| +|$)'
}

function data_reset() {
  test -z "${NO_DATA_RESET:-}"
}

COMMAND=''
case "$ACTION" in
  setup-scripts)
    ADDSCRIPT=$(require-exec npmAddScript)
    add_script build 'catalyst-scripts build'
    add_script start 'catalyst-scripts start'
    add_script lint 'catalyst-scripts lint'
    add_script lint-fix 'catalyst-scripts lint-fix'
    add_script install-clean 'rm -rf package-lock.json node_modules/ && npm install'
    add_script prepare 'rm -rf dist && npm run lint && npm run build'
    add_script pretest 'catalyst-scripts pretest'
    add_script test 'catalyst-scripts test'
    if [[ "$_ADD_SCRIPT_WARNING" -eq "true" ]]; then
      echo "Possibly verwrote some existing scripts. Check your package.json diff and update as necessary."
    fi
  ;;
  pretest)
    catalyst_pretest
  ;;
  test)
    catalyst_test
  ;;
  build)
    # TODO: support building specific ones
    if [[ -d 'go' ]]; then
      COMMAND="${COMMAND}echo 'building go...'; cd go; go build ./...; cd ..;"
      # TODO: support watch
    fi
    if [[ -f "${JS_BUILD_TARGET:-}" ]]; then
      ROLLUP="JS_BUILD_TARGET='${JS_BUILD_TARGET}' $(require-exec rollup)"
      ROLLUP_CONFIG="${CONFIG_PATH}/rollup.config.js"
      COMMAND="${COMMAND}echo 'building js...';"
      COMMAND="${COMMAND}${ROLLUP} --config ${ROLLUP_CONFIG};"
      # TODO: make the yalc push conditional
      # TODO: 'yalc push' was triggering 'npm prepare' which was running lint and build and then (somehow) causing an infinite loop
      # COMMAND="${COMMAND}yalc push;"
    fi
    if [[ -z "${COMMAND:-}" ]]; then
      echoerrandexit "Did not find anything to build. Did you need to specify JS_SRC or JS_FILE? Recall, 'JS_SRC' is used to target a directory containing an 'index.js' file and potentially other '.js' files. 'JS_FILE' is used to specify a single target file. Using 'JS_SRC' to target a file can cause this error."
    fi
  ;;
  watch)
    # TODO: move this to ancillary docs.
    # Note: we originally tried to use 'rollup --watch' directly as it it would
    # be a bit quicker, but with the yalc push needed for sane "linking" it was
    # hard. We tried to use a rollup plugin to push after the bundles were built
    # but there is simple no "rollup is done" trigger and attempts to detect
    # when rollup made things too complex. See note 'yalc-push plugin'
    # in 'rollup.config'
    # TODO: watch and build go and js separately
    WATCH_DIRS=''
    if [[ -d 'go' ]]; then
      WATCH_DIRS="go"
    fi
    if [[ -d 'js' ]]; then
      WATCH_DIRS="${WATCH_DIRS} js"
    fi
    COMMAND="${COMMAND}npx --no-install watch 'npx --no-install catalyst-scripts build' ${WATCH_DIRS};"
  ;;
  lint | lint-fix)
   # JS_LINT_TARGET can and often is empty.
    # TODO: I think we can depricate the '.liq.eslint.target' option; see where it's used.
    [[ -n "${JS_LINT_TARGET:-}" ]] \
      || JS_LINT_TARGET=$(jq -r '.liq.eslint.target // ""' package.json)
    [[ -n "${JS_LINT_TARGET}" ]] \
      || JS_LINT_TARGET=.
    ESLINT_CONFIG="${CONFIG_PATH}/eslintrc.js"
    ESLINT=$(require-exec eslint)
    # Note the '--ext' option only works with directories and 'JS_LINT_TARGET' defaults to '.'. We'd actually like to
    # handle mor of this from 'eslintrc.js', but AFAIK, this is the only way to do this.
    COMMAND="${COMMAND}$ESLINT --config ${ESLINT_CONFIG} --ext .js,.mjs,.xjs --ignore-pattern 'dist/**/*' ${JS_LINT_TARGET}"
    if [[ "$ACTION" == 'lint-fix' ]]; then
      COMMAND="${COMMAND} --fix"
    fi
    COMMAND="${COMMAND};"
  ;;
  *)
    echo "Unknown catalyst-scripts action: '$ACTION'." >&2
    exit 1
  ;;
esac

eval $COMMAND
