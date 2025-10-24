# AWS EC2 Management Scripts

This directory contains shell scripts for managing AWS EC2 instances.

## Prerequisites

- AWS CLI installed and configured
- Appropriate AWS credentials with EC2 permissions
- For SSH operations: SSH key pair configured in AWS

## Scripts

### 1. create-ec2.sh
Create a new EC2 instance with custom configuration.

**Usage:**
```bash
./create-ec2.sh [instance-name] [instance-type] [ami-id] [key-name] [security-group]
```

**Example:**
```bash
# Create with defaults
./create-ec2.sh my-server

# Create with custom type
./create-ec2.sh my-server t3.small

# Create with all parameters
./create-ec2.sh my-server t3.medium ami-0c55b159cbfafe1f0 my-keypair my-security-group
```

**Features:**
- Creates instance with specified configuration
- Waits for instance to be running
- Displays connection details
- Saves instance info to file

### 2. delete-ec2.sh
Terminate an EC2 instance by ID or name.

**Usage:**
```bash
./delete-ec2.sh [instance-id-or-name] [region]
```

**Example:**
```bash
# Delete by instance ID
./delete-ec2.sh i-1234567890abcdef0

# Delete by name
./delete-ec2.sh my-server

# Delete in specific region
./delete-ec2.sh my-server us-west-2
```

**Features:**
- Finds instance by ID or name tag
- Shows instance details before deletion
- Confirms before terminating
- Logs deletions

### 3. list-ec2.sh
List all EC2 instances with detailed information.

**Usage:**
```bash
./list-ec2.sh [region]
```

**Example:**
```bash
# List in default region
./list-ec2.sh

# List in specific region
./list-ec2.sh us-west-2
```

**Features:**
- Shows all instances in tabular format
- Color-coded by state (green=running, red=stopped)
- Shows count by state
- Displays IP addresses and launch time

### 4. manage-ec2.sh
Start, stop, reboot, or check status of EC2 instances.

**Usage:**
```bash
./manage-ec2.sh [action] [instance-id-or-name] [region]
```

**Actions:**
- `start` - Start a stopped instance
- `stop` - Stop a running instance
- `reboot` - Reboot a running instance
- `status` - Get detailed instance status

**Example:**
```bash
# Start an instance
./manage-ec2.sh start my-server

# Stop an instance
./manage-ec2.sh stop i-1234567890abcdef0

# Reboot an instance
./manage-ec2.sh reboot my-server

# Get instance status
./manage-ec2.sh status my-server
```

### 5. run-script-on-ec2.sh
Execute a shell script on a remote EC2 instance via SSH.

**Usage:**
```bash
./run-script-on-ec2.sh [instance-id-or-name] [script-file] [key-file] [region] [user]
```

**Example:**
```bash
# Run script with default key
./run-script-on-ec2.sh my-server setup.sh

# Run with custom key
./run-script-on-ec2.sh my-server deploy.sh ~/.ssh/my-key.pem

# Run with custom user
./run-script-on-ec2.sh my-server update.sh ~/.ssh/my-key.pem us-east-1 ubuntu
```

**Features:**
- Copies script to remote instance
- Executes script and shows output
- Cleans up after execution
- Returns exit code from script

## Configuration

### Environment Variables

Set these in your shell or in a `.env` file:

```bash
export AWS_REGION="us-east-1"
export AWS_PROFILE="default"
```

### Default Values

Scripts use these defaults if not specified:
- **Region**: `us-east-1`
- **Instance Type**: `t3.micro`
- **Key Name**: `my-key-pair`
- **Security Group**: `default`
- **AMI ID**: Amazon Linux 2 (varies by region)
- **SSH User**: `ec2-user`

## AWS Permissions Required

IAM permissions needed for these scripts:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:RebootInstances",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:CreateTags"
      ],
      "Resource": "*"
    }
  ]
}
```

## Common AMI IDs by Region

Update these based on your needs:

| Region | Amazon Linux 2 | Ubuntu 22.04 |
|--------|----------------|--------------|
| us-east-1 | ami-0c55b159cbfafe1f0 | ami-0557a15b87f6559cf |
| us-west-2 | ami-0d1cd67c26f5fca19 | ami-0fcf52bcf5db7b003 |
| eu-west-1 | ami-0d71ea30463e0ff8d | ami-0905a3c97561e0b69 |

## SSH Configuration

### Setting Up SSH Keys

1. Create a key pair in AWS:
```bash
aws ec2 create-key-pair --key-name my-key-pair --query 'KeyMaterial' --output text > ~/.ssh/my-key-pair.pem
chmod 400 ~/.ssh/my-key-pair.pem
```

2. Use the key with instances:
```bash
ssh -i ~/.ssh/my-key-pair.pem ec2-user@<instance-ip>
```

### Default Users by OS

- Amazon Linux: `ec2-user`
- Ubuntu: `ubuntu`
- Red Hat: `ec2-user`
- Debian: `admin`

## Tips and Best Practices

### 1. Use Name Tags
Always name your instances for easier management:
```bash
./create-ec2.sh meaningful-name
```

### 2. Choose Right Instance Type
- Development: `t3.micro` or `t3.small`
- Production: `t3.medium` or larger
- Compute-intensive: `c5` family
- Memory-intensive: `r5` family

### 3. Security Groups
Create custom security groups instead of using `default`:
```bash
aws ec2 create-security-group --group-name my-app-sg --description "My App Security Group"
aws ec2 authorize-security-group-ingress --group-name my-app-sg --protocol tcp --port 22 --cidr 0.0.0.0/0
```

### 4. Cost Optimization
- Stop instances when not in use
- Use spot instances for non-critical workloads
- Set up billing alerts

### 5. Backups
Create AMIs of important instances:
```bash
aws ec2 create-image --instance-id i-1234567890abcdef0 --name "my-backup-$(date +%Y%m%d)"
```

## Troubleshooting

### Permission Denied (SSH)
```bash
chmod 400 ~/.ssh/my-key-pair.pem
```

### Cannot Connect via SSH
- Check security group allows inbound SSH (port 22)
- Verify instance has public IP
- Ensure key pair matches

### Script Not Executable
```bash
chmod +x *.sh
```

### AWS CLI Not Found
Install AWS CLI:
```bash
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

## Examples

### Complete Workflow

```bash
# 1. Create an instance
./create-ec2.sh web-server t3.small

# 2. Check status
./list-ec2.sh

# 3. Run a setup script
cat > setup.sh << 'EOF'
#!/bin/bash
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
EOF
./run-script-on-ec2.sh web-server setup.sh

# 4. Stop when not in use
./manage-ec2.sh stop web-server

# 5. Start when needed
./manage-ec2.sh start web-server

# 6. Delete when done
./delete-ec2.sh web-server
```

## Logging

Scripts create log files:
- `ec2-deletions.log` - Tracks instance terminations
- `ec2-[instance-id].txt` - Instance creation details

## Make Scripts Executable

```bash
chmod +x *.sh
```
