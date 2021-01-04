function catalyst_test() {
  # TODO: check for 'catalyst' and issue info re. catalyst for to run integration tests
  if [[ -d 'go' ]]; then
    if [[ -n "${GO_RUN:-}" ]]; then GO_RUN="-run '${GO_RUN}'"; fi
    if test_all; then
      COMMAND='cd go; env $(catalyst environments show | tail -n +2 | xargs) go test -v ./... '${GO_RUN:-}'; cd ..;'
    elif test_unit; then
      COMMAND='cd go; env $(catalyst environments show | tail -n +2 | xargs) SKIP_INTEGRATION=true go test -v ./... '${GO_RUN:-}'; cd ..;'
    elif test_integration; then
      if [[ -z "${GO_RUN}" ]]; then GO_RUN="-run Integration"; fi
      COMMAND='cd go; env $(catalyst environments show | tail -n +2 | xargs) go test -v ./... '${GO_RUN}'; cd ..;'
    fi
  fi
  if [[ -d test-staging ]]; then
    if ls ./test-staging/*.js > /dev/null 2>&1; then
      JEST=`require-exec jest`
      JEST_CONFIG="${CONFIG_PATH}/jest.config.js"
      # the '--runInBand' is necessary for the 'seqtests' to work.
      COMMAND="${COMMAND}${JEST} --config=${JEST_CONFIG} --runInBand ./test-staging;"
    fi
    # else nothing to do; no JS files to test
  else
    echoerr "Did not find expected './test-staging'. Try setting the 'pretest' script:\n\"pretest\": \"catalyst-scripts pretest\""
  fi
}
