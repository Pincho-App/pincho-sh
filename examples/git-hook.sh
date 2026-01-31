#!/bin/sh
#
# Git Hook Example - Post-Receive Hook
#
# This script sends notifications when code is pushed to a repository.
# Install as a post-receive hook in your Git repository.
#
# Installation:
#   1. Copy this script to .git/hooks/post-receive
#   2. Make it executable: chmod +x .git/hooks/post-receive
#   3. Set environment variables in .git/hooks/post-receive:
#      export PINCHO_TOKEN="pnc_your_token"
#
# Or for a pre-commit hook that checks for TODOs:
#   Copy to .git/hooks/pre-commit
#

# Source the library (adjust path as needed)
. ../pincho.sh

# Get repository name
REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")

# Read pushed ref information from stdin
while read oldrev newrev refname; do
    # Extract branch name
    branch=$(echo "$refname" | sed 's|refs/heads/||')

    # Get commit information
    if [ "$oldrev" = "0000000000000000000000000000000000000000" ]; then
        # New branch
        commit_count=$(git rev-list --count "$newrev")
        message="New branch '$branch' created with $commit_count commit(s)"
        notification_type="git-branch"
    elif [ "$newrev" = "0000000000000000000000000000000000000000" ]; then
        # Branch deleted
        message="Branch '$branch' was deleted"
        notification_type="git-branch"
    else
        # Commits pushed
        commit_count=$(git rev-list --count "${oldrev}..${newrev}")

        if [ "$commit_count" -eq 1 ]; then
            # Single commit - include message
            commit_msg=$(git log -1 --pretty=format:"%s" "$newrev")
            message="1 commit pushed to '$branch':\n\n${commit_msg}"
        else
            # Multiple commits - list them
            commits=$(git log --pretty=format:"- %h: %s" "${oldrev}..${newrev}")
            message="${commit_count} commits pushed to '$branch':\n\n${commits}"
        fi

        notification_type="git-push"
    fi

    # Get author information
    author=$(git log -1 --pretty=format:"%an" "$newrev" 2>/dev/null || echo "Unknown")

    # Send notification
    pincho_send \
        --title "🔄 ${REPO_NAME}" \
        --message "$message\n\nAuthor: $author" \
        --type "$notification_type" \
        --tag "git" \
        --tag "$branch"

    echo "Notification sent for ${refname}"
done

exit 0
