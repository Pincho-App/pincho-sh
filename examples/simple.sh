#!/bin/sh
#
# Simple Pincho notification example
#
# This example demonstrates basic usage of the Pincho library
# with environment variables for configuration.
#

# Exit on error
set -e

# Source the library
. ../pincho.sh

# Check if credentials are set
if [ -z "$PINCHO_TOKEN" ]; then
    echo "Error: Please set PINCHO_TOKEN environment variable" >&2
    echo "" >&2
    echo "Example:" >&2
    echo "  export PINCHO_TOKEN='pnc_your_token'" >&2
    exit 1
fi

# Send a simple notification with positional arguments
echo "Sending simple notification..."
if pincho_send "Hello from Shell!" "This is a test notification"; then
    echo "✓ Notification sent successfully!"
else
    echo "✗ Failed to send notification"
    exit 1
fi

# Send a notification with named arguments
echo ""
echo "Sending notification with options..."
if pincho_send \
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
