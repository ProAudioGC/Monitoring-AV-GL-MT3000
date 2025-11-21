#!/bin/sh
echo "Content-Type: text/plain"
echo

if [ -f /tmp/monitor_target_history ]; then
    cat /tmp/monitor_target_history
else
    echo "8.8.8.8"
fi
