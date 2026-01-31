#!/bin/bash
#
# Pincho Shell Script Library (Bash-enhanced version)
# Official shell script library for Pincho - https://pincho.app
#
# This is the Bash-enhanced version with better array handling and string manipulation.
# For maximum compatibility, use pincho.sh instead.
#
# Usage:
#   source pincho-bash.sh
#   pincho_send "Title" "Message"
#
# Or with options:
#   pincho_send --title "Title" --message "Message" --type info --tag prod --tag release
#
# Environment variables:
#   PINCHO_TOKEN - Your API token (required if not passed as argument)
#   PINCHO_URL   - API URL (default: https://api.pincho.app/send)
#
# Rate limit variables (exported after each API call):
#   PINCHO_LAST_RATE_LIMIT     - Total requests allowed per hour
#   PINCHO_LAST_RATE_REMAINING - Requests remaining in current window
#   PINCHO_LAST_RATE_RESET     - Unix timestamp when rate limit resets
#
# Exit codes:
#   0 - Success
#   1 - Authentication error (401, 403)
#   2 - Validation error (400, 404)
#   3 - Rate limit error (429)
#   4 - Network or other error
#

# Require bash 4.0 or higher for associative arrays
if ((BASH_VERSINFO[0] < 4)); then
    echo "Error: Bash 4.0 or higher is required for pincho-bash.sh" >&2
    echo "Current version: ${BASH_VERSION}" >&2
    echo "Consider using pincho.sh for maximum compatibility" >&2
    return 1 2>/dev/null || exit 1
fi

# Default API URL
PINCHO_URL="${PINCHO_URL:-https://api.pincho.app/send}"

# Escape JSON string (Bash version with better string handling)
_pincho_escape_json() {
    local str="$1"
    # Escape backslashes first
    str="${str//\\/\\\\}"
    # Escape quotes
    str="${str//\"/\\\"}"
    # Escape newlines
    str="${str//$'\n'/\\n}"
    # Escape carriage returns
    str="${str//$'\r'/\\r}"
    # Escape tabs
    str="${str//$'\t'/\\t}"
    printf '%s' "$str"
}

# Parse rate limit headers from curl response
# Exports environment variables with rate limit information
_pincho_parse_rate_limit_headers() {
    local headers_file="$1"

    if [ ! -f "$headers_file" ]; then
        return 0
    fi

    # Extract rate limit headers (case-insensitive)
    local limit=$(grep -i '^x-ratelimit-limit:' "$headers_file" | sed 's/^[^:]*:[[:space:]]*//' | tr -d '\r')
    local remaining=$(grep -i '^x-ratelimit-remaining:' "$headers_file" | sed 's/^[^:]*:[[:space:]]*//' | tr -d '\r')
    local reset=$(grep -i '^x-ratelimit-reset:' "$headers_file" | sed 's/^[^:]*:[[:space:]]*//' | tr -d '\r')

    # Export to environment variables if found
    if [ -n "$limit" ]; then
        PINCHO_LAST_RATE_LIMIT="$limit"
        export PINCHO_LAST_RATE_LIMIT
    fi

    if [ -n "$remaining" ]; then
        PINCHO_LAST_RATE_REMAINING="$remaining"
        export PINCHO_LAST_RATE_REMAINING
    fi

    if [ -n "$reset" ]; then
        PINCHO_LAST_RATE_RESET="$reset"
        export PINCHO_LAST_RATE_RESET
    fi
}

