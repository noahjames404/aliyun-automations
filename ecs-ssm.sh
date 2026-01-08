#!/bin/bash
# https://www.alibabacloud.com/help/en/ecs/user-guide/register-a-public-key-and-connect-to-an-instance-with-the-key-by-using-ali-instance-cli
# Check if instance ID is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <instance-id>"
  exit 1
fi

# Assign the first argument to a variable
instance_id="$1"

# Start terminal session
ali-instance-cli session --instance "$instance_id"