#!/bin/bash
echo "$(date)  f^r monitor.sh exécuté" >> /tmp/monitor_debug.log

# -----------------------
# CONFIG
# -----------------------
TARGET=$(cat /tmp/monitor_target 2>/dev/null || echo "8.8.8.8")         # IP à pinguer pour AV / link
IPERF_SERVER="192.168.8.1" # Serveur iPerf local ou distant
PUBLIQUE=true            # true pour récupérer l'IP publique
JSON_FILE="/www/web/monitoring_av.json"

# -----------------------
# SYSTEM (optimisé)
# -----------------------

CPU_FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null || echo 0)

# Lire les stats CPU actuelles
read cpu user nice system idle iowait irq softirq steal guest < /proc/stat
total_now=$((user + nice + system + idle + iowait + irq + softirq + steal))
active_now=$((user + nice + system))

# Charger les valeurs précédentes
if [ -f /tmp/cpu_prev ]; then
    read total_prev active_prev < /tmp/cpu_prev
else
    total_prev=$total_now
    active_prev=$active_now
fi

# Calculer CPU load instantanée
delta_total=$((total_now - total_prev))
delta_active=$((active_now - active_prev))

if [ "$delta_total" -gt 0 ]; then
    CPU_LOAD=$(awk "BEGIN {printf \"%.2f\", ($delta_active*100)/$delta_total}")
else
    CPU_LOAD=0
fi

# Sauver les nouvelles valeurs
echo "$total_now $active_now" > /tmp/cpu_prev

