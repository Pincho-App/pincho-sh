#!/bin/sh
#
# NotifAI example - Convert text to notifications using AI
#
# This example demonstrates how to use the NotifAI endpoint to convert
# free-form text into structured push notifications using AI.
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

echo "=== NotifAI Examples ==="
echo ""

# Example 1: Simple text conversion
echo "1. Converting simple text to notification..."
response=$(wirepusher_notifai "Deploy server and restart all services")
if [ $? -eq 0 ]; then
    echo "✓ AI conversion successful!"
    echo "Response: $response"
else
    echo "✗ AI conversion failed"
    exit 1
fi

echo ""

# Example 2: Text with type
echo "2. Converting text with type specification..."
response=$(wirepusher_notifai --text "Check error logs for database connection issues" --type "monitoring")
if [ $? -eq 0 ]; then
    echo "✓ AI conversion successful!"
    echo "Response: $response"
else
    echo "✗ AI conversion failed"
    exit 1
fi

echo ""

# Example 3: Longer text with context
echo "3. Converting longer text with context..."
text="Build #147 completed successfully. All tests passed (324/324). "
text="${text}Code coverage increased to 87%. Ready for deployment to staging environment."
response=$(wirepusher_notifai --text "$text" --type "ci-cd")
if [ $? -eq 0 ]; then
    echo "✓ AI conversion successful!"
    echo "Response: $response"
else
    echo "✗ AI conversion failed"
    exit 1
fi

echo ""

# Example 4: Action-oriented text
echo "4. Converting action-oriented text..."
response=$(wirepusher_notifai "SSL certificate expires in 7 days - renew immediately")
if [ $? -eq 0 ]; then
    echo "✓ AI conversion successful!"
    echo "Response: $response"
else
    echo "✗ AI conversion failed"
    exit 1
fi

echo ""

# Example 5: Error notification
echo "5. Converting error message..."
response=$(wirepusher_notifai "API server returned 500 error - database connection timeout after 30 seconds")
if [ $? -eq 0 ]; then
    echo "✓ AI conversion successful!"
    echo "Response: $response"
else
    echo "✗ AI conversion failed"
    exit 1
fi

echo ""
echo "=== All NotifAI conversions completed successfully! ==="
echo ""
echo "Rate limit info:"
[ -n "$WIREPUSHER_LAST_RATE_REMAINING" ] && echo "  Remaining: $WIREPUSHER_LAST_RATE_REMAINING/$WIREPUSHER_LAST_RATE_LIMIT"
