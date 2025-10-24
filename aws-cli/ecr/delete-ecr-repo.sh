#!/bin/bash

# Script to delete an ECR repository
# Usage: ./delete-ecr-repo.sh [repository-name]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default region
DEFAULT_REGION="us-east-1"
REGION="${AWS_REGION:-$DEFAULT_REGION}"

# Check if repository name is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Repository name is required${NC}"
    echo "Usage: $0 <repository-name> [region]"
    exit 1
fi

REPO_NAME="$1"
REGION="${2:-$REGION}"

echo -e "${YELLOW}Checking repository: $REPO_NAME${NC}"
echo "Region: $REGION"
echo ""

# Check if repository exists
REPO_INFO=$(aws ecr describe-repositories \
    --repository-names "$REPO_NAME" \
    --region "$REGION" \
    --query 'repositories[0].[repositoryName,repositoryUri,registryId]' \
    --output text 2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}Repository not found: $REPO_NAME${NC}"
    exit 1
fi

REPO_URI=$(echo "$REPO_INFO" | awk '{print $2}')
REGISTRY_ID=$(echo "$REPO_INFO" | awk '{print $3}')

# Get image count
IMAGE_COUNT=$(aws ecr describe-images \
    --repository-name "$REPO_NAME" \
    --region "$REGION" \
    --query 'length(imageDetails)' \
    --output text 2>/dev/null || echo "0")

echo "=== Repository Details ==="
echo "Repository Name: $REPO_NAME"
echo "Repository URI: $REPO_URI"
echo "Registry ID: $REGISTRY_ID"
echo "Image Count: $IMAGE_COUNT"
echo ""

# Confirm deletion
read -p "$(echo -e ${RED}Are you sure you want to delete this repository and all its images? [y/N]: ${NC})" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Deletion cancelled${NC}"
    exit 0
fi

# Delete repository (force delete to remove all images)
echo ""
echo -e "${YELLOW}Deleting repository...${NC}"

aws ecr delete-repository \
    --repository-name "$REPO_NAME" \
    --region "$REGION" \
    --force \
    --output json > /dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Repository deleted successfully!${NC}"
    echo "Repository: $REPO_NAME"
    echo "Images deleted: $IMAGE_COUNT"
    
    # Log deletion
    LOG_FILE="ecr-deletions.log"
    echo "$(date): Deleted repository $REPO_NAME ($REPO_URI) with $IMAGE_COUNT images" >> "$LOG_FILE"
    echo -e "${GREEN}Deletion logged to: $LOG_FILE${NC}"
else
    echo -e "${RED}Failed to delete repository${NC}"
    exit 1
fi
