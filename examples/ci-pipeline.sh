#!/bin/sh
#
# CI/CD Pipeline Notification Example
#
# This script sends notifications for CI/CD pipeline events.
# Works with GitHub Actions, GitLab CI, Jenkins, and other CI systems.
#
# Usage:
#   ./ci-pipeline.sh started
#   ./ci-pipeline.sh success
#   ./ci-pipeline.sh failure "Error: Tests failed"
#

# Exit on error (except for expected failures)
set -e

# Source the library
. ../pincho.sh

# Get event type
EVENT="${1:-unknown}"
ERROR_MESSAGE="${2:-}"

# Detect CI environment
detect_ci_environment() {
    if [ -n "$GITHUB_ACTIONS" ]; then
        CI_SYSTEM="GitHub Actions"
        REPO="$GITHUB_REPOSITORY"
        BRANCH="$GITHUB_REF_NAME"
        COMMIT="$GITHUB_SHA"
        RUN_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
    elif [ -n "$GITLAB_CI" ]; then
        CI_SYSTEM="GitLab CI"
        REPO="$CI_PROJECT_PATH"
        BRANCH="$CI_COMMIT_REF_NAME"
        COMMIT="$CI_COMMIT_SHA"
        RUN_URL="$CI_PROJECT_URL/-/pipelines/$CI_PIPELINE_ID"
    elif [ -n "$JENKINS_URL" ]; then
        CI_SYSTEM="Jenkins"
        REPO="${JOB_NAME:-Unknown}"
        BRANCH="${GIT_BRANCH:-Unknown}"
        COMMIT="${GIT_COMMIT:-Unknown}"
        RUN_URL="${BUILD_URL:-Unknown}"
    else
        CI_SYSTEM="Unknown CI"
        REPO="Unknown"
        BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "Unknown")
        COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "Unknown")
        RUN_URL=""
    fi
}

# Send notification based on event type
send_notification() {
    event="$1"

    case "$event" in
        started|start|begin)
            pincho_send \
                --title "🔄 Build Started" \
                --message "CI/CD pipeline started\n\nSystem: $CI_SYSTEM\nRepository: $REPO\nBranch: $BRANCH\nCommit: $COMMIT" \
                --type "ci-started" \
                --tag "ci" \
                --tag "build" \
                --action "$RUN_URL"
            ;;

        success|passed|pass)
            pincho_send \
                --title "✅ Build Successful" \
                --message "CI/CD pipeline completed successfully\n\nSystem: $CI_SYSTEM\nRepository: $REPO\nBranch: $BRANCH\nCommit: $COMMIT" \
                --type "ci-success" \
                --tag "ci" \
                --tag "build" \
                --action "$RUN_URL"
            ;;

        failure|failed|fail|error)
            error_text=""
            if [ -n "$ERROR_MESSAGE" ]; then
                error_text="\n\nError: $ERROR_MESSAGE"
            fi

            pincho_send \
                --title "❌ Build Failed" \
                --message "CI/CD pipeline failed\n\nSystem: $CI_SYSTEM\nRepository: $REPO\nBranch: $BRANCH\nCommit: $COMMIT${error_text}" \
                --type "ci-failure" \
                --tag "ci" \
                --tag "build" \
                --action "$RUN_URL"
            ;;

        deploy-success)
            pincho_send \
                --title "🚀 Deployment Successful" \
                --message "Application deployed successfully\n\nSystem: $CI_SYSTEM\nRepository: $REPO\nBranch: $BRANCH\nCommit: $COMMIT" \
                --type "deployment" \
                --tag "ci" \
                --tag "deployment" \
                --tag "production" \
                --action "$RUN_URL"
            ;;

        deploy-failure)
            error_text=""
            if [ -n "$ERROR_MESSAGE" ]; then
                error_text="\n\nError: $ERROR_MESSAGE"
            fi

            pincho_send \
                --title "⚠️ Deployment Failed" \
                --message "Application deployment failed\n\nSystem: $CI_SYSTEM\nRepository: $REPO\nBranch: $BRANCH\nCommit: $COMMIT${error_text}" \
                --type "deployment-failure" \
                --tag "ci" \
                --tag "deployment" \
                --tag "production" \
                --action "$RUN_URL"
            ;;

        *)
            echo "Error: Unknown event type '$event'" >&2
            echo "Valid events: started, success, failure, deploy-success, deploy-failure" >&2
            exit 1
            ;;
    esac
}

# Main
detect_ci_environment

echo "CI System: $CI_SYSTEM"
echo "Repository: $REPO"
echo "Branch: $BRANCH"
echo "Commit: $COMMIT"
echo "Event: $EVENT"
echo ""

send_notification "$EVENT"

echo "Notification sent successfully!"
