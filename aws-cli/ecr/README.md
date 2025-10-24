# AWS ECR Management Scripts

This directory contains shell scripts for managing AWS Elastic Container Registry (ECR).

## Prerequisites

- AWS CLI installed and configured
- Docker installed and running
- Appropriate AWS credentials with ECR permissions

## Scripts

### 1. create-ecr-repo.sh
Create a new ECR repository with best practices configured.

**Usage:**
```bash
./create-ecr-repo.sh [repository-name] [region]
```

**Example:**
```bash
# Create with defaults
./create-ecr-repo.sh myapp

# Create in specific region
./create-ecr-repo.sh myapp us-west-2
```

**Features:**
- Creates repository with encryption
- Enables image scanning on push
- Sets lifecycle policy (keeps last 10 images)
- Provides login and push commands
- Saves repository details to file

### 2. delete-ecr-repo.sh
Delete an ECR repository and all its images.

**Usage:**
```bash
./delete-ecr-repo.sh [repository-name] [region]
```

**Example:**
```bash
# Delete repository
./delete-ecr-repo.sh myapp

# Delete in specific region
./delete-ecr-repo.sh myapp us-west-2
```

**Features:**
- Shows repository details before deletion
- Confirms before deleting
- Force deletes all images
- Logs deletions

### 3. push-to-ecr.sh
Push a Docker image to ECR.

**Usage:**
```bash
./push-to-ecr.sh [local-image:tag] [ecr-repo-name] [ecr-tag] [region]
```

**Example:**
```bash
# Push with default tag (latest)
./push-to-ecr.sh myapp:1.0.0 myapp-repo

# Push with custom ECR tag
./push-to-ecr.sh myapp:1.0.0 myapp-repo production

# Push in specific region
./push-to-ecr.sh myapp:1.0.0 myapp-repo v1.0.0 us-west-2
```

**Features:**
- Verifies local image exists
- Authenticates with ECR
- Tags and pushes image
- Shows image details after push
- Saves push information to file

### 4. list-ecr.sh
List ECR repositories and images.

**Usage:**
```bash
# List all repositories
./list-ecr.sh [region]

# List images in a specific repository
./list-ecr.sh [repository-name] [region]
```

**Example:**
```bash
# List all repositories
./list-ecr.sh

# List images in repository
./list-ecr.sh myapp

# List in specific region
./list-ecr.sh myapp us-west-2
```

**Features:**
- Shows all repositories or specific repository images
- Displays image tags, sizes, and push dates
- Shows image digests
- Provides pull commands

## Configuration

### Environment Variables

```bash
export AWS_REGION="us-east-1"
export AWS_PROFILE="default"
```

### Default Values

- **Region**: `us-east-1`
- **Image Tag**: `latest`
- **Encryption**: AES256
- **Scan on Push**: Enabled

## AWS Permissions Required

IAM permissions needed:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:CreateRepository",
        "ecr:DeleteRepository",
        "ecr:DescribeRepositories",
        "ecr:DescribeImages",
        "ecr:PutLifecyclePolicy",
        "ecr:ListImages"
      ],
      "Resource": "*"
    }
  ]
}
```

## Common Workflows

### 1. Create Repository and Push Image

```bash
# Step 1: Create ECR repository
./create-ecr-repo.sh myapp

# Step 2: Build your Docker image locally
docker build -t myapp:latest .

# Step 3: Push to ECR
./push-to-ecr.sh myapp:latest myapp latest
```

### 2. Update Existing Image

```bash
# Build new version
docker build -t myapp:2.0.0 .

# Push with version tag
./push-to-ecr.sh myapp:2.0.0 myapp 2.0.0

# Also tag as latest
./push-to-ecr.sh myapp:2.0.0 myapp latest
```

### 3. Pull Image from ECR

```bash
# Get login
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789012.dkr.ecr.us-east-1.amazonaws.com

# Pull image
docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
```

### 4. List and Clean Up

```bash
# List all repositories
./list-ecr.sh

# List images in a repository
./list-ecr.sh myapp

