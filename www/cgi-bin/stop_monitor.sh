#!/bin/sh

echo "Content-Type: text/plain"
echo ""

# Stop monitor_loop.sh et monitor.sh
for pid in $(ps | grep '[m]onitor_loop.sh' | awk '{print $1}'); do
    kill $pid
done

for pid in $(ps | grep '[m]onitor.sh' | awk '{print $1}'); do
    kill $pid
done

echo "Monitoring arrêté"
