function catalyst_test() {
  # TODO: check for 'catalyst' and issue info re. catalyst for to run integration tests
  if [[ -d 'go' ]]; then
    if [[ -n "${GO_RUN:-}" ]]; then GO_RUN="-run '${GO_RUN}'"; fi
    if test_all; then
      COMMAND='cd go && env $(catalyst environments show | tail -n +2 | xargs) go test -v ./... '${GO_RUN:-}';'
    elif test_unit; then
      COMMAND='cd go && env $(catalyst environments show | tail -n +2 | xargs) SKIP_INTEGRATION=true go test -v ./... '${GO_RUN:-}';'
    elif test_integration; then
      if [[ -z "${GO_RUN}" ]]; then GO_RUN="-run Integration"; fi
      COMMAND='cd go && env $(catalyst environments show | tail -n +2 | xargs) go test -v ./... '${GO_RUN}';'
    fi
  fi
  if [[ -d 'js' ]]; then
    JEST=`require-exec jest`
    JEST_CONFIG="${CONFIG_PATH}/jest.config.js"
    # the '--runInBand' is necessary for the 'seqtests' to work.
    COMMAND="${COMMAND}${JEST} --config=${JEST_CONFIG} --runInBand ./test-staging"
  fi
}
