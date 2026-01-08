#!/bin/bash
# Creates a snapshot from an Alibaba ECS instance's root volume and then creates an image from that snapshot
# Usage: ./ecs-snapshot-to-image.sh <prefix> <instance-id>

# Check if parameters are provided
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <prefix> <instance-id>"
  echo ""
  echo "Parameters:"
  echo "  prefix      - Prefix for the snapshot and image names"
  echo "  instance-id - The ECS instance ID to create snapshot from"
  exit 1
fi

prefix="$1"
instance_id="$2"

echo "Creating snapshot and image for instance: $instance_id with prefix: $prefix"
echo ""

# Step 1: Get the root volume ID of the instance
echo "[Step 1/3] Fetching root volume ID from instance..."
volume_id=$(aliyun ecs DescribeDisks --InstanceId "$instance_id" | jq -r .Disks.Disk[].DiskId)

if [ -z "$volume_id" ] || [ "$volume_id" == "null" ]; then
  echo "Error: Could not find root volume for instance $instance_id"
  exit 1
fi

echo "Root volume ID: $volume_id"
echo ""

# Step 2: Create a snapshot from the root volume
echo "[Step 2/3] Creating snapshot from volume..."
snapshot_name="${prefix}-snapshot-$(date +%H%m%d-%H%M)"

snapshot_output=$(aliyun ecs CreateSnapshot --DiskId "$volume_id" --SnapshotName "$snapshot_name")

snapshot_id=$(echo "$snapshot_output" | jq -r .SnapshotId)

if [ -z "$snapshot_id" ] || [ "$snapshot_id" == "null" ]; then
  echo "Error: Failed to create snapshot"
  exit 1
fi

echo "Snapshot created: $snapshot_id ($snapshot_name)"
echo "Waiting for snapshot to complete..."

# Wait for snapshot to complete (max 30 minutes)
max_attempts=180
attempt=0
while [ $attempt -lt $max_attempts ]; do
  snapshot_status=$(aliyun ecs DescribeSnapshots --SnapshotIds "['$snapshot_id']" | jq -r .Snapshots.Snapshot[].Progress)

  if [ "$snapshot_status" == "100%" ]; then
    echo "Snapshot completed successfully! - final state $snapshot_status"
    break
  fi
  
  echo "Snapshot status: $snapshot_status (attempt $((attempt+1))/$max_attempts)"
  sleep 10
  ((attempt++))
done

if [ "$snapshot_status" != "100%" ]; then
  echo "Error: Snapshot creation timed out or failed with status: $snapshot_status"
  exit 1
fi

echo ""

# Step 3: Create an image from the snapshot
echo "[Step 3/3] Creating image from snapshot..."
image_name="${prefix}-image-$(date +%H%m%d-%H%M)"

image_output=$(aliyun ecs CreateImage --SnapshotId "$snapshot_id" --ImageName "$image_name")

image_id=$(echo "$image_output" | jq -r .ImageId)

if [ -z "$image_id" ] || [ "$image_id" == "null" ]; then
  echo "Error: Failed to create image from snapshot"
  exit 1
fi

echo "Image created: $image_id ($image_name)"
echo ""
echo "=== Summary ==="
echo "Instance ID:   $instance_id"
echo "Volume ID:     $volume_id"
echo "Snapshot ID:   $snapshot_id"
echo "Image ID:      $image_id"
echo ""
echo "Image is now being processed and will be available shortly."
