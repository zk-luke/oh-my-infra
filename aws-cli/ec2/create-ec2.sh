#!/bin/bash

# Script to create an EC2 instance
# Usage: ./create-ec2.sh [instance-name] [instance-type] [ami-id]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
DEFAULT_INSTANCE_TYPE="t3.micro"
DEFAULT_AMI_ID="ami-0c55b159cbfafe1f0"  # Amazon Linux 2 (update for your region)
DEFAULT_REGION="us-east-1"
DEFAULT_KEY_NAME="my-key-pair"
DEFAULT_SECURITY_GROUP="default"

# Parse arguments
INSTANCE_NAME="${1:-my-ec2-instance}"
INSTANCE_TYPE="${2:-$DEFAULT_INSTANCE_TYPE}"
AMI_ID="${3:-$DEFAULT_AMI_ID}"
KEY_NAME="${4:-$DEFAULT_KEY_NAME}"
SECURITY_GROUP="${5:-$DEFAULT_SECURITY_GROUP}"
REGION="${AWS_REGION:-$DEFAULT_REGION}"

echo -e "${GREEN}Creating EC2 Instance...${NC}"
echo "Instance Name: $INSTANCE_NAME"
echo "Instance Type: $INSTANCE_TYPE"
echo "AMI ID: $AMI_ID"
echo "Key Name: $KEY_NAME"
echo "Security Group: $SECURITY_GROUP"
echo "Region: $REGION"
echo ""

# Create EC2 instance
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-groups "$SECURITY_GROUP" \
    --region "$REGION" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

if [ -z "$INSTANCE_ID" ]; then
    echo -e "${RED}Failed to create instance${NC}"
    exit 1
fi

echo -e "${GREEN}Instance created successfully!${NC}"
echo "Instance ID: $INSTANCE_ID"
echo ""

# Wait for instance to be running
echo -e "${YELLOW}Waiting for instance to be in running state...${NC}"
aws ec2 wait instance-running \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION"

echo -e "${GREEN}Instance is now running!${NC}"
echo ""

# Get instance details
INSTANCE_INFO=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --query 'Reservations[0].Instances[0].[PublicIpAddress,PrivateIpAddress,State.Name]' \
    --output text)

PUBLIC_IP=$(echo "$INSTANCE_INFO" | awk '{print $1}')
PRIVATE_IP=$(echo "$INSTANCE_INFO" | awk '{print $2}')
STATE=$(echo "$INSTANCE_INFO" | awk '{print $3}')

echo "=== Instance Details ==="
echo "Instance ID: $INSTANCE_ID"
echo "Instance Name: $INSTANCE_NAME"
echo "Public IP: $PUBLIC_IP"
echo "Private IP: $PRIVATE_IP"
echo "State: $STATE"
echo ""

# SSH connection command
if [ "$PUBLIC_IP" != "None" ]; then
    echo -e "${GREEN}To connect via SSH:${NC}"
    echo "ssh -i ~/.ssh/${KEY_NAME}.pem ec2-user@${PUBLIC_IP}"
else
    echo -e "${YELLOW}No public IP assigned. Instance may be in a private subnet.${NC}"
fi

# Save instance details to file
OUTPUT_FILE="ec2-${INSTANCE_ID}.txt"
cat > "$OUTPUT_FILE" << EOF
EC2 Instance Details
====================
Instance ID: $INSTANCE_ID
Instance Name: $INSTANCE_NAME
Instance Type: $INSTANCE_TYPE
AMI ID: $AMI_ID
Public IP: $PUBLIC_IP
Private IP: $PRIVATE_IP
State: $STATE
Region: $REGION
Created: $(date)

SSH Command:
ssh -i ~/.ssh/${KEY_NAME}.pem ec2-user@${PUBLIC_IP}
EOF

echo -e "${GREEN}Instance details saved to: $OUTPUT_FILE${NC}"
