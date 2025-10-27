#!/bin/sh
#
# WirePusher Shell Script Library (POSIX sh compatible)
# Official shell script library for WirePusher - https://wirepusher.dev
#
# Usage:
#   source wirepusher.sh
#   wirepusher_send "Title" "Message"
#
# Or with options:
#   wirepusher_send --title "Title" --message "Message" --type info
#
# Environment variables:
#   WIREPUSHER_TOKEN - Your API token (required if not passed as argument)
#   WIREPUSHER_ID    - Your user ID (required if not passed as argument)
#   WIREPUSHER_URL   - API URL (default: https://wirepusher.com/send)
#
# Exit codes:
#   0 - Success
#   1 - Authentication error (401, 403)
#   2 - Validation error (400, 404)
#   3 - Rate limit error (429)
#   4 - Network or other error
#

# Default API URL
WIREPUSHER_URL="${WIREPUSHER_URL:-https://wirepusher.com/send}"

# Escape JSON string
# Escapes quotes, backslashes, newlines, tabs, and control characters
_wirepusher_escape_json() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g' | awk '{
        gsub(/\n/, "\\n");
        gsub(/\r/, "\\r");
        printf "%s", $0;
    }'
}

# Send a notification to WirePusher
#
# Usage:
#   wirepusher_send "Title" "Message"
#   wirepusher_send --title "Title" --message "Message" --type info --tag prod
#
# Arguments:
#   Positional: title message
#   Named:
#     --title TEXT      - Notification title (required, max 256 chars)
#     --message TEXT    - Notification message (required, max 4096 chars)
#     --type TEXT       - Notification type for categorization
#     --tag TEXT        - Add a tag (can be repeated, max 10 tags)
#     --image URL       - Image URL to display
#     --action URL      - Action URL to open when tapped
#     --token TEXT      - API token (overrides WIREPUSHER_TOKEN)
#     --id TEXT         - User ID (overrides WIREPUSHER_ID)
#
# Returns:
#   0 on success, non-zero on error
wirepusher_send() {
    local title=""
    local message=""
    local notification_type=""
    local tags=""
    local image_url=""
    local action_url=""
    local token="${WIREPUSHER_TOKEN}"
    local user_id="${WIREPUSHER_ID}"

    # Parse arguments
    if [ $# -eq 2 ] && [ "${1#--}" = "$1" ]; then
        # Positional arguments: title message
        title="$1"
        message="$2"
    else
        # Named arguments
        while [ $# -gt 0 ]; do
            case "$1" in
                --title)
                    title="$2"
                    shift 2
                    ;;
                --message)
                    message="$2"
                    shift 2
                    ;;
                --type)
                    notification_type="$2"
                    shift 2
                    ;;
                --tag)
                    if [ -z "$tags" ]; then
                        tags="$2"
                    else
                        tags="${tags}|$2"
                    fi
                    shift 2
                    ;;
                --image)
                    image_url="$2"
                    shift 2
                    ;;
                --action)
                    action_url="$2"
                    shift 2
                    ;;
                --token)
                    token="$2"
                    shift 2
                    ;;
                --id)
                    user_id="$2"
                    shift 2
                    ;;
                *)
                    echo "Error: Unknown argument '$1'" >&2
                    echo "Usage: wirepusher_send [--title TITLE] [--message MESSAGE] [options]" >&2
                    return 4
                    ;;
            esac
        done
    fi

    # Validate required parameters
    if [ -z "$title" ]; then
        echo "Error: Title is required" >&2
        return 2
    fi

    if [ -z "$message" ]; then
        echo "Error: Message is required" >&2
        return 2
    fi

    if [ -z "$token" ]; then
        echo "Error: WIREPUSHER_TOKEN environment variable or --token argument is required" >&2
        return 2
    fi

    if [ -z "$user_id" ]; then
        echo "Error: WIREPUSHER_ID environment variable or --id argument is required" >&2
        return 2
    fi

    # Validate lengths
    title_len=$(printf '%s' "$title" | wc -c | tr -d ' ')
    if [ "$title_len" -gt 256 ]; then
        echo "Error: Title must be 256 characters or less (got $title_len)" >&2
        return 2
    fi

    message_len=$(printf '%s' "$message" | wc -c | tr -d ' ')
    if [ "$message_len" -gt 4096 ]; then
        echo "Error: Message must be 4096 characters or less (got $message_len)" >&2
        return 2
    fi

    # Build JSON payload
    local json_data
    json_data='{"id":"'"$(_wirepusher_escape_json "$user_id")"'","title":"'"$(_wirepusher_escape_json "$title")"'","message":"'"$(_wirepusher_escape_json "$message")"'"'

    # Add optional fields
    if [ -n "$notification_type" ]; then
        json_data="${json_data},\"type\":\"$(_wirepusher_escape_json "$notification_type")\""
    fi

    if [ -n "$tags" ]; then
        # Convert pipe-separated tags to JSON array
        tags_json='['
        first=1
        IFS='|'
        for tag in $tags; do
            if [ $first -eq 1 ]; then
                tags_json="${tags_json}\"$(_wirepusher_escape_json "$tag")\""
                first=0
            else
                tags_json="${tags_json},\"$(_wirepusher_escape_json "$tag")\""
            fi
        done
        unset IFS
        tags_json="${tags_json}]"
        json_data="${json_data},\"tags\":${tags_json}"
    fi

    if [ -n "$image_url" ]; then
        json_data="${json_data},\"image_url\":\"$(_wirepusher_escape_json "$image_url")\""
    fi

    if [ -n "$action_url" ]; then
        json_data="${json_data},\"action_url\":\"$(_wirepusher_escape_json "$action_url")\""
    fi

    json_data="${json_data}}"

    # Send request with curl
    local response
    local http_code
    local temp_file

    # Create temp file for response
    temp_file=$(mktemp)

    # Make the request
    http_code=$(curl -fsSL -X POST \
        -H "Content-Type: application/json" \
        -d "$json_data" \
        -w "%{http_code}" \
        -o "$temp_file" \
        --max-time 30 \
        "${WIREPUSHER_URL}?type=wirepusher&token=${token}" 2>/dev/null)

    local curl_exit=$?

    # Read response
    if [ -f "$temp_file" ]; then
        response=$(cat "$temp_file")
        rm -f "$temp_file"
    fi

    # Check curl exit code
    if [ $curl_exit -ne 0 ]; then
        echo "Error: Request failed (curl exit code: $curl_exit)" >&2
        return 4
    fi

    # Check HTTP status code
    case "$http_code" in
        200|201|202)
            # Success
            echo "$response"
            return 0
            ;;
        401|403)
            # Authentication error
            echo "Error: Authentication failed (HTTP $http_code)" >&2
            [ -n "$response" ] && echo "Response: $response" >&2
            return 1
            ;;
        400|404)
            # Validation error
            echo "Error: Validation failed (HTTP $http_code)" >&2
            [ -n "$response" ] && echo "Response: $response" >&2
            return 2
            ;;
        429)
            # Rate limit
            echo "Error: Rate limit exceeded (HTTP $http_code)" >&2
            [ -n "$response" ] && echo "Response: $response" >&2
            return 3
            ;;
        *)
            # Other error
            echo "Error: Request failed (HTTP $http_code)" >&2
            [ -n "$response" ] && echo "Response: $response" >&2
            return 4
            ;;
    esac
}

# Print library version
wirepusher_version() {
    echo "WirePusher Shell Script Library v1.0.0"
}

# Check if required commands are available
wirepusher_check_dependencies() {
    if ! command -v curl >/dev/null 2>&1; then
        echo "Error: curl is required but not installed" >&2
        return 1
    fi
    return 0
}

# Run dependency check when sourced
if ! wirepusher_check_dependencies; then
    return 1 2>/dev/null || exit 1
fi
