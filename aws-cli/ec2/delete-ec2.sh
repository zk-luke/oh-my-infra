#!/bin/bash

# Script to delete an EC2 instance
# Usage: ./delete-ec2.sh [instance-id-or-name]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default region
DEFAULT_REGION="us-east-1"
REGION="${AWS_REGION:-$DEFAULT_REGION}"

# Check if instance identifier is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Instance ID or Name is required${NC}"
    echo "Usage: $0 <instance-id-or-name> [region]"
    exit 1
fi

INSTANCE_IDENTIFIER="$1"
REGION="${2:-$REGION}"

echo -e "${YELLOW}Searching for instance: $INSTANCE_IDENTIFIER${NC}"
echo "Region: $REGION"
echo ""

# Try to find instance by ID first, then by name
if [[ "$INSTANCE_IDENTIFIER" =~ ^i-[a-z0-9]+$ ]]; then
    INSTANCE_ID="$INSTANCE_IDENTIFIER"
    echo "Using Instance ID: $INSTANCE_ID"
else
    # Search by name tag
    INSTANCE_ID=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=$INSTANCE_IDENTIFIER" "Name=instance-state-name,Values=running,stopped,stopping" \
        --region "$REGION" \
        --query 'Reservations[0].Instances[0].InstanceId' \
        --output text)
    
    if [ "$INSTANCE_ID" = "None" ] || [ -z "$INSTANCE_ID" ]; then
        echo -e "${RED}Instance not found with name: $INSTANCE_IDENTIFIER${NC}"
        exit 1
    fi
    echo "Found Instance ID: $INSTANCE_ID"
fi

# Get instance details before termination
echo ""
echo -e "${YELLOW}Fetching instance details...${NC}"
INSTANCE_DETAILS=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --query 'Reservations[0].Instances[0].[Tags[?Key==`Name`].Value|[0],InstanceType,PublicIpAddress,State.Name]' \
    --output text)

NAME=$(echo "$INSTANCE_DETAILS" | awk '{print $1}')
TYPE=$(echo "$INSTANCE_DETAILS" | awk '{print $2}')
PUBLIC_IP=$(echo "$INSTANCE_DETAILS" | awk '{print $3}')
STATE=$(echo "$INSTANCE_DETAILS" | awk '{print $4}')

echo "=== Instance to be terminated ==="
echo "Instance ID: $INSTANCE_ID"
echo "Name: $NAME"
echo "Type: $TYPE"
echo "Public IP: $PUBLIC_IP"
echo "Current State: $STATE"
echo ""

# Confirm deletion
read -p "$(echo -e ${RED}Are you sure you want to terminate this instance? [y/N]: ${NC})" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Termination cancelled${NC}"
    exit 0
fi

# Terminate instance
echo ""
echo -e "${YELLOW}Terminating instance...${NC}"
aws ec2 terminate-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --output json > /dev/null

echo -e "${GREEN}Termination request sent successfully!${NC}"
echo ""

# Wait for instance to be terminated
echo -e "${YELLOW}Waiting for instance to terminate...${NC}"
aws ec2 wait instance-terminated \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION"

echo -e "${GREEN}Instance terminated successfully!${NC}"
echo "Instance ID: $INSTANCE_ID"

# Log deletion
LOG_FILE="ec2-deletions.log"
echo "$(date): Terminated instance $INSTANCE_ID ($NAME) - $TYPE - $PUBLIC_IP" >> "$LOG_FILE"
echo -e "${GREEN}Deletion logged to: $LOG_FILE${NC}"
