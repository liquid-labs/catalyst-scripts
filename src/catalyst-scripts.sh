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

CONFIG_PATH="$(npm explore @liquid-labs/catalyst-scripts -- pwd)/config"

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
    ADDSCRIPT=`require-exec npmAddScript`
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
    if [[ -d 'go' ]]; then # && ( [[ -z "${WHICH}" ]] || "go" == "${WHICH}" ]] ); then
      COMMAND="${COMMAND}echo 'building go...'; cd go; go build ./...; cd ..;"
      # TODO: support watch
    fi
    if [[ -d 'js' ]]; then # && ( [[ -z "${WHICH}" ]] || "js" == "${WHICH}" ]] ); then
      ROLLUP=`require-exec rollup`
      ROLLUP_CONFIG="${CONFIG_PATH}/rollup.config.js"
      COMMAND="${COMMAND}echo 'building js...';"
      COMMAND="${COMMAND}${ROLLUP} --config ${ROLLUP_CONFIG};"
      # TODO: make the yalc push conditional
      COMMAND="${COMMAND}yalc push;"
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
    ESLINT_CONFIG="${CONFIG_PATH}/eslintrc.json"
    ESLINT=`require-exec eslint`
    COMMAND="${COMMAND}$ESLINT --ext .js,.jsx --config $ESLINT_CONFIG js/**"
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
