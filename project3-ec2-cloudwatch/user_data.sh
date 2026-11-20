#!/bin/bash
set -e

# Wait for the instance to initialize
sleep 120

# Generate CPU load using both vCPUs
for i in 1 2; do
  timeout 360 yes > /dev/null &
done

wait
