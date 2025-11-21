#!/bin/bash
# jitter_monitor.sh <IP> [percentile] ; Jitter et p95

HOST=$1
PCT=${2:-100}  # 100 = moyenne (écart-type), 95 = percentile p95

# récupérer les temps de ping
PING_TIMES=$(ping -c 10 $HOST | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')

# convertir en liste compatible sh
TIMES=""
for t in $PING_TIMES; do
  TIMES="$TIMES $t"
done

# calcul écart-type
SUM=0; SUM2=0; COUNT=0
for t in $TIMES; do
  SUM=$(echo "$SUM+$t" | bc)
  SUM2=$(echo "$SUM2+($t)^2" | bc)
  COUNT=$((COUNT+1))
done

if [ $COUNT -eq 0 ]; then
  echo "0"
  exit 0
fi

MEAN=$(echo "scale=4;$SUM/$COUNT" | bc)
VAR=$(echo "scale=4;($SUM2/$COUNT)-($MEAN)^2" | bc)
STDDEV=$(echo "scale=2;sqrt($VAR)" | bc)

# percentile p95 si demandé
if [ "$PCT" -eq 95 ]; then
  SORTED=$(printf '%s\n' $TIMES | sort -n)
  IDX=$(echo "($COUNT*95/100)-1" | bc)
  [ $IDX -lt 0 ] && IDX=0
  P95=$(echo "$SORTED" | sed -n "$((IDX+1))p")
  echo "$P95"
else
  echo "$STDDEV"
fi
