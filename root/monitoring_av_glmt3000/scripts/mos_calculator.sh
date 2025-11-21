#!/bin/sh
# mos_calculator.sh <rtt_ms> <jitter_ms> <packet_loss_percent> ; MOS simple

RTT=$1
JITTER=$2
LOSS=$3

# E-model simplifié
R=$(echo "94.2 - $RTT/2 - $JITTER - $LOSS*2.5" | bc)

# Clamp R entre 0 et 100
if [ "$(echo "$R>100" | bc)" -eq 1 ]; then
  R=100
elif [ "$(echo "$R<0" | bc)" -eq 1 ]; then
  R=0
fi

# MOS = 1 + 0.035*R + R*(R-60)*(100-R)*0.000007
MOS=$(echo "scale=2; 1 + 0.035*$R + $R*($R-60)*(100-$R)*0.000007" | bc)

echo $MOS
