#!/bin/bash

# Script to run a script on an EC2 instance via SSH
# Usage: ./run-script-on-ec2.sh [instance-id-or-name] [script-file] [key-file]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
DEFAULT_REGION="us-east-1"
DEFAULT_USER="ec2-user"
REGION="${AWS_REGION:-$DEFAULT_REGION}"

# Check arguments
if [ -z "$1" ] || [ -z "$2" ]; then
    echo -e "${RED}Error: Instance identifier and script file are required${NC}"
    echo "Usage: $0 <instance-id-or-name> <script-file> [key-file] [region] [user]"
    exit 1
fi

INSTANCE_IDENTIFIER="$1"
SCRIPT_FILE="$2"
KEY_FILE="${3:-$HOME/.ssh/id_rsa}"
REGION="${4:-$REGION}"
SSH_USER="${5:-$DEFAULT_USER}"

# Verify script file exists
if [ ! -f "$SCRIPT_FILE" ]; then
    echo -e "${RED}Error: Script file not found: $SCRIPT_FILE${NC}"
    exit 1
fi

# Verify key file exists
if [ ! -f "$KEY_FILE" ]; then
    echo -e "${RED}Error: Key file not found: $KEY_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}Looking up instance: $INSTANCE_IDENTIFIER${NC}"

# Try to find instance by ID first, then by name
if [[ "$INSTANCE_IDENTIFIER" =~ ^i-[a-z0-9]+$ ]]; then
    INSTANCE_ID="$INSTANCE_IDENTIFIER"
else
    INSTANCE_ID=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=$INSTANCE_IDENTIFIER" "Name=instance-state-name,Values=running" \
        --region "$REGION" \
        --query 'Reservations[0].Instances[0].InstanceId' \
        --output text)
    
    if [ "$INSTANCE_ID" = "None" ] || [ -z "$INSTANCE_ID" ]; then
        echo -e "${RED}No running instance found with name: $INSTANCE_IDENTIFIER${NC}"
        exit 1
    fi
fi

# Get instance public IP
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

if [ "$PUBLIC_IP" = "None" ] || [ -z "$PUBLIC_IP" ]; then
    echo -e "${RED}Instance does not have a public IP address${NC}"
    exit 1
fi

echo -e "${GREEN}Found instance: $INSTANCE_ID${NC}"
echo "Public IP: $PUBLIC_IP"
echo "Script: $SCRIPT_FILE"
echo ""

# Copy script to instance
echo -e "${YELLOW}Copying script to instance...${NC}"
REMOTE_SCRIPT="/tmp/$(basename $SCRIPT_FILE)"

scp -i "$KEY_FILE" \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR \
    "$SCRIPT_FILE" \
    "${SSH_USER}@${PUBLIC_IP}:${REMOTE_SCRIPT}"

echo -e "${GREEN}Script copied successfully${NC}"
echo ""

# Make script executable and run it
echo -e "${YELLOW}Executing script on instance...${NC}"
echo "=========================================="

ssh -i "$KEY_FILE" \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR \
    "${SSH_USER}@${PUBLIC_IP}" \
    "chmod +x ${REMOTE_SCRIPT} && ${REMOTE_SCRIPT}"

EXIT_CODE=$?

echo "=========================================="

if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}Script executed successfully!${NC}"
else
    echo -e "${RED}Script execution failed with exit code: $EXIT_CODE${NC}"
fi

# Cleanup remote script
echo -e "${YELLOW}Cleaning up...${NC}"
ssh -i "$KEY_FILE" \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR \
    "${SSH_USER}@${PUBLIC_IP}" \
    "rm -f ${REMOTE_SCRIPT}"

echo -e "${GREEN}Done!${NC}"
exit $EXIT_CODE
