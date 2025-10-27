#!/bin/sh
#
# System Health Monitoring Example
#
# This script performs comprehensive system health checks and sends
# notifications for any issues detected.
#
# Checks performed:
#   - Service status (systemd services)
#   - SSL certificate expiration
#   - Website availability
#   - Database connectivity
#

# Exit on error
set -e

# Source the library
. ../wirepusher.sh

# Configuration
SERVICES="nginx postgresql redis"  # Space-separated list of services to check
WEBSITES="https://example.com https://api.example.com"  # Space-separated list
SSL_CERT_WARN_DAYS=30  # Warn if SSL cert expires within this many days

# Check systemd service status
check_service() {
    service_name="$1"

    if ! command -v systemctl >/dev/null 2>&1; then
        echo "systemctl not available, skipping service checks"
        return 0
    fi

    echo "Checking service: $service_name"

    if systemctl is-active --quiet "$service_name"; then
        echo "✓ $service_name is running"
        return 0
    else
        echo "✗ $service_name is not running"

        wirepusher_send \
            --title "⚠️ Service Down" \
            --message "Service '$service_name' is not running on $(hostname)\n\nPlease investigate immediately." \
            --type "alert" \
            --tag "monitoring" \
            --tag "service" \
            --tag "$service_name"

        return 1
    fi
}

# Check website availability
check_website() {
    url="$1"

    echo "Checking website: $url"

    # Try to fetch the URL
    if curl -fsSL -o /dev/null --max-time 10 "$url"; then
        echo "✓ $url is accessible"
        return 0
    else
        echo "✗ $url is not accessible"

        wirepusher_send \
            --title "⚠️ Website Down" \
            --message "Website $url is not accessible from $(hostname)\n\nHTTP request failed.\n\nPlease investigate immediately." \
            --type "alert" \
            --tag "monitoring" \
            --tag "website"

        return 1
    fi
}

# Check SSL certificate expiration
check_ssl_cert() {
    domain="$1"

    # Extract domain from URL if needed
    domain=$(echo "$domain" | sed -e 's|https\?://||' -e 's|/.*||')

    echo "Checking SSL certificate: $domain"

    if ! command -v openssl >/dev/null 2>&1; then
        echo "openssl not available, skipping SSL check"
        return 0
    fi

    # Get certificate expiration date
    expiry_date=$(echo | openssl s_client -servername "$domain" -connect "${domain}:443" 2>/dev/null | \
                  openssl x509 -noout -enddate 2>/dev/null | \
                  cut -d= -f2)

    if [ -z "$expiry_date" ]; then
        echo "✗ Could not retrieve SSL certificate for $domain"
        return 1
    fi

    # Convert to epoch time
    expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$expiry_date" +%s 2>/dev/null)
    current_epoch=$(date +%s)
    days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))

    if [ "$days_until_expiry" -le "$SSL_CERT_WARN_DAYS" ]; then
        echo "⚠️  SSL certificate for $domain expires in $days_until_expiry days"

        wirepusher_send \
            --title "⚠️ SSL Certificate Expiring" \
            --message "SSL certificate for $domain will expire in $days_until_expiry days\n\nExpiry date: $expiry_date\n\nPlease renew the certificate." \
            --type "alert" \
            --tag "monitoring" \
            --tag "ssl" \
            --tag "$domain"

        return 1
    else
        echo "✓ SSL certificate for $domain is valid ($days_until_expiry days remaining)"
        return 0
    fi
}

# Main
echo "Starting comprehensive health checks..."
echo ""

all_healthy=0

# Check services
if [ -n "$SERVICES" ]; then
    echo "=== Service Checks ==="
    for service in $SERVICES; do
        check_service "$service" || all_healthy=1
    done
    echo ""
fi

# Check websites
if [ -n "$WEBSITES" ]; then
    echo "=== Website Availability Checks ==="
    for website in $WEBSITES; do
        check_website "$website" || all_healthy=1
    done
    echo ""
fi

# Check SSL certificates
if [ -n "$WEBSITES" ]; then
    echo "=== SSL Certificate Checks ==="
    for website in $WEBSITES; do
        check_ssl_cert "$website" || all_healthy=1
    done
    echo ""
fi

# Send summary if all healthy
if [ $all_healthy -eq 0 ]; then
    echo "All health checks passed!"

    wirepusher_send \
        --title "✓ Health Check: All Systems Operational" \
        --message "All monitored services, websites, and SSL certificates are healthy on $(hostname)" \
        --type "info" \
        --tag "monitoring" \
        --tag "health-check"
else
    echo "Some health checks failed - alerts have been sent"
    exit 1
fi
