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

###############################################################################
# Determine event type and set variables accordingly
###############################################################################

if [[ "$GITHUB_EVENT_NAME" == "schedule" ]]; then
    CURRENT_TIME=$((10#$(date -u +"%H%M")))
    echo "Current UTC time: $CURRENT_TIME"
    case $CURRENT_TIME in
        180[0-9] | 181[0-9] | 182[0-5])
            TEST_MODULE="Websters"
            TEST_ENVIRONMENT="PROD"
            TEST_GROUP="ALL"
            ENABLE_PKCE="false"
            ENABLE_TEST_RETRY="false"
            ENABLE_XRAY_REPORT="false"
            ENABLE_SLACK_REPORT="false"
            ;;
        183[0-9] | 184[0-9] | 185[0-5])
            TEST_MODULE="Klasters"
            TEST_ENVIRONMENT="PROD"
            TEST_GROUP="ALL"
            ENABLE_PKCE="false"
            ENABLE_TEST_RETRY="false"
            ENABLE_XRAY_REPORT="false"
            ENABLE_SLACK_REPORT="false"
            ;;
        190[0-9] | 191[0-9] | 192[0-5])
            TEST_MODULE="Websters"
            TEST_ENVIRONMENT="UAT"
            TEST_GROUP="ALL"
            ENABLE_PKCE="false"
            ENABLE_TEST_RETRY="false"
            ENABLE_XRAY_REPORT="false"
            ENABLE_SLACK_REPORT="false"
            ;;
        193[0-9] | 194[0-9] | 195[0-5])
            TEST_MODULE="Klasters"
            TEST_ENVIRONMENT="UAT"
            TEST_GROUP="ALL"
            ENABLE_PKCE="false"
            ENABLE_TEST_RETRY="false"
            ENABLE_XRAY_REPORT="false"
            ENABLE_SLACK_REPORT="false"
            ;;
        *)
            echo "❌ ERROR: No matching schedule found! Exiting..."
            exit 1
            ;;
    esac

elif [[ "$TRIGGERED_FROM_DEV_REPO" == "true" || "$GITHUB_EVENT_NAME" == "workflow_dispatch" || "$GITHUB_EVENT_NAME" == "repository_dispatch" ]]; then
    TEST_MODULE="${GITHUB_EVENT_TEST_MODULE}"
    TEST_ENVIRONMENT="${TEST_ENVIRONMENT:-"PROD"}"
    TEST_GROUP="${TEST_GROUP:-"REGRESSION"}"
    ENABLE_PKCE="${ENABLE_PKCE:-"false"}"
    ENABLE_TEST_RETRY="${ENABLE_TEST_RETRY:-"false"}"
    ENABLE_XRAY_REPORT="${ENABLE_XRAY_REPORT:-"false"}"
    ENABLE_SLACK_REPORT="${ENABLE_SLACK_REPORT:-"false"}"
else
    echo "❌ ERROR: Unsupported event type '$GITHUB_EVENT_NAME'! Exiting..."
    exit 1
fi

###############################################################################
# Validate TEST_MODULE and determine Gradle settings
###############################################################################

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
        #echo "TEST_MODULE=${TEST_MODULE}"
    } >> "$GITHUB_ENV"
else
    echo "⚠️ WARNING: Unable to write to GITHUB_ENV"
fi

###############################################################################
# Change directory and log the configuration
###############################################################################

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

###############################################################################
# Build and execute the Gradle command
###############################################################################

GRADLE_COMMAND="./gradlew $GRADLE_TASK"
GRADLE_COMMAND+=" -DruntimeEnvironment='CICD'"
GRADLE_COMMAND+=" -DtestEnvironment='${TEST_ENVIRONMENT%% *}'"
GRADLE_COMMAND+=" -DenablePKCE='$ENABLE_PKCE'"
GRADLE_COMMAND+=" -DenableTestRetry='$ENABLE_TEST_RETRY'"
GRADLE_COMMAND+=" -DenableXrayReport='$ENABLE_XRAY_REPORT'"
GRADLE_COMMAND+=" -DenableSlackReport='$ENABLE_SLACK_REPORT'"

if [[ -n "$TEST_GROUP" && "$TEST_GROUP" != "ALL" ]]; then
    GRADLE_COMMAND+=" -Dgroups='$TEST_GROUP'"
fi

echo "----------------------------------------"
echo "🚨 Starting test execution 🚨"
echo "----------------------------------------"
echo "> Executing Gradle command: $GRADLE_COMMAND"
eval "$GRADLE_COMMAND"
