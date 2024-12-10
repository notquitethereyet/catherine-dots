#!/bin/bash
while true; do
    waybar-mpris --position --autofocus --play ▶ --pause  | grep '"tooltip":.*spotify'
    sleep 1
done
