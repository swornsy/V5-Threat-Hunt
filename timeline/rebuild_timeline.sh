#!/bin/bash


if [ ! -f /tmp/adversary_report.txt ]; then

  echo "No log file found"

  exit 1

fi


cat /tmp/adversary_report.txt | sort
