#!/bin/bash

# Script to list ECR repositories and images
# Usage: ./list-ecr.sh [repository-name]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default region
DEFAULT_REGION="us-east-1"
REGION="${AWS_REGION:-$DEFAULT_REGION}"

REPO_NAME="${1}"
REGION="${2:-$REGION}"

if [ -z "$REPO_NAME" ]; then
    # List all repositories
    echo -e "${GREEN}=== ECR Repositories in $REGION ===${NC}"
    echo ""
    
    aws ecr describe-repositories \
        --region "$REGION" \
        --query 'repositories[*].[repositoryName,repositoryUri,createdAt]' \
        --output text | \
        awk -v green="$GREEN" -v nc="$NC" \
        'BEGIN {
            printf "%-40s %-80s %-25s\n", "REPOSITORY NAME", "REPOSITORY URI", "CREATED AT"
            printf "%s\n", "================================================================================================================================"
        }
        {
            printf "%-40s %-80s %-25s\n", $1, $2, $3
        }'
    
    echo ""
    REPO_COUNT=$(aws ecr describe-repositories --region "$REGION" --query 'length(repositories)' --output text)
    echo -e "${BLUE}Total repositories: $REPO_COUNT${NC}"
    echo ""
    
    # Show total images across all repositories
    echo -e "${GREEN}=== Image Count by Repository ===${NC}"
    aws ecr describe-repositories \
        --region "$REGION" \
        --query 'repositories[*].repositoryName' \
        --output text | tr '\t' '\n' | while read repo; do
        
        IMAGE_COUNT=$(aws ecr describe-images \
            --repository-name "$repo" \
            --region "$REGION" \
            --query 'length(imageDetails)' \
            --output text 2>/dev/null || echo "0")
        
        printf "${YELLOW}%-40s${NC}: %d images\n" "$repo" "$IMAGE_COUNT"
    done
    
else
    # List images in specific repository
    echo -e "${GREEN}=== Images in $REPO_NAME ===${NC}"
    echo ""
    
    # Check if repository exists
    aws ecr describe-repositories \
        --repository-names "$REPO_NAME" \
        --region "$REGION" \
        --output text > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Repository not found: $REPO_NAME${NC}"
        exit 1
    fi
    
    # Get repository URI
    REPO_URI=$(aws ecr describe-repositories \
        --repository-names "$REPO_NAME" \
        --region "$REGION" \
        --query 'repositories[0].repositoryUri' \
        --output text)
    
    echo "Repository URI: $REPO_URI"
    echo ""
    
    # List images
    aws ecr describe-images \
        --repository-name "$REPO_NAME" \
        --region "$REGION" \
        --query 'sort_by(imageDetails,& imagePushedAt)[*].[imageTags[0],imagePushedAt,imageSizeInBytes,imageDigest]' \
        --output text | \
        awk -v green="$GREEN" -v nc="$NC" \
        'BEGIN {
            printf "%-20s %-30s %-15s %-70s\n", "TAG", "PUSHED AT", "SIZE (MB)", "DIGEST"
            printf "%s\n", "================================================================================================================================"
        }
        {
            tag = ($1 == "None" || $1 == "") ? "<untagged>" : $1
            size_mb = sprintf("%.2f", $3 / 1024 / 1024)
            digest_short = substr($4, 8, 12)  # Show first 12 chars after "sha256:"
            printf "%-20s %-30s %-15s sha256:%s...\n", tag, $2, size_mb, digest_short
        }'
    
    echo ""
    IMAGE_COUNT=$(aws ecr describe-images --repository-name "$REPO_NAME" --region "$REGION" --query 'length(imageDetails)' --output text)
    echo -e "${BLUE}Total images: $IMAGE_COUNT${NC}"
    echo ""
    
    # Show pull command
    echo -e "${GREEN}=== Pull Command ===${NC}"
    echo "docker pull ${REPO_URI}:latest"
    echo ""
fi
