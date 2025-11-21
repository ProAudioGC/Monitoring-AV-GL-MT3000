# Monitoring-AV-GL-MT3000
This project allows real-time monitoring of VoIP/AV service quality, network performance, etc., of a GL-MT3000 router. The data is displayed via a web interface with dynamic graphs.
Ce projet permet de surveiller en temps réel la qualité de service VoIP/AV, les performances réseau ...etc  d’un routeur GL-MT3000. Les données sont affichées via une interface web avec des graphiques dynamiques.

## Fonctionnalités

- Monitoring du **CPU load**.
- Monitoring du **trafic WAN** (RX/TX Mbps).
- Mesure du **jitter**, **RTT ICMP**, **packet loss**, **MOS** et **hops**.
- Suivi des **erreurs et paquets perdus** sur l’interface WAN.
- Surveillance de la **connexion fibre** (CRC, link stability).
- Interface web en temps réel avec graphiques interactifs.
- Zoom sur les graphiques via un popup.
- Start/Stop du monitoring avec boutons colorés et clignotement pour l’état actif.

---

## Prérequis

### Système

- GL-MT3000 OpenWrt en mode routeur OpenWrt.
- Shell Bash disponible (`/bin/bash`).

### Packages OpenWrt nécessaires

- Certains packages doivent être installés pour le monitoring et la génération des métriques :

opkg update
opkg install curl bash coreutils-bc coreutils-sleep coreutils-sort coreutils-awk
opkg install iputils-ping  # pour les tests ICMP
opkg install chart.js  # bibliothèque JS incluse via CDN dans index.html

1. Installation

Copier les fichiers sur le routeur :

/www/web/index.html
/www/web/monitoring_av.json        # fichier JSON de sortie
/www/cgi-bin/start_monitor.sh
/www/cgi-bin/stop_monitor.sh
/www/cgi-bin/status_monitor.sh
/www/cgi-bin/set_target.sh
/www/cgi-bin/get_target.sh

/root/monitoring_av_glmt3000/scripts/monitor.sh
/root/monitoring_av_glmt3000/scripts/jitter_monitor.sh
/root/monitoring_av_glmt3000/scripts/monitor_loop.sh
/root/monitoring_av_glmt3000/scripts/monitor.sh
/root/monitoring_av_glmt3000/scripts/mos_calculator.sh
/root/monitoring_av_glmt3000/scripts/traceroute.sh

2. Rendre les scripts exécutables

chmod +x /root/monitoring_av_glmt3000/scripts/*.sh
chmod +x /www/web/cgi-bin/*.sh

3. Vérifier que le serveur web (ex: uhttpd) peut accéder aux scripts cgi-bin

4. Ouvrir l’interface web :

http://<IP_DU_ROUTEUR>/web/index.html

-----------------------------------------------

## Scripts principaux

- monitor.sh : collecte toutes les métriques système et réseau, écrit dans monitoring_av.json.

- jitter_monitor.sh : mesure le jitter et le percentile p95 via des pings.

- start_monitor.sh / stop_monitor.sh : scripts CGI pour lancer et arrêter le monitoring.

- status_monitor.sh : renvoie l’état actuel du monitoring (running ou stopped).

- set_target.sh / get_target.sh : changer ou récupérer l’IP de destination pour le monitoring VoIP.


## JSON généré

Exemple de contenu de monitoring_av.json :

{
  "timestamp": 1763668258,
  "system": {
    "cpu_load": 2.60
  },
  "network": {
    "wan_rx_Mbps": 2.97,
    "wan_tx_Mbps": 0.02,
    "packet_errors": 0,
    "packet_dropped": 440
  },
  "av": {
    "jitter": 0.0748,
    "jitter_p95": 13.741,
    "packet_loss": 0,
    "mos": 4.29,
    "hops": 15,
    "rtt_icmp": 13.834
  },
  "wan_fibre": {
    "crc": 0,
    "link_stability": 100
  },
  "source_ip": {
    "local": "192.168.0.134",
    "public": "78.193.222.12"
  }
}

-----------------------------

## Notes

- Les deltas de packet_errors et packet_dropped sont calculés dans la page web pour éviter des valeurs absolues trop grandes.

- Les graphiques sont mis à jour via JavaScript toutes les 10 secondes.

## Auteur

© 2025 G. CLARET
