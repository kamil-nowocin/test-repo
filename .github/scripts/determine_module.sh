#!/bin/bash

DEBUG_MODE=${3:-true}

log_debug() {
    if [[ "$DEBUG_MODE" == "true" ]]; then
        echo "[DEBUG]: $1"
    fi
}

if [[ -z "$1" || -z "$2" ]]; then
    echo "❌ ERROR: Missing required arguments! Exiting..."
    echo "Usage: $0 <WORKING_DIRECTORY> <TRIGGERED_FROM_DEV_REPO> [DEBUG_MODE]"
    exit 1
fi

WORKING_DIRECTORY=$1
TRIGGERED_FROM_DEV_REPO=$2

log_debug "Arguments received: WORKING_DIRECTORY='$WORKING_DIRECTORY', TRIGGERED_FROM_DEV_REPO='$TRIGGERED_FROM_DEV_REPO', DEBUG_MODE='$DEBUG_MODE'"
log_debug "----------------------------------------"

if [[ ! -d "$WORKING_DIRECTORY" ]]; then
    echo "❌ ERROR: Provided WORKING_DIRECTORY doesn't exist: $WORKING_DIRECTORY! Exiting..."
    exit 1
fi

if [[ "$GITHUB_EVENT_NAME" == "schedule" ]]; then
    CURRENT_TIME=$((10#$(date -u +"%H%M")))
    echo "Current UTC time: $CURRENT_TIME"
    case $CURRENT_TIME in
        200[0-9] | 201[0-9]) TEST_MODULE="Websters" TEST_ENVIRONMENT="PROD" ;;
        203[0-9] | 204[0-9]) TEST_MODULE="Klasters" TEST_ENVIRONMENT="PROD" ;;
        210[0-9] | 211[0-9]) TEST_MODULE="Websters" TEST_ENVIRONMENT="UAT" ;;
        213[0-9] | 214[0-9]) TEST_MODULE="Klasters" TEST_ENVIRONMENT="UAT" ;;
        *) echo "❌ ERROR: No matching schedule found! Exiting..." && exit 1 ;;
    esac
elif [[ "$TRIGGERED_FROM_DEV_REPO" == "true" || "$GITHUB_EVENT_NAME" == "workflow_dispatch" || "$GITHUB_EVENT_NAME" == "repository_dispatch" ]]; then
    TEST_MODULE="$GITHUB_EVENT_TEST_MODULE"
else
    echo "❌ ERROR: Unsupported event type '$GITHUB_EVENT_NAME'! Exiting..."
    exit 1
fi

if [[ -z "$TEST_MODULE" ]]; then
    echo "❌ ERROR: No TEST_MODULE provided! Exiting..."
    exit 1
fi

if [[ "$TEST_MODULE" == "All" ]]; then
    GRADLE_TASK="test"
    TEST_MODULES=("Websters" "Klasters")
else
    GRADLE_TASK="${TEST_MODULE}:test"
    TEST_MODULES=("$TEST_MODULE")
fi

if [[ -w "$GITHUB_ENV" ]]; then
    {
        echo "TEST_MODULES=${TEST_MODULES[*]}"
    } >> "$GITHUB_ENV"
else
    echo "⚠️ WARNING: Unable to write to GITHUB_ENV"
fi

cd "$WORKING_DIRECTORY" || exit 1

log_debug "GitHub event name: $GITHUB_EVENT_NAME"
log_debug "Selected test module: $TEST_MODULE"
log_debug "Selected test environment: $TEST_ENVIRONMENT"
log_debug "Selected test group: $TEST_GROUP"
log_debug "Enable PKCE: $ENABLE_PKCE"
log_debug "Enable Test Retry: $ENABLE_TEST_RETRY"
log_debug "Enable Xray Report: $ENABLE_XRAY_REPORT"
log_debug "Enable Slack Report: $ENABLE_SLACK_REPORT"
log_debug "Gradle Task: $GRADLE_TASK"

GRADLE_COMMAND="./gradlew $GRADLE_TASK"
GRADLE_COMMAND+=" -DruntimeEnvironment='CICD'"
GRADLE_COMMAND+=" -DtestEnvironment='${TEST_ENVIRONMENT%% *}'"
GRADLE_COMMAND+=" -DenablePKCE='$ENABLE_PKCE'"
GRADLE_COMMAND+=" -DenableTestRetry='$ENABLE_TEST_RETRY'"
GRADLE_COMMAND+=" -DenableXrayReport='$ENABLE_XRAY_REPORT'"
GRADLE_COMMAND+=" -DenableSlackReport='$ENABLE_SLACK_REPORT'"

[[ -n "$TEST_GROUP" && "$TEST_GROUP" != "ALL" ]] && GRADLE_COMMAND+=" -Dgroups='$TEST_GROUP'"

echo "----------------------------------------"
echo "🚨 Starting test execution 🚨"
echo "----------------------------------------"
echo "> Executing Gradle command: $GRADLE_COMMAND"
eval "$GRADLE_COMMAND"
