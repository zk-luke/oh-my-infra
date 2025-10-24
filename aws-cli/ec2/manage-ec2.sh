#!/bin/bash

# Script to start/stop/reboot EC2 instances
# Usage: ./manage-ec2.sh [action] [instance-id-or-name]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default region
DEFAULT_REGION="us-east-1"
REGION="${AWS_REGION:-$DEFAULT_REGION}"

# Check arguments
if [ -z "$1" ] || [ -z "$2" ]; then
    echo -e "${RED}Error: Action and instance identifier are required${NC}"
    echo "Usage: $0 <action> <instance-id-or-name> [region]"
    echo ""
    echo "Actions:"
    echo "  start   - Start a stopped instance"
    echo "  stop    - Stop a running instance"
    echo "  reboot  - Reboot a running instance"
    echo "  status  - Get instance status"
    exit 1
fi

ACTION="$1"
INSTANCE_IDENTIFIER="$2"
REGION="${3:-$REGION}"

# Validate action
case "$ACTION" in
    start|stop|reboot|status)
        ;;
    *)
        echo -e "${RED}Invalid action: $ACTION${NC}"
        echo "Valid actions: start, stop, reboot, status"
        exit 1
        ;;
esac

echo -e "${YELLOW}Looking up instance: $INSTANCE_IDENTIFIER${NC}"

# Try to find instance by ID first, then by name
if [[ "$INSTANCE_IDENTIFIER" =~ ^i-[a-z0-9]+$ ]]; then
    INSTANCE_ID="$INSTANCE_IDENTIFIER"
else
    INSTANCE_ID=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=$INSTANCE_IDENTIFIER" \
        --region "$REGION" \
        --query 'Reservations[0].Instances[0].InstanceId' \
        --output text)
    
    if [ "$INSTANCE_ID" = "None" ] || [ -z "$INSTANCE_ID" ]; then
        echo -e "${RED}Instance not found: $INSTANCE_IDENTIFIER${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Found instance: $INSTANCE_ID${NC}"
echo ""

# Get current status
CURRENT_STATE=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text)

echo "Current state: $CURRENT_STATE"
echo ""

# Perform action
case "$ACTION" in
    start)
        if [ "$CURRENT_STATE" = "running" ]; then
            echo -e "${YELLOW}Instance is already running${NC}"
            exit 0
        fi
        
        echo -e "${YELLOW}Starting instance...${NC}"
        aws ec2 start-instances \
            --instance-ids "$INSTANCE_ID" \
            --region "$REGION" \
            --output json > /dev/null
        
        echo -e "${YELLOW}Waiting for instance to be running...${NC}"
        aws ec2 wait instance-running \
            --instance-ids "$INSTANCE_ID" \
            --region "$REGION"
        
        echo -e "${GREEN}Instance started successfully!${NC}"
        ;;
    
    stop)
        if [ "$CURRENT_STATE" = "stopped" ]; then
            echo -e "${YELLOW}Instance is already stopped${NC}"
            exit 0
        fi
        
        echo -e "${YELLOW}Stopping instance...${NC}"
        aws ec2 stop-instances \
            --instance-ids "$INSTANCE_ID" \
            --region "$REGION" \
            --output json > /dev/null
        
        echo -e "${YELLOW}Waiting for instance to be stopped...${NC}"
        aws ec2 wait instance-stopped \
            --instance-ids "$INSTANCE_ID" \
            --region "$REGION"
        
        echo -e "${GREEN}Instance stopped successfully!${NC}"
        ;;
    
    reboot)
        if [ "$CURRENT_STATE" != "running" ]; then
            echo -e "${RED}Instance must be running to reboot${NC}"
            exit 1
        fi
        
        echo -e "${YELLOW}Rebooting instance...${NC}"
        aws ec2 reboot-instances \
            --instance-ids "$INSTANCE_ID" \
            --region "$REGION"
        
        sleep 5
        
        echo -e "${YELLOW}Waiting for instance to be running...${NC}"
        aws ec2 wait instance-running \
            --instance-ids "$INSTANCE_ID" \
            --region "$REGION"
        
        echo -e "${GREEN}Instance rebooted successfully!${NC}"
        ;;
    
    status)
        INSTANCE_DETAILS=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --region "$REGION" \
            --query 'Reservations[0].Instances[0].[Tags[?Key==`Name`].Value|[0],InstanceType,PublicIpAddress,PrivateIpAddress,State.Name,LaunchTime]' \
            --output text)
        
        NAME=$(echo "$INSTANCE_DETAILS" | awk '{print $1}')
        TYPE=$(echo "$INSTANCE_DETAILS" | awk '{print $2}')
        PUBLIC_IP=$(echo "$INSTANCE_DETAILS" | awk '{print $3}')
        PRIVATE_IP=$(echo "$INSTANCE_DETAILS" | awk '{print $4}')
        STATE=$(echo "$INSTANCE_DETAILS" | awk '{print $5}')
        LAUNCH_TIME=$(echo "$INSTANCE_DETAILS" | awk '{print $6}')
        
        echo "=== Instance Status ==="
        echo "Instance ID: $INSTANCE_ID"
        echo "Name: $NAME"
        echo "Type: $TYPE"
        echo "State: $STATE"
        echo "Public IP: $PUBLIC_IP"
        echo "Private IP: $PRIVATE_IP"
        echo "Launch Time: $LAUNCH_TIME"
        ;;
esac
