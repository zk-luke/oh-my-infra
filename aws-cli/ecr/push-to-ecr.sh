#!/bin/bash

# Script to push a Docker image to ECR
# Usage: ./push-to-ecr.sh [local-image:tag] [ecr-repo-name] [ecr-tag]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
DEFAULT_REGION="us-east-1"
DEFAULT_TAG="latest"
REGION="${AWS_REGION:-$DEFAULT_REGION}"

# Check arguments
if [ -z "$1" ] || [ -z "$2" ]; then
    echo -e "${RED}Error: Image name and ECR repository are required${NC}"
    echo "Usage: $0 <local-image:tag> <ecr-repo-name> [ecr-tag] [region]"
    echo ""
    echo "Example:"
    echo "  $0 myapp:latest my-ecr-repo latest us-east-1"
    exit 1
fi

LOCAL_IMAGE="$1"
REPO_NAME="$2"
ECR_TAG="${3:-$DEFAULT_TAG}"
REGION="${4:-$REGION}"

echo -e "${GREEN}Pushing image to ECR...${NC}"
echo "Local Image: $LOCAL_IMAGE"
echo "ECR Repository: $REPO_NAME"
echo "ECR Tag: $ECR_TAG"
echo "Region: $REGION"
echo ""

# Verify local image exists
if ! docker images "$LOCAL_IMAGE" | grep -q "$LOCAL_IMAGE"; then
    echo -e "${RED}Local image not found: $LOCAL_IMAGE${NC}"
    echo "Available images:"
    docker images
    exit 1
fi

echo -e "${GREEN}Local image found${NC}"
echo ""

# Get ECR repository URI
echo -e "${YELLOW}Getting ECR repository details...${NC}"
REPO_URI=$(aws ecr describe-repositories \
    --repository-names "$REPO_NAME" \
    --region "$REGION" \
    --query 'repositories[0].repositoryUri' \
    --output text 2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}ECR repository not found: $REPO_NAME${NC}"
    echo "Create it first with: ./create-ecr-repo.sh $REPO_NAME"
    exit 1
fi

echo "Repository URI: $REPO_URI"
echo ""

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_ENDPOINT="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# Login to ECR
echo -e "${YELLOW}Logging in to ECR...${NC}"
aws ecr get-login-password --region "$REGION" | \
    docker login --username AWS --password-stdin "$ECR_ENDPOINT"

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to login to ECR${NC}"
    exit 1
fi

echo -e "${GREEN}Successfully logged in to ECR${NC}"
echo ""

# Tag image for ECR
ECR_IMAGE="${REPO_URI}:${ECR_TAG}"
echo -e "${YELLOW}Tagging image...${NC}"
echo "Target: $ECR_IMAGE"

docker tag "$LOCAL_IMAGE" "$ECR_IMAGE"

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to tag image${NC}"
    exit 1
fi

echo -e "${GREEN}Image tagged successfully${NC}"
echo ""

# Push to ECR
echo -e "${YELLOW}Pushing image to ECR...${NC}"
docker push "$ECR_IMAGE"

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to push image${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Image pushed successfully!${NC}"
echo ""

# Get image details
echo -e "${GREEN}=== Image Details ===${NC}"
IMAGE_DETAILS=$(aws ecr describe-images \
    --repository-name "$REPO_NAME" \
    --image-ids imageTag="$ECR_TAG" \
    --region "$REGION" \
    --query 'imageDetails[0].[imagePushedAt,imageSizeInBytes,imageDigest]' \
    --output text)

PUSHED_AT=$(echo "$IMAGE_DETAILS" | awk '{print $1}')
SIZE_BYTES=$(echo "$IMAGE_DETAILS" | awk '{print $2}')
DIGEST=$(echo "$IMAGE_DETAILS" | awk '{print $3}')
SIZE_MB=$(echo "scale=2; $SIZE_BYTES / 1024 / 1024" | bc)

echo "Image: $ECR_IMAGE"
echo "Digest: $DIGEST"
echo "Size: ${SIZE_MB} MB"
echo "Pushed At: $PUSHED_AT"
echo ""

# Show pull command
echo -e "${GREEN}=== Pull Command ===${NC}"
echo "docker pull $ECR_IMAGE"
echo ""

# Save push info
OUTPUT_FILE="ecr-push-${REPO_NAME}-${ECR_TAG}.txt"
cat > "$OUTPUT_FILE" << EOF
ECR Push Details
================
Local Image: $LOCAL_IMAGE
ECR Image: $ECR_IMAGE
Repository: $REPO_NAME
Tag: $ECR_TAG
Region: $REGION
Size: ${SIZE_MB} MB
Digest: $DIGEST
Pushed At: $PUSHED_AT

Pull Command:
docker pull $ECR_IMAGE
EOF

echo -e "${GREEN}Push details saved to: $OUTPUT_FILE${NC}"
