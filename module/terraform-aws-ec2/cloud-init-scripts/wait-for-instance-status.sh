# scipt that can be used within null_resource to wait for the instance status 
# to be "running" and healthy. # this will introdcuce dynamic wait time for the instance to completely 
#boot up and be ready for further configuration.

#!/bin/bash

INSTANCE_ID=$1

# Strip quotes from the input if the value is an empty string
if [ "$INSTANCE_ID" = '""' ]; then
    INSTANCE_ID=""
fi

# Print the instance ID
echo "Instance ID: '$INSTANCE_ID'"

# Function to get detailed instance status
get_instance_detailed_status() {
    INSTANCE_ID=$1
    STATUS=$(aws ec2 describe-instance-status --instance-ids "$INSTANCE_ID" --query "InstanceStatuses[0]" --output json)
    echo "$STATUS"
}

# Function to wait for instance status to be "running"
wait_for_instance_running() {
    INSTANCE_ID=$1

    echo "Checking status for Instance ID: $INSTANCE_ID"
    for i in {1..10}; do
        echo "Waiting for instance $INSTANCE_ID to be in running state... Attempt $i of 10"
        sleep 30

        # Get detailed status
        STATUS=$(get_instance_detailed_status "$INSTANCE_ID")
        INSTANCE_STATE=$(echo "$STATUS" | jq -r '.InstanceState.Name')
        INSTANCE_STATUS=$(echo "$STATUS" | jq -r '.InstanceStatus.Status')
        SYSTEM_STATUS=$(echo "$STATUS" | jq -r '.SystemStatus.Status')

        echo "Instance State: $INSTANCE_STATE, Instance Status: $INSTANCE_STATUS, System Status: $SYSTEM_STATUS"

        # Check if both instance and system statuses are ok and the instance is running
        if [ "$INSTANCE_STATE" = "running" ] && [ "$INSTANCE_STATUS" = "ok" ] && [ "$SYSTEM_STATUS" = "ok" ]; then
            echo "Instance $INSTANCE_ID is running and healthy!"
            break
        fi

        if [ $i -eq 10 ]; then
            echo "Instance $INSTANCE_ID did not reach the desired state after 10 attempts."
        fi
    done
}

# Check and process Instance ID if it is not empty
if [ -n "$INSTANCE_ID" ]; then
    echo "Processing Instance ID: $INSTANCE_ID"
    wait_for_instance_running "$INSTANCE_ID"
else
    echo "Skipping status check as Instance ID is empty."
fi