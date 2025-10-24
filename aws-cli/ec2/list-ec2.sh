#!/bin/bash

# Script to list EC2 instances with detailed information
# Usage: ./list-ec2.sh [region]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default region
DEFAULT_REGION="us-east-1"
REGION="${1:-${AWS_REGION:-$DEFAULT_REGION}}"

echo -e "${GREEN}=== EC2 Instances in $REGION ===${NC}"
echo ""

# Get all instances
aws ec2 describe-instances \
    --region "$REGION" \
    --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],InstanceType,State.Name,PublicIpAddress,PrivateIpAddress,LaunchTime]' \
    --output text | \
    awk -v blue="$BLUE" -v green="$GREEN" -v yellow="$YELLOW" -v red="$RED" -v nc="$NC" \
    'BEGIN {
        printf "%-20s %-30s %-15s %-12s %-16s %-16s %-20s\n", 
        "INSTANCE ID", "NAME", "TYPE", "STATE", "PUBLIC IP", "PRIVATE IP", "LAUNCH TIME"
        printf "%s\n", "================================================================================================================================"
    }
    {
        state = $4
        color = nc
        if (state == "running") color = green
        else if (state == "stopped") color = red
        else if (state == "stopping" || state == "pending") color = yellow
        
        printf "%-20s %-30s %-15s %s%-12s%s %-16s %-16s %-20s\n", 
        $1, ($2 ? $2 : "N/A"), $3, color, state, nc, ($5 ? $5 : "N/A"), ($6 ? $6 : "N/A"), $7
    }'

echo ""
echo -e "${BLUE}Total instances: $(aws ec2 describe-instances --region "$REGION" --query 'length(Reservations[*].Instances[*])' --output text)${NC}"
echo ""

# Count by state
echo -e "${GREEN}=== Instance Count by State ===${NC}"
aws ec2 describe-instances \
    --region "$REGION" \
    --query 'Reservations[*].Instances[*].State.Name' \
    --output text | tr '\t' '\n' | sort | uniq -c | \
    awk '{printf "%s%-12s%s: %d\n", "'$YELLOW'", $2, "'$NC'", $1}'
