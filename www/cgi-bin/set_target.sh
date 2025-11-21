#!/bin/sh

TARGET=$(echo "$QUERY_STRING" | sed -n 's/^target=//p')

if [ -z "$TARGET" ]; then
    echo "Content-Type: text/plain"
    echo
    echo "ERROR: no target"
    exit 1
fi

# Fichier principal
echo "$TARGET" > /tmp/monitor_target

# Historique
HIST=/tmp/monitor_target_history
touch $HIST

# 1. Ajouter la nouvelle adresse en tête
echo "$TARGET" | cat - $HIST > /tmp/.tmp_history

# 2. Supprimer les doublons
awk '!seen[$0]++' /tmp/.tmp_history > /tmp/.tmp_history2

# 3. Garder les 10 dernières
head -n 10 /tmp/.tmp_history2 > $HIST

# Nettoyage
rm /tmp/.tmp_history /tmp/.tmp_history2

echo "Content-Type: text/plain"
echo
echo "OK"
