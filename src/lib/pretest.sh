function catalyst_pretest() {
  # TODO https://github.com/Liquid-Labs/catalyst-cli/issues/28
  if test_integration; then # make sure necessary services are running
    echo -n "Checking services... "
    if ! catalyst services list --show-status --exit-on-stopped > /dev/null; then
      echo
      echoerrandexit "Some services are not running. You can either run unit tests are start services. Try one of the following:\ncatalyst packages test --types=unit\ncatalyst services start"
    else
      echo "looks good." # TODO: colorize
    fi
  fi

  if [[ -d 'go' ]]; then
    if ! data_reset; then
      COMMAND="${COMMAND}echo 'Skippeng DB reset.';"
    elif test_integration && [[ -n "$(find go -name "sql.go" -print -quit)" ]]; then
      # Because go generally builds faster than DBs reset, we check the build
      # first to avoid possible costly and pointless DB reset.
      COMMAND="${COMMAND}echo 'Complie check...'; cd go && go build ./...; cd ..;"
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
}
