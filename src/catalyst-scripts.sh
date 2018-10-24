#!/usr/bin/env bash
LOCAL_TARGET_PACKAGE_ROOT="$1"
ACTION="$2"

cd -P `dirname $0`
cd $(dirname $(readlink $0))
CATALYST_SCRIPTS_REAL_PATH="$PWD"

import find-exec

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

cd "$LOCAL_TARGET_PACKAGE_ROOT"
case "$ACTION" in
  setup-scripts)
    ADDSCRIPT=`require-exec npmAddScript "$LOCAL_TARGET_PACKAGE_ROOT"`
    add_script build 'catalyst-scripts "$PWD" build'
    add_script start 'catalyst-scripts "$PWD" start'
    add_script lint 'catalyst-scripts "$PWD" lint'
    add_script lint-fix 'catalyst-scripts "$PWD" lint-fix'
    add_script install-clean 'rm -rf package-lock.json node_modules/ && npm install'
    add_script prepare 'rm -rf dist && npm run lint && npm run build'
    add_script pretest 'catalyst-scripts "$PWD" pretest'
    add_script test 'npm run pretest && catalyst-scripts "$PWD" test'
    if [[ "$_ADD_SCRIPT_WARNING" -eq "true" ]]; then
      echo "Possibly verwrote some existing scripts. Check your package.json diff and update as necessary."
    fi
  ;;
  pretest)
    BABEL=`require-exec babel "$LOCAL_TARGET_PACKAGE_ROOT"`
    BABEL_CONFIG="${CATALYST_SCRIPTS_REAL_PATH}/../config/babel.config.js"
    #COMMAND="rm -rf test-staging; '${BABEL}' --config-file '${BABEL_CONFIG}' --source-maps src -d test-staging"
    COMMAND="rm -rf test-staging; ${BABEL} --config-file ${BABEL_CONFIG} $LOCAL_TARGET_PACKAGE_ROOT/src --out-dir test-staging --source-maps"
  ;;
  test)
    JEST=`require-exec jest "$LOCAL_TARGET_PACKAGE_ROOT"`
    COMMAND="'${JEST}' -i ./test-staging"
  ;;
  build | start)
    ROLLUP=`require-exec rollup "$LOCAL_TARGET_PACKAGE_ROOT"`
    ROLLUP_CONFIG="${CATALYST_SCRIPTS_REAL_PATH}/../config/rollup.config.js"
    COMMAND="${ROLLUP} --config ${ROLLUP_CONFIG}"
    if [[ "$ACTION" == 'start' ]]; then
      COMMAND="$COMMAND --watch"
    fi
  ;;
  lint | lint-fix)
    ESLINT_CONFIG="${CATALYST_SCRIPTS_REAL_PATH}/../config/eslintrc.json"
    ESLINT=`require-exec eslint "$LOCAL_TARGET_PACKAGE_ROOT"`
    COMMAND="$ESLINT --ext .js,.jsx --config $ESLINT_CONFIG src/**"
    if [[ "$ACTION" == 'lint-fix' ]]; then
      COMMAND="$COMMAND --fix"
    fi
  ;;
  *)
    echo "Unknown catalyst-scripts action: '$ACTION'." >&2
    exit 1
  ;;
esac

eval $COMMAND
