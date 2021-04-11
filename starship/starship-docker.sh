#!/bin/bash

TEXT=""

COUNT=0
while read -r container; do
  COUNT=$((COUNT + 1))
  if [ -z "$TEXT" ]; then
    TEXT="${container}"
  else
    TEXT="${TEXT}, ${container}"
  fi
done < <(docker ps --format "{{.Names}}")

if [ $COUNT -eq 0 ]; then
  echo "no containers"
else
  echo "$TEXT"
fi
