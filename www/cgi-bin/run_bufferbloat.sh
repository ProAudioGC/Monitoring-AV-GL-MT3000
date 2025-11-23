#!/bin/sh
echo "Content-Type: application/json"
echo ""

UPLOAD_MBPS=900
TMP="/tmp/bufferbloat.json"

bash /root/monitoring_av_glmt3000/scripts/test_bufferbloat_auto.sh "$UPLOAD_MBPS" "$TMP"

if [ ! -f "$TMP" ]; then
    echo '{"bufferbloat_test":"failed","ping_avg_ms":999}'
    exit 0
fi

MODE=$(jq -r '.mode' "$TMP")
AVG=$(jq -r '.AVG' "$TMP")

STATUS="passed"
[ "$AVG" -gt 200 ] && STATUS="failed"

echo "{\"bufferbloat_test\":\"$STATUS\",\"mode\":\"$MODE\",\"ping_avg_ms\":$AVG}"
