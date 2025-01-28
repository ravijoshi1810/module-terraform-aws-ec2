# Script that can be used within null_resource to wait for the instance status 
# to be "running" and healthy. This will introduce dynamic wait time for the instance to completely 
# boot up and be ready for further configuration.
param (
    [string]$InstanceId
)

# Strip quotes from the input if the value is an empty string
if ($InstanceId -eq '""') {
    $InstanceId = ""
}

# Print the instance ID
Write-Host "Instance ID: '$InstanceId'"

# Function to get detailed instance status
function Get-InstanceDetailedStatus {
    param (
        [string]$InstanceId
    )

    # Get instance status from AWS
    $status = aws ec2 describe-instance-status --instance-ids $InstanceId --query "InstanceStatuses[0]" --output json | ConvertFrom-Json
    return $status
}

# Function to wait for instance status to be "running"
function Wait-ForInstanceRunning {
    param (
        [string]$InstanceId
    )

    Write-Host "Checking status for Instance ID: $InstanceId"
    for ($i = 1; $i -le 10; $i++) {
        Write-Host "Waiting for instance $InstanceId to be in running state... Attempt $i of 10"
        Start-Sleep -Seconds 30

        # Get detailed status
        $status = Get-InstanceDetailedStatus -InstanceId $InstanceId
        $instanceState = $status.InstanceState.Name
        $instanceStatus = $status.InstanceStatus.Status
        $systemStatus = $status.SystemStatus.Status

        # Output instance status for debugging purposes
        Write-Host "Instance State: $instanceState, Instance Status: $instanceStatus, System Status: $systemStatus"

        # Check if both instance and system statuses are ok and the instance is running
        if ($instanceState -eq "running" -and $instanceStatus -eq "ok" -and $systemStatus -eq "ok") {
            Write-Host "Instance $InstanceId is running and healthy!"
            break
        }

        if ($i -eq 10) {
            Write-Host "Instance $InstanceId did not reach the desired state after 10 attempts."
        }
    }
}

# Check and process Instance ID if it is not empty
if (-not [string]::IsNullOrWhiteSpace($InstanceId)) {
    Write-Host "Processing Instance ID: $InstanceId"
    Wait-ForInstanceRunning -InstanceId $InstanceId
} else {
    Write-Host "Skipping status check as Instance ID is empty."
}