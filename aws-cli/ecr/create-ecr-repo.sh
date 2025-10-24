#!/bin/bash

# Script to create an ECR repository
# Usage: ./create-ecr-repo.sh [repository-name]

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

echo -e "${GREEN}Creating ECR repository...${NC}"
echo "Repository Name: $REPO_NAME"
echo "Region: $REGION"
echo ""

# Create repository
REPO_URI=$(aws ecr create-repository \
    --repository-name "$REPO_NAME" \
    --region "$REGION" \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration encryptionType=AES256 \
    --query 'repository.repositoryUri' \
    --output text 2>&1)

if [ $? -ne 0 ]; then
    if echo "$REPO_URI" | grep -q "RepositoryAlreadyExistsException"; then
        echo -e "${YELLOW}Repository already exists: $REPO_NAME${NC}"
        # Get existing repository URI
        REPO_URI=$(aws ecr describe-repositories \
            --repository-names "$REPO_NAME" \
            --region "$REGION" \
            --query 'repositories[0].repositoryUri' \
            --output text)
    else
        echo -e "${RED}Failed to create repository${NC}"
        echo "$REPO_URI"
        exit 1
    fi
else
    echo -e "${GREEN}Repository created successfully!${NC}"
fi

echo ""
echo "=== Repository Details ==="
echo "Repository Name: $REPO_NAME"
echo "Repository URI: $REPO_URI"
echo ""

# Set lifecycle policy to limit number of images
echo -e "${YELLOW}Setting lifecycle policy...${NC}"
cat > /tmp/lifecycle-policy.json << 'EOF'
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 10 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF

aws ecr put-lifecycle-policy \
    --repository-name "$REPO_NAME" \
    --region "$REGION" \
    --lifecycle-policy-text file:///tmp/lifecycle-policy.json \
    --output json > /dev/null

echo -e "${GREEN}Lifecycle policy set successfully${NC}"
echo ""

# Get login command
echo -e "${GREEN}=== Docker Login Command ===${NC}"
echo "Run this command to login to ECR:"
echo ""
echo "aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REPO_URI"
echo ""

# Show push commands
echo -e "${GREEN}=== Push Image to ECR ===${NC}"
echo "1. Tag your image:"
echo "   docker tag myimage:latest $REPO_URI:latest"
echo ""
echo "2. Push to ECR:"
echo "   docker push $REPO_URI:latest"
echo ""

# Save repository info
OUTPUT_FILE="ecr-${REPO_NAME}.txt"
cat > "$OUTPUT_FILE" << EOF
ECR Repository Details
======================
Repository Name: $REPO_NAME
Repository URI: $REPO_URI
Region: $REGION
Created: $(date)

Docker Login:
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REPO_URI

Tag and Push:
docker tag myimage:latest $REPO_URI:latest
docker push $REPO_URI:latest

Pull Image:
docker pull $REPO_URI:latest
EOF

echo -e "${GREEN}Repository details saved to: $OUTPUT_FILE${NC}"

# Cleanup
rm -f /tmp/lifecycle-policy.json
