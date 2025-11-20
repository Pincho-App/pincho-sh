#!/bin/sh
#
# Simple WirePusher notification example
#
# This example demonstrates basic usage of the WirePusher library
# with environment variables for configuration.
#

# Exit on error
set -e

# Source the library
. ../wirepusher.sh

# Check if credentials are set
if [ -z "$WIREPUSHER_TOKEN" ]; then
    echo "Error: Please set WIREPUSHER_TOKEN environment variable" >&2
    echo "" >&2
    echo "Example:" >&2
    echo "  export WIREPUSHER_TOKEN='wpt_your_token'" >&2
    exit 1
fi

# Send a simple notification with positional arguments
echo "Sending simple notification..."
if wirepusher_send "Hello from Shell!" "This is a test notification"; then
    echo "✓ Notification sent successfully!"
else
    echo "✗ Failed to send notification"
    exit 1
fi

# Send a notification with named arguments
echo ""
echo "Sending notification with options..."
if wirepusher_send \
    --title "Deploy Complete" \
    --message "Application v1.2.3 has been deployed to production" \
    --type "deployment" \
    --tag "production" \
    --tag "release"; then
    echo "✓ Notification sent successfully!"
else
    echo "✗ Failed to send notification"
    exit 1
fi

echo ""
echo "All notifications sent successfully!"