# Send a notification to Pincho
#
# Usage:
#   pincho_send "Title" "Message"
#   pincho_send --title "Title" --message "Message" --type info --tag prod --tag release
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
#     --token TEXT      - API token (overrides PINCHO_TOKEN)
#
# Returns:
#   0 on success, non-zero on error
pincho_send() {
    local title=""
    local message=""
    local notification_type=""
    local -a tags=()
    local image_url=""
    local action_url=""
    local token="${PINCHO_TOKEN}"

    # Parse arguments
    if [[ $# -eq 2 && "${1:0:2}" != "--" ]]; then
        # Positional arguments: title message
        title="$1"
        message="$2"
    else
        # Named arguments
        while [[ $# -gt 0 ]]; do
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
                    tags+=("$2")
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
                *)
                    echo "Error: Unknown argument '$1'" >&2
                    echo "Usage: pincho_send [--title TITLE] [--message MESSAGE] [options]" >&2
                    return 4
                    ;;
            esac
        done
    fi

    # Validate required parameters
    if [[ -z "$title" ]]; then
        echo "Error: Title is required" >&2
        return 2
    fi

    if [[ -z "$message" ]]; then
        echo "Error: Message is required" >&2
        return 2
    fi

    if [[ -z "$token" ]]; then
        echo "Error: PINCHO_TOKEN environment variable or --token argument is required" >&2
        return 2
    fi

    # Validate lengths
    if [[ ${#title} -gt 256 ]]; then
        echo "Error: Title must be 256 characters or less (got ${#title})" >&2
        return 2
    fi

    if [[ ${#message} -gt 4096 ]]; then
        echo "Error: Message must be 4096 characters or less (got ${#message})" >&2
        return 2
    fi

    # Validate tags count
    if [[ ${#tags[@]} -gt 10 ]]; then
        echo "Error: Maximum 10 tags allowed (got ${#tags[@]})" >&2
        return 2
    fi

    # Build JSON payload
    local json_data='{"title":"'"$(_pincho_escape_json "$title")"'","message":"'"$(_pincho_escape_json "$message")"'"'

    # Add optional fields
    if [[ -n "$notification_type" ]]; then
        json_data+=",\"type\":\"$(_pincho_escape_json "$notification_type")\""
    fi

    if [[ ${#tags[@]} -gt 0 ]]; then
        # Build tags array
        local tags_json='['
        local first=1
        for tag in "${tags[@]}"; do
            if [[ $first -eq 1 ]]; then
                tags_json+="\"$(_pincho_escape_json "$tag")\""
                first=0
            else
                tags_json+=",\"$(_pincho_escape_json "$tag")\""
            fi
        done
        tags_json+=']'
        json_data+=",\"tags\":${tags_json}"
    fi

    if [[ -n "$image_url" ]]; then
        json_data+=",\"image_url\":\"$(_pincho_escape_json "$image_url")\""
    fi

    if [[ -n "$action_url" ]]; then
        json_data+=",\"action_url\":\"$(_pincho_escape_json "$action_url")\""
    fi

    json_data+='}'

    # Send request with curl
    local response
    local http_code
    local temp_file
    local headers_file

    # Create temp files for response and headers
    temp_file=$(mktemp)
    headers_file=$(mktemp)

    # Make the request
    http_code=$(curl -fsSL -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${token}" \
        -d "$json_data" \
        -w "%{http_code}" \
        -o "$temp_file" \
        -D "$headers_file" \
        --max-time 30 \
        "${PINCHO_URL}" 2>/dev/null)

    local curl_exit=$?

    # Read response
    if [[ -f "$temp_file" ]]; then
        response=$(cat "$temp_file")
        rm -f "$temp_file"
    fi

    # Parse and export rate limit headers
    if [[ -f "$headers_file" ]]; then
        _pincho_parse_rate_limit_headers "$headers_file"
        rm -f "$headers_file"
    fi

    # Check curl exit code
    if [[ $curl_exit -ne 0 ]]; then
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
            [[ -n "$response" ]] && echo "Response: $response" >&2
            return 1
            ;;
        400|404)
            # Validation error
            echo "Error: Validation failed (HTTP $http_code)" >&2
            [[ -n "$response" ]] && echo "Response: $response" >&2
            return 2
            ;;
        429)
            # Rate limit
            echo "Error: Rate limit exceeded (HTTP $http_code)" >&2
            [[ -n "$response" ]] && echo "Response: $response" >&2
            return 3
            ;;
        *)
            # Other error
            echo "Error: Request failed (HTTP $http_code)" >&2
            [[ -n "$response" ]] && echo "Response: $response" >&2
            return 4
            ;;
    esac
}

# Convert text to a notification using AI
#
# Usage:
#   pincho_notifai "Deploy server and restart services"
#   pincho_notifai --text "Check logs" --type "monitoring"
#
# Arguments:
#   Positional: text
#   Named:
#     --text TEXT       - Text to convert (required, 5-2500 chars)
#     --type TEXT       - Notification type for categorization
#     --token TEXT      - API token (overrides PINCHO_TOKEN)
#
# Returns:
#   0 on success, non-zero on error
pincho_notifai() {
    local text=""
    local notification_type=""
    local token="${PINCHO_TOKEN}"

    # Parse arguments
    if [[ $# -eq 1 && "${1#--}" == "$1" ]]; then
        # Positional argument: text
        text="$1"
    else
        # Named arguments
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --text)
                    text="$2"
                    shift 2
                    ;;
                --type)
                    notification_type="$2"
                    shift 2
                    ;;
                --token)
                    token="$2"
                    shift 2
                    ;;
                *)
                    echo "Error: Unknown argument '$1'" >&2
                    echo "Usage: pincho_notifai [--text TEXT] [options]" >&2
                    return 4
                    ;;
            esac
        done
    fi

    # Validate required parameters
    if [[ -z "$text" ]]; then
        echo "Error: Text is required" >&2
        return 2
    fi

    if [[ -z "$token" ]]; then
        echo "Error: PINCHO_TOKEN environment variable or --token argument is required" >&2
        return 2
    fi

    # Validate text length
    local text_len=${#text}
    if [[ $text_len -lt 5 ]]; then
        echo "Error: Text must be at least 5 characters (got $text_len)" >&2
        return 2
    fi
    if [[ $text_len -gt 2500 ]]; then
        echo "Error: Text must be 2500 characters or less (got $text_len)" >&2
        return 2
    fi

    # Build JSON payload
    local json_data
    json_data='{"text":"'"$(_pincho_escape_json "$text")"'"'

    # Add optional type field
    if [[ -n "$notification_type" ]]; then
        json_data="${json_data},\"type\":\"$(_pincho_escape_json "$notification_type")\""
    fi

    json_data="${json_data}}"

    # Send request with curl
    local response
    local http_code
    local temp_file
    local headers_file

    # Create temp files for response and headers
    temp_file=$(mktemp)
    headers_file=$(mktemp)

    # Determine the base URL (remove /send if present, add /notifai)
    local base_url="${PINCHO_URL%/send}"
    local notifai_url="${base_url}/notifai"

    # Make the request
    http_code=$(curl -fsSL -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${token}" \
        -d "$json_data" \
        -w "%{http_code}" \
        -o "$temp_file" \
        -D "$headers_file" \
        --max-time 30 \
        "${notifai_url}" 2>/dev/null)

    local curl_exit=$?

    # Read response
    if [[ -f "$temp_file" ]]; then
        response=$(cat "$temp_file")
        rm -f "$temp_file"
    fi

    # Parse and export rate limit headers
    if [[ -f "$headers_file" ]]; then
        _pincho_parse_rate_limit_headers "$headers_file"
        rm -f "$headers_file"
    fi

    # Check curl exit code
    if [[ $curl_exit -ne 0 ]]; then
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
            [[ -n "$response" ]] && echo "Response: $response" >&2
            return 1
            ;;
        400|404)
            # Validation error
            echo "Error: Validation failed (HTTP $http_code)" >&2
            [[ -n "$response" ]] && echo "Response: $response" >&2
            return 2
            ;;
        429)
            # Rate limit
            echo "Error: Rate limit exceeded (HTTP $http_code)" >&2
            [[ -n "$response" ]] && echo "Response: $response" >&2
            return 3
            ;;
        *)
            # Other error
            echo "Error: Request failed (HTTP $http_code)" >&2
            [[ -n "$response" ]] && echo "Response: $response" >&2
            return 4
            ;;
    esac
}

# Print library version
pincho_version() {
    echo "Pincho Shell Script Library v1.0.0-alpha.1 (Bash)"
}

# Check if required commands are available
pincho_check_dependencies() {
    if ! command -v curl &>/dev/null; then
        echo "Error: curl is required but not installed" >&2
        return 1
    fi
    return 0
}

# Run dependency check when sourced
if ! pincho_check_dependencies; then
    return 1 2>/dev/null || exit 1
fi
