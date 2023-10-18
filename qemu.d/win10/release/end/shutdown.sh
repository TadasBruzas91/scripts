#!/usr/bin/env bash
# Change display input to DisplayPort
source /home/tadasb/code/scripts/XAUTHORITY.sh
export DISPLAY=:1
sudo -u tadasb XDG_RUNTIME_DIR=/run/user/1000 kscreen-doctor output.DP-2.enable && ddcutil --display 2 setvcp 60 0x0f
pkill barrier