# Delete old repository
./delete-ecr-repo.sh old-app
```

## Best Practices

### 1. Image Tagging Strategy

Use semantic versioning and multiple tags:
```bash
# Tag with version
./push-to-ecr.sh myapp:1.2.3 myapp 1.2.3

# Tag with major.minor
./push-to-ecr.sh myapp:1.2.3 myapp 1.2

# Tag as latest
./push-to-ecr.sh myapp:1.2.3 myapp latest
```

### 2. Lifecycle Policies

The create script sets a policy to keep only the last 10 images. Customize if needed:

```bash
# Keep last 20 images
cat > lifecycle-policy.json << 'EOF'
{
  "rules": [{
    "rulePriority": 1,
    "description": "Keep last 20 images",
    "selection": {
      "tagStatus": "any",
      "countType": "imageCountMoreThan",
      "countNumber": 20
    },
    "action": {"type": "expire"}
  }]
}
EOF

aws ecr put-lifecycle-policy \
  --repository-name myapp \
  --lifecycle-policy-text file://lifecycle-policy.json
```

### 3. Image Scanning

Images are automatically scanned on push. View scan results:

```bash
aws ecr describe-image-scan-findings \
  --repository-name myapp \
  --image-id imageTag=latest
```

### 4. Repository Policies

Set repository policies for cross-account access:

```bash
cat > policy.json << 'EOF'
{
  "Version": "2008-10-17",
  "Statement": [{
    "Sid": "AllowPull",
    "Effect": "Allow",
    "Principal": {
      "AWS": "arn:aws:iam::123456789012:root"
    },
    "Action": [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
  }]
}
EOF

aws ecr set-repository-policy \
  --repository-name myapp \
  --policy-text file://policy.json
```

## Integration with CI/CD

### GitHub Actions

```yaml
name: Build and Push to ECR

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Login to ECR
        run: |
          aws ecr get-login-password --region us-east-1 | \
          docker login --username AWS --password-stdin \
          ${{ secrets.ECR_REGISTRY }}
      
      - name: Build and push
        run: |
          docker build -t myapp:${{ github.sha }} .
          ./aws-cli/ecr/push-to-ecr.sh myapp:${{ github.sha }} myapp ${{ github.sha }}
```

### GitLab CI

```yaml
deploy:
  stage: deploy
  image: docker:latest
  services:
    - docker:dind
  script:
    - apk add --no-cache aws-cli bash
    - ./aws-cli/ecr/push-to-ecr.sh myapp:$CI_COMMIT_SHA myapp $CI_COMMIT_SHA
  only:
    - main
```

## Costs and Limits

### Pricing (as of 2024)
- Storage: $0.10 per GB/month
- Data transfer: Free to same-region AWS services
- Private scanning: Included

### Limits
- 10,000 repositories per region (soft limit)
- 10,000 images per repository (soft limit)
- Image max size: 10 GB (hard limit)

## Troubleshooting

### Error: "no basic auth credentials"
Login to ECR:
```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789012.dkr.ecr.us-east-1.amazonaws.com
```

### Error: "denied: User is not authorized"
Check IAM permissions for ECR actions.

### Error: "repository does not exist"
Create repository first:
```bash
./create-ecr-repo.sh myapp
```

### Image push is slow
- Check internet connection
- Image may be large (optimize Docker layers)
- Use closer AWS region

## Security Best Practices

### 1. Use IAM Roles
Use IAM roles instead of access keys when possible (e.g., EC2, ECS, Lambda).

### 2. Enable Encryption
All repositories created by these scripts use AES256 encryption.

### 3. Enable Vulnerability Scanning
Scan images automatically:
```bash
aws ecr put-image-scanning-configuration \
  --repository-name myapp \
  --image-scanning-configuration scanOnPush=true
```

### 4. Use Least Privilege
Grant minimum required permissions to users and services.

### 5. Monitor Access
Enable CloudTrail logging:
```bash
aws cloudtrail create-trail \
  --name ecr-trail \
  --s3-bucket-name my-cloudtrail-bucket
```

## Make Scripts Executable

```bash
chmod +x *.sh
```

## Additional Resources

- [ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [ECR Image Scanning](https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-scanning.html)
