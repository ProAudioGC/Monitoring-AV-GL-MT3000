#!/bin/bash
# traceroute.sh - calcul du nombre de hops vers une IP cible

TARGET="$1"
TTL_MAX=30

# Vérifier que TARGET est défini
if [ -z "$TARGET" ]; then
  echo '{"error":"No target IP provided"}'
  exit 1
fi

# Vérifier que traceroute est présent
if ! command -v /bin/traceroute >/dev/null 2>&1; then
  echo '{"error":"traceroute not installed"}'
  exit 1
fi

# Exécuter traceroute et récupérer le dernier hop
LAST_HOP=$(/bin/traceroute -n -m $TTL_MAX "$TARGET" 2>/dev/null | tail -n1 | awk '{print $1}')

if [ -z "$LAST_HOP" ] || [ "$LAST_HOP" = "*" ]; then
  echo '{"error":"Cannot determine hops"}'
  exit 1
fi

# Nombre de hops = numéro de ligne du dernier hop
HOPS=$(/bin/traceroute -n -m $TTL_MAX "$TARGET" 2>/dev/null | grep -n "$LAST_HOP" | head -1 | cut -d: -f1)

# Retour JSON
cat << EOF
{
  "target": "$TARGET",
  "hops": $HOPS
}
EOF
