#!/bin/bash

DEBUG_MODE=${2:-true}

log_debug() {
    if [[ "$DEBUG_MODE" == "true" ]]; then
        echo "[DEBUG]: $1"
    fi
}

if [[ -z "$1" ]]; then
    echo "❌ ERROR: Missing required argument! Exiting..."
    echo "Usage: $0 <WORKING_DIRECTORY> [DEBUG_MODE]"
    exit 1
fi

WORKING_DIRECTORY=$1

log_debug "Arguments received: WORKING_DIRECTORY='$WORKING_DIRECTORY', DEBUG_MODE='$DEBUG_MODE'"
log_debug "----------------------------------------"

if [[ ! -d "$WORKING_DIRECTORY" ]]; then
    echo "❌ ERROR: Provided WORKING_DIRECTORY does not exist: $WORKING_DIRECTORY! Exiting..."
    exit 1
fi

if [[ -z "$TEST_MODULES" ]]; then
    echo "❌ ERROR: TEST_MODULES is not set! Exiting..."
    exit 1
fi

mkdir -p artifacts

copy_reports() {
    local MODULE=$1
    local REPORT_TYPE=$2
    local MODULE_PATH=$3
    local TARGET_DIR=$4

    if [[ -d "$MODULE_PATH" ]]; then
        mkdir -p "$TARGET_DIR"
        cp -r "$MODULE_PATH"* "$TARGET_DIR/"
        echo "Moved ${REPORT_TYPE} report files for \"$MODULE\" to $TARGET_DIR"
    else
        echo "No ${REPORT_TYPE} results found for \"$MODULE\""
    fi
}

log_debug "Test modules: ${TEST_MODULES[*]}"

for MODULE in $TEST_MODULES; do
    echo "Starting processing reports for module: $MODULE"
    JUNIT_PATH="$WORKING_DIRECTORY/$MODULE/build/reports/tests/test/junitreports/"
    copy_reports "$MODULE" "JUnit" "$JUNIT_PATH" "artifacts/junit-report"

    TESTNG_PATH="$WORKING_DIRECTORY/$MODULE/build/reports/tests/test/"
    copy_reports "$MODULE" "TestNG" "$TESTNG_PATH" "artifacts/$MODULE-testng-report"
    echo "Finished processing reports for module: $MODULE"
done
