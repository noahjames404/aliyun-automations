#!/bin/bash

# Check if instance ID is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <instance-id>"
  exit 1
fi

# Assign the first argument to a variable
instance_id="$1"

# Start terminal session
ali-instance-cli session --instance "$instance_id"