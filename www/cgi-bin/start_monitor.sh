#!/bin/sh

echo "Content-Type: text/plain"
echo ""

# Vérifie si monitor_loop.sh tourne déjà
if ps | grep '[m]onitor_loop.sh' > /dev/null; then
    echo "Monitoring déjà en cours"
    exit 0
fi

# Lancer le loop en arrière-plan
/bin/sh /root/monitoring_av_glmt3000/scripts/monitor_loop.sh > /tmp/monitor_loop.log 2>&1 &
echo "Monitoring démarré"
