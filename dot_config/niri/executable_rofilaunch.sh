#!/usr/bin/env bash


if [[ ! $(pidof rofi) ]]; then
    rofi -show drun
else
    pkill rofi
fi
