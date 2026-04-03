#!/bin/bash

echo "---------------------------------------------------------------"
echo "Sending magic packet via SSH..."
ssh -v mihaicristianfarcas@raspberrypi 'wakeonlan A4:C3:F0:7C:0D:49'

echo "---------------------------------------------------------------"
echo "Sleep 15 seconds..."
sleep 15

echo "---------------------------------------------------------------"
echo "Try connection..."
ping -c 5 windows
