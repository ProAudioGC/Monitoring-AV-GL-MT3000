#!/bin/bash
# Renvoie "running" si monitor.sh tourne, sinon "stopped"

if pgrep -f monitor.sh > /dev/null ; then
    echo "running"
else
    echo "stopped"
fi
