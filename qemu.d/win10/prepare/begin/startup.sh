#!/usr/bin/env bash
# Chnage display input to HDMI1
source /home/tadasb/code/scripts/XAUTHORITY.sh
export DISPLAY=:1
sudo -u tadasb XDG_RUNTIME_DIR=/run/user/1000 kscreen-doctor output.DP-2.disable && ddcutil --display 2 setvcp 60 0x11 && barriers -c /home/tadasb/barrier.conf -n desktop-ryzen --disable-crypto