# -----------------------
# IP
# -----------------------
LOCAL_IP=$(ip -4 addr show eth0 | awk '/inet / {print $2}' | cut -d/ -f1)
PUB_IP=$(curl -s https://checkip.amazonaws.com || echo "")
SOURCE_IP_LOCAL="$LOCAL_IP"
SOURCE_IP_PUBLIC="$PUB_IP"

# -----------------------
# NETWORK
# -----------------------
WAN_IF="eth0"  # interface fibre Freebox

RX_NOW=$(cat /sys/class/net/$WAN_IF/statistics/rx_bytes)
TX_NOW=$(cat /sys/class/net/$WAN_IF/statistics/tx_bytes)
TIME_NOW=$(date +%s)

RX_PREV_FILE="/tmp/wan_rx_prev"
TX_PREV_FILE="/tmp/wan_tx_prev"
TIME_PREV_FILE="/tmp/wan_time_prev"

# Si première exécution, initialiser fichiers
if [ ! -f $RX_PREV_FILE ] || [ ! -f $TX_PREV_FILE ] || [ ! -f $TIME_PREV_FILE ]; then
    echo $RX_NOW > $RX_PREV_FILE
    echo $TX_NOW > $TX_PREV_FILE
    echo $TIME_NOW > $TIME_PREV_FILE
    WAN_RX_Mbps=0
    WAN_TX_Mbps=0
else
    RX_PREV=$(cat $RX_PREV_FILE)
    TX_PREV=$(cat $TX_PREV_FILE)
    TIME_PREV=$(cat $TIME_PREV_FILE)

    DELTA_BYTES_RX=$((RX_NOW - RX_PREV))
    DELTA_BYTES_TX=$((TX_NOW - TX_PREV))
    DELTA_TIME=$((TIME_NOW - TIME_PREV))
    if [ $DELTA_TIME -le 0 ]; then
        DELTA_TIME=1
    fi

    # Conversion octets/sec  f^r Mbps
    WAN_RX_Mbps=$(awk "BEGIN {printf \"%.2f\", ($DELTA_BYTES_RX*8)/($DELTA_TIME*1000000)}")
    WAN_TX_Mbps=$(awk "BEGIN {printf \"%.2f\", ($DELTA_BYTES_TX*8)/($DELTA_TIME*1000000)}")

    # Mettre à jour fichiers pour prochaine mesure
    echo $RX_NOW > $RX_PREV_FILE
    echo $TX_NOW > $TX_PREV_FILE
    echo $TIME_NOW > $TIME_PREV_FILE
fi

# -----------------------
# PACKET ERRORS / DROPPED
# -----------------------
RX_ERRORS=$(cat /sys/class/net/$WAN_IF/statistics/rx_errors 2>/dev/null || echo 0)
TX_ERRORS=$(cat /sys/class/net/$WAN_IF/statistics/tx_errors 2>/dev/null || echo 0)
RX_DROPPED=$(cat /sys/class/net/$WAN_IF/statistics/rx_dropped 2>/dev/null || echo 0)
TX_DROPPED=$(cat /sys/class/net/$WAN_IF/statistics/tx_dropped 2>/dev/null || echo 0)

# Total erreurs et paquets perdus
PACKET_ERRORS=$((RX_ERRORS + TX_ERRORS))
PACKET_DROPPED=$((RX_DROPPED + TX_DROPPED))

# Pourcentage de paquets perdus (utile pour AV/VoIP)
TOTAL_RX=$(cat /sys/class/net/$WAN_IF/statistics/rx_packets 2>/dev/null || echo 1)
TOTAL_TX=$(cat /sys/class/net/$WAN_IF/statistics/tx_packets 2>/dev/null || echo 1)
DROPPED_PERCENT=$(awk "BEGIN {printf \"%.2f\", (($RX_DROPPED+$TX_DROPPED)*100)/($TOTAL_RX+$TOTAL_TX)}")

# -----------------------
# AV / VoIP
# -----------------------
TARGET=$(cat /tmp/monitor_target 2>/dev/null || echo "8.8.8.8")

# Récupération du jitter et P95 depuis le script qui renvoie un JSON
JITTER_JSON=$(bash /root/monitoring_av_glmt3000/scripts/jitter_monitor.sh $TARGET 2>/dev/null || echo '{"jitter":0,"p95":0}')
JITTER=$(echo "$JITTER_JSON" | jq '.jitter')
P95_JITTER=$(echo "$JITTER_JSON" | jq '.p95')

# Packet loss via ping
PKT_LOSS=$(ping -c 5 $TARGET 2>/dev/null | awk -F',' '/packet loss/ {gsub(/%/,"",$3); print $3+0}' || echo 0)

# -----------------------
# Hops et RTT avec TTL
# -----------------------
TARGET=$(cat /tmp/monitor_target 2>/dev/null || echo "8.8.8.8")

# Ping simple pour obtenir RTT et TTL
PING_OUTPUT=$(ping -c 1 -W 1 $TARGET 2>/dev/null)

# RTT en ms
RTT=$(echo "$PING_OUTPUT" | awk -F'time=' '/time=/{print $2}' | awk '{print $1}')
RTT=${RTT:-0}

# HOPS estimés à partir du TTL reçu
TTL_RECEIVED=$(echo "$PING_OUTPUT" | awk -F'ttl=' '/ttl=/{print $2}' | awk '{print $1}')
if [ -n "$TTL_RECEIVED" ]; then
    if [ "$TTL_RECEIVED" -le 64 ]; then
        TTL_INIT=64
    elif [ "$TTL_RECEIVED" -le 128 ]; then
        TTL_INIT=128
    else
        TTL_INIT=255
    fi
    HOPS=$((TTL_INIT - TTL_RECEIVED + 1))
    [ "$HOPS" -lt 0 ] && HOPS=0
else
    HOPS=0
fi

# Pour debug
echo "HOPS: $HOPS"
echo "RTT: $RTT ms"

# -----------------------
# MOS
# -----------------------
# Calcul MOS via le script externe
MOS=$(bash /root/monitoring_av_glmt3000/scripts/mos_calculator.sh "$RTT" "$JITTER" "$PKT_LOSS" 2>/dev/null || echo 0)
MOS=$(printf "%.2f" "${MOS:-0}")

# -----------------------
# WAN Fibre
# -----------------------
# CRC
CRC=$(ethtool -S $WAN_IF 2>/dev/null | grep crc | awk '{print $2}' || echo 0)
CRC=$(printf "%d" "${CRC:-0}")

# Link stability : ping rapide sur 1 paquet avec timeout 1s
if ping -c 1 -W 1 $TARGET >/dev/null 2>&1; then
    LINK_STABILITY=100
else
    LINK_STABILITY=0
fi

# Timestamp
TIMESTAMP=$(date +%s)

# -----------------------
# Génération JSON
# -----------------------
cat > "$JSON_FILE" <<EOF
{
  "timestamp": $TIMESTAMP,
  "system": {
    "cpu_load": $CPU_LOAD
  },
  "network": {
    "wan_rx_Mbps": ${WAN_RX_Mbps:-0},
    "wan_tx_Mbps": ${WAN_TX_Mbps:-0},
    "packet_errors": ${PACKET_ERRORS:-0},
    "packet_dropped": ${PACKET_DROPPED:-0}
  },
  "av": {
    "jitter": $JITTER,
    "jitter_p95": $P95_JITTER,
    "packet_loss": ${PACKET_LOSS:-0},
    "mos": $MOS,
    "hops": $HOPS,
    "rtt_icmp": $RTT
  },
  "wan_fibre": {
    "crc": $CRC,
    "link_stability": $LINK_STABILITY
  },
  "source_ip": {
    "local": "$SOURCE_IP_LOCAL",
    "public": "$SOURCE_IP_PUBLIC"
  }
}
EOF

echo "$(date)  f^r JSON mis a jour : $JSON_FILE"

