#!/usr/bin/env bash

# bash strict settings
set -o errexit # exit on errors
set -o nounset # exit on use of uninitialized variable
set -o pipefail

ACTION="$1"; shift

import echoerr
import find_exec
import lists
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
    if [[ -d 'go' ]]; then
      if ! data_reset; then
        COMMAND="${COMMAND}echo 'Skippeng DB reset.';"
      elif test_integration && [[ -n "$(find go -name "sql.go" -print -quit)" ]]; then
        # Because go generally builds faster than DBs reset, we check the build
        # first to avoid possible costly and pointless DB reset.
        COMMAND="${COMMAND}echo 'Complie check...'; cd go && go build ./...;"
        # Rebuild the schema
        COMMAND="${COMMAND}"'echo "Ressetting database..."; catalyst data rebuild sql || ( EXIT=$?; echo -e "If you want to run only unit tests, you can invoke the NPM command like\nTEST_TYPES=unit npm run test"; exit $EXIT );'
        # Load test data (if any)
        if [[ -d "./data/sql/test" ]]; then
          COMMAND="${COMMAND}catalyst data load test;"
        else
          echo "No test data files found."
        fi
      fi
    fi
    if [[ -d 'js' ]]; then
      BABEL=`require-exec babel`
      BABEL_CONFIG="${CONFIG_PATH}/babel.config.js"
      # Jest is not picking up the external maps, so we inline them for the test.
      COMMAND="${COMMAND}rm -rf test-staging; ${BABEL} --config-file ${BABEL_CONFIG} ./js --out-dir test-staging --source-maps=inline"
    fi
  ;;
  test)
    catalyst_test
  ;;
  build | watch)
    if [[ -d 'go' ]]; then
      COMMAND="${COMMAND}cd go; go build ./...; cd ..;"
    fi
    if [[ -d 'js' ]]; then
      ROLLUP=`require-exec rollup`
      ROLLUP_CONFIG="${CONFIG_PATH}/rollup.config.js"
      COMMAND="${COMMAND}${ROLLUP} --config ${ROLLUP_CONFIG}"
      if [[ "$ACTION" == 'watch' ]]; then
        COMMAND="${COMMAND} --watch"
      fi
      COMMAND="${COMMAND};"
    fi
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
