#!/bin/bash

printf ">> Sending magic packet via SSH...\n\n"
ssh -v mihaicristianfarcas@raspberrypi 'wakeonlan A4:C3:F0:7C:0D:49'

printf "\n>> Sleep 15 seconds...\n\n"

for i in $(seq 1 15);
do
    if [ $i -lt 15 ]; then
        printf "$i, "
    else
	printf "$i!\n"
    fi
    sleep 1
done

printf "\n>> Try connection...\n\n"
ping -c 5 windows
