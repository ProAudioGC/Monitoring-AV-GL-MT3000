#!/bin/sh

# -----------------------
# Fichiers de PID et de log
# -----------------------
PID_FILE="/tmp/monitor_loop.pid"
LOG_FILE="/tmp/monitor_loop.log"

# -----------------------
# Vérifie si le script tourne déjà
# -----------------------
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if [ -d "/proc/$OLD_PID" ]; then
        echo "$(date)  f^r Le monitoring tourne déjà (PID $OLD_PID)." >> "$LOG_FILE"
        exit 0
    else
        echo "$(date)  f^r PID ancien trouvé mais processus mort, nettoyage." >> "$LOG_FILE"
        rm -f "$PID_FILE"
    fi
fi

# -----------------------
# Enregistre le PID actuel
# -----------------------
echo $$ > "$PID_FILE"
echo "$(date)  f^r Démarrage du monitoring" >> "$LOG_FILE"

# -----------------------
# Boucle principale
# -----------------------
while true
do
    # Ne lancer monitor.sh que s'il n'est pas déjà en cours
    if ! pgrep -f "/root/monitoring_av_glmt3000/scripts/monitor.sh" > /dev/null; then
        echo "$(date)  f^r Lancement de monitor.sh" >> "$LOG_FILE"
        /bin/bash /root/monitoring_av_glmt3000/scripts/monitor.sh >> "$LOG_FILE" 2>&1
    else
        echo "$(date)  f^r monitor.sh déjà en cours, attente..." >> "$LOG_FILE"
    fi
    sleep 30
done