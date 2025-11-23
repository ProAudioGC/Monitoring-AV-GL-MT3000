#!/bin/sh
# test_bufferbloat_auto.sh
# Usage: ./test_bufferbloat_auto.sh <UPLOAD_MBPS> <OUTPUT.json>

UPLOAD_MBPS="$1"
OUTPUT_FILE="$2"

if [ -z "$UPLOAD_MBPS" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Usage: $0 <UPLOAD_MBPS> <OUTPUT_FILE>"
    exit 1
fi

# Assurer fping
if ! command -v fping >/dev/null; then
    opkg update
    opkg install fping
fi

# Assurer jq
if ! command -v jq >/dev/null; then
    opkg update
    opkg install jq
fi

# Liste serveurs iperf3 fiables
SERVERS="iperf.paris1.he.net iperf3.scaleway.com speedtest.serverius.net"

IPERF_SERVER=""
for S in $SERVERS; do
    iperf3 -c "$S" -t 1 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        IPERF_SERVER="$S"
        break
    fi
done

MODE=""
if [ -n "$IPERF_SERVER" ]; then
    MODE="iperf3"
    iperf3 -c "$IPERF_SERVER" -b "${UPLOAD_MBPS}M" -t 25 >/dev/null 2>&1 &
    LOAD_PID=$!
else
    MODE="http_fallback"
    ( while true; do
        dd if=/dev/zero bs=64k count=64 2>/dev/null | wget -O /dev/null --method=POST --body-file=- http://speed.cloudflare.com >/dev/null 2>&1
      done ) &
    LOAD_PID=$!
fi

# Mesure latence
PING=$(fping -c 20 -p 200 1.1.1.1 2>&1 | grep "min/avg/max")

RAW_MIN=$(echo "$PING" | awk -F'=' '{print $2}' | awk -F'/' '{print $1}')
RAW_AVG=$(echo "$PING" | awk -F'=' '{print $2}' | awk -F'/' '{print $2}')
RAW_MAX=$(echo "$PING" | awk -F'=' '{print $2}' | awk -F'/' '{print $3}')

clean() {
    echo "$1" | tr -dc '0-9.'
}

MIN=$(clean "$RAW_MIN")
AVG=$(clean "$RAW_AVG")
MAX=$(clean "$RAW_MAX")

[ -z "$MIN" ] && MIN=999
[ -z "$AVG" ] && AVG=999
[ -z "$MAX" ] && MAX=999

kill $LOAD_PID 2>/dev/null

echo "{\"mode\":\"$MODE\",\"MIN\":$MIN,\"AVG\":$AVG,\"MAX\":$MAX}" > "$OUTPUT_FILE"

