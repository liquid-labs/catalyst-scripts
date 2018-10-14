#!/usr/bin/env bash
LOCAL_TARGET_PACKAGE_ROOT="$1"
ACTION="$2"

cd -P `dirname $0`
cd $(dirname $(readlink $0))
REACT_SCRIPTS_REAL_PATH="$PWD"
BABEL=$(npm bin)/babel

cd "$LOCAL_TARGET_PACKAGE_ROOT"
HAS_JSX=`find src/ -name "*.jsx" | wc -l`
if (( $HAS_JSX > 0 )); then
  BABEL_CONFIG=babel-react.config.js
else
  BABEL_CONFIG=babel-base.config.js
fi
BABEL_CONFIG="${REACT_SCRIPTS_REAL_PATH}/../config/${BABEL_CONFIG}"

case "$ACTION" in
  build)
    "${BABEL}" --config-file "${BABEL_CONFIG}" src/ --out-dir dist;;
  *)
    echo "Unknown catalyst-scripts action: '$ACTION'." >&2;;
esac
