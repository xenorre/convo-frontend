#!/bin/sh
# Health check script for Docker container

set -e

# Check if nginx is running
if ! pgrep -f nginx > /dev/null; then
    echo "ERROR: nginx is not running"
    exit 1
fi

# Check if the health endpoint responds
if ! curl -f -s -o /dev/null http://localhost:8080/health; then
    echo "ERROR: Health endpoint is not responding"
    exit 1
fi

# Check if main app is accessible
if ! curl -f -s -o /dev/null -w "%{http_code}" http://localhost:8080/ | grep -q "200"; then
    echo "ERROR: Main application is not accessible"
    exit 1
fi

echo "Health check passed"
exit 0