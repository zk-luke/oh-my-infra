# oh-my-infra

A comprehensive collection of infrastructure configuration files, Docker setups, and AWS automation scripts for modern DevOps workflows.

## 📁 Repository Structure

```
oh-my-infra/
├── docker-compose/          # Ready-to-use Docker Compose configurations
│   ├── postgres/           # PostgreSQL with pgAdmin
│   ├── redis/              # Redis with Redis Commander
│   └── full-stack/         # Complete stack (PostgreSQL + Redis + App)
├── dockerfiles/            # Production and development Dockerfiles
│   ├── nodejs/            # Node.js application Dockerfiles
│   └── golang/            # Go application Dockerfiles
├── aws-cli/               # AWS CLI automation scripts
│   ├── ec2/              # EC2 instance management
│   └── ecr/              # Elastic Container Registry management
└── scripts/              # Additional utility scripts
```

## 🚀 Quick Start

### Docker Compose Services

#### PostgreSQL
```bash
cd docker-compose/postgres
cp .env.example .env
docker-compose up -d
# Access: PostgreSQL at localhost:5432, pgAdmin at localhost:5050
```

#### Redis
```bash
cd docker-compose/redis
cp .env.example .env
docker-compose up -d
# Access: Redis at localhost:6379, Redis Commander at localhost:8081
```

#### Full Stack
```bash
cd docker-compose/full-stack
cp .env.example .env
docker-compose up -d postgres redis
# Ready for your application
```

### Building Docker Images

#### Node.js Application
```bash
# Production
docker build -t myapp:latest -f dockerfiles/nodejs/Dockerfile .

# Development with hot-reload
docker build -t myapp:dev -f dockerfiles/nodejs/Dockerfile.dev .
```

#### Go Application
```bash
# Production (minimal ~5-10MB)
docker build -t myapp:latest -f dockerfiles/golang/Dockerfile .

# Production with tools (~15-20MB)
docker build -t myapp:alpine -f dockerfiles/golang/Dockerfile.alpine .

# Development with hot-reload
docker build -t myapp:dev -f dockerfiles/golang/Dockerfile.dev .
```

### AWS CLI Scripts

#### EC2 Management
```bash
# Create instance
./aws-cli/ec2/create-ec2.sh my-server t3.micro

# List instances
./aws-cli/ec2/list-ec2.sh

# Start/stop/reboot
./aws-cli/ec2/manage-ec2.sh start my-server

# Run script on instance
./aws-cli/ec2/run-script-on-ec2.sh my-server setup.sh

# Delete instance
./aws-cli/ec2/delete-ec2.sh my-server
```

#### ECR Management
```bash
# Create repository
./aws-cli/ecr/create-ecr-repo.sh myapp

# Push image
./aws-cli/ecr/push-to-ecr.sh myapp:latest myapp latest

# List repositories and images
./aws-cli/ecr/list-ecr.sh
./aws-cli/ecr/list-ecr.sh myapp

# Delete repository
./aws-cli/ecr/delete-ecr-repo.sh myapp
```

## 📚 Documentation

Each directory contains detailed README files with:
- Complete usage instructions
- Configuration options
- Best practices
- Troubleshooting guides
- Real-world examples

### Directory-Specific Documentation
- [Docker Compose - PostgreSQL](docker-compose/postgres/README.md)
- [Docker Compose - Redis](docker-compose/redis/README.md)
- [Docker Compose - Full Stack](docker-compose/full-stack/README.md)
- [Dockerfiles - Node.js](dockerfiles/nodejs/README.md)
- [Dockerfiles - Golang](dockerfiles/golang/README.md)
- [AWS CLI - EC2 Management](aws-cli/ec2/README.md)
- [AWS CLI - ECR Management](aws-cli/ecr/README.md)

## 🛠️ Prerequisites

### For Docker Compose
- Docker Engine 20.10+
- Docker Compose v2.0+

### For Dockerfiles
- Docker Engine 20.10+
- Application source code (Node.js or Go)

### For AWS CLI Scripts
- AWS CLI v2
- Configured AWS credentials (`aws configure`)
- Appropriate IAM permissions
- For EC2 SSH: SSH key pairs
- For ECR: Docker installed

## 🔧 Configuration

### Docker Compose
Each Docker Compose setup includes:
- `.env.example` - Copy to `.env` and customize
- Environment variable configuration
- Volume persistence
- Health checks
- Network isolation

### Dockerfiles
- Production builds optimized for size and security
- Development builds with hot-reloading
- Multi-stage builds
- Non-root user execution
- `.dockerignore` for faster builds

### AWS Scripts
Configure using environment variables:
```bash
export AWS_REGION="us-east-1"
export AWS_PROFILE="default"
```

## 💡 Features

### Docker Compose
- ✅ Production-ready configurations
- ✅ Management UIs included (pgAdmin, Redis Commander)
- ✅ Persistent data volumes
- ✅ Health checks
- ✅ Easy customization via environment variables
- ✅ Network isolation

### Dockerfiles
- ✅ Multi-stage builds for minimal image size
- ✅ Security best practices (non-root users)
- ✅ Development and production variants
- ✅ Hot-reloading for development
- ✅ Health check configurations
- ✅ Optimized layer caching

### AWS CLI Scripts
- ✅ Color-coded output for better readability
- ✅ Interactive confirmations for destructive operations
- ✅ Detailed logging and output files
- ✅ Support for instance names and IDs
- ✅ Comprehensive error handling
- ✅ Cross-region support

## 📝 Best Practices

### Docker
1. **Use specific tags** - Don't rely on `latest` in production
2. **Multi-stage builds** - Keep production images small
3. **Layer caching** - Order Dockerfile commands for optimal caching
4. **Health checks** - Always implement health endpoints
5. **Security** - Run as non-root, scan for vulnerabilities

### AWS
1. **Name everything** - Use meaningful names for resources
2. **Tags** - Tag all resources for organization and cost tracking
3. **IAM roles** - Use IAM roles instead of access keys when possible
4. **Security groups** - Create specific security groups, don't use default
5. **Cost optimization** - Stop instances when not needed

### General
1. **Documentation** - Keep README files updated
2. **Environment variables** - Never commit secrets
3. **Version control** - Track all infrastructure as code
4. **Testing** - Test configurations before production
5. **Backups** - Regular backups of data and configurations

## 🔐 Security

### Docker
- All Dockerfiles run as non-root users
- Images use minimal base images (Alpine, scratch)
- Regular security updates recommended
- Use `docker scan` to check for vulnerabilities

### AWS
- Scripts prompt for confirmation on destructive actions
- Use IAM roles and least privilege principles
- Enable CloudTrail for audit logging
- ECR images scanned on push
- Encrypted ECR repositories by default

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test your changes
4. Submit a pull request

## 📄 License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file.

## 🆘 Support

For issues and questions:
1. Check the relevant README in each directory
2. Review troubleshooting sections
3. Open an issue on GitHub

## 🔄 Updates

This repository is actively maintained. Check back for:
- New Docker Compose configurations
- Additional Dockerfiles for other languages
- More AWS automation scripts
- Updated best practices

## 📖 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [PostgreSQL Docker Hub](https://hub.docker.com/_/postgres)
- [Redis Docker Hub](https://hub.docker.com/_/redis)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [Go Best Practices](https://go.dev/doc/effective_go)

---

**Happy Infrastructure Building! 🚀**
