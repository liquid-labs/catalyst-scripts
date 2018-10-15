#!/usr/bin/env bash
LOCAL_TARGET_PACKAGE_ROOT="$1"
ACTION="$2"

cd -P `dirname $0`
cd $(dirname $(readlink $0))
REACT_SCRIPTS_REAL_PATH="$PWD"

function find-exec() {
  EXEC_NAME="$1"

  EXEC=$(npm bin)/$EXEC_NAME
  if [ ! -x "$EXEC" ]; then
    cd $LOCAL_TARGET_PACKAGE_ROOT
    EXEC=$(npm bin)/$EXEC_NAME
  fi
  if [ ! -x "$EXEC" ]; then
    echo "Could not locate '$EXEC_NAME' executable; bailing out." >&2
    exit 10
  fi
  echo $EXEC
}

cd "$LOCAL_TARGET_PACKAGE_ROOT"
if [[ "$ACTION" == 'build' ]] || [[ "$ACTION" == 'start' ]]; then
  # we prefer our own babel, if installed
  BABEL=`find-exec babel`

  HAS_JSX=`find src/ -name "*.jsx" | wc -l`
  if (( $HAS_JSX > 0 )); then
    BABEL_CONFIG=babel-react.config.js
  else
    BABEL_CONFIG=babel-base.config.js
  fi
  BABEL_CONFIG="${REACT_SCRIPTS_REAL_PATH}/../config/${BABEL_CONFIG}"

  COMMAND="${BABEL} --config-file ${BABEL_CONFIG} src/ --out-dir dist"
  if [[ "$ACTION" == 'start' ]]; then
    COMMAND="$COMMAND --watch"
  fi
elif [[ "$ACTION" == 'lint' ]] || [[ "$ACTION" == 'lint-fix' ]]; then
  ESLINT_CONFIG="${REACT_SCRIPTS_REAL_PATH}/../config/eslintrc.json"
  ESLINT=`find-exec eslint`
  COMMAND="$ESLINT --ext .js,.jsx --config $ESLINT_CONFIG src/**"
  if [[ "$ACTION" == 'lint-fix' ]]; then
    COMMAND="$COMMAND --fix"
  fi
else
  echo "Unknown catalyst-scripts action: '$ACTION'." >&2
  exit 1
fi

$COMMAND
