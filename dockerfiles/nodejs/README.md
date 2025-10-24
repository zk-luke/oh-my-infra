# Node.js Dockerfiles

This directory contains production-ready and development Dockerfiles for Node.js applications.

## Files

- `Dockerfile` - Production-optimized multi-stage build
- `Dockerfile.dev` - Development environment with hot-reloading
- `.dockerignore` - Files to exclude from Docker build context

## Production Dockerfile Features

- **Multi-stage build** for smaller final image
- **Node.js 20 Alpine** for minimal size (~150MB)
- **Security best practices**:
  - Non-root user (nodejs:nodejs)
  - dumb-init for proper signal handling
  - Only production dependencies
- **Health check** included
- **Optimized caching** with separate layer for dependencies

## Building Images

### Production Build
```bash
# Basic build
docker build -t myapp:latest -f Dockerfile .

# Build with custom port
docker build --build-arg PORT=8080 -t myapp:latest -f Dockerfile .

# Multi-platform build (ARM64 + AMD64)
docker buildx build --platform linux/amd64,linux/arm64 -t myapp:latest -f Dockerfile .
```

### Development Build
```bash
docker build -t myapp:dev -f Dockerfile.dev .
```

## Running Containers

### Production
```bash
# Run container
docker run -d \
  --name myapp \
  -p 3000:3000 \
  -e NODE_ENV=production \
  -e DATABASE_URL=postgresql://user:pass@host:5432/db \
  myapp:latest

# Run with volume mounts (for configs)
docker run -d \
  --name myapp \
  -p 3000:3000 \
  -v $(pwd)/config:/app/config:ro \
  myapp:latest
```

### Development
```bash
# Run with hot-reload and debugger
docker run -d \
  --name myapp-dev \
  -p 3000:3000 \
  -p 9229:9229 \
  -v $(pwd):/app \
  -v /app/node_modules \
  -e NODE_ENV=development \
  myapp:dev

# Attach to debug at chrome://inspect
```

## Application Requirements

Your Node.js application should:

1. Have a `package.json` with dependencies
2. Main entry point as `index.js` (or update CMD in Dockerfile)
3. Implement a `/health` endpoint for health checks:

```javascript
// Express example
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Raw HTTP example
const http = require('http');
http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok' }));
  }
}).listen(3000);
```

## Best Practices

### 1. Use .dockerignore
Always use `.dockerignore` to exclude unnecessary files and speed up builds.

### 2. Multi-stage Builds
Keep your production images small by using multi-stage builds.

### 3. Layer Caching
Copy `package.json` before source code to cache dependencies:
```dockerfile
COPY package*.json ./
RUN npm ci
COPY . .
```

### 4. Security
- Run as non-root user
- Scan images for vulnerabilities: `docker scan myapp:latest`
- Use specific version tags, not `latest`
- Keep base images updated

### 5. Environment Variables
Use environment variables for configuration:
```bash
docker run -e DATABASE_URL=... -e API_KEY=... myapp:latest
```

## Optimization Tips

### Reduce Image Size
```dockerfile
# Use alpine base images
FROM node:20-alpine

# Remove development dependencies in production
RUN npm ci --only=production

# Use npm ci instead of npm install (faster, more reliable)
```

### Improve Build Speed
```bash
# Use BuildKit for parallel builds
DOCKER_BUILDKIT=1 docker build -t myapp:latest .

# Cache dependencies in a separate layer
COPY package*.json ./
RUN npm ci
COPY . .
```

## Troubleshooting

### Container exits immediately
Check logs:
```bash
docker logs myapp
```

### Health check failing
Test health endpoint manually:
```bash
docker exec myapp curl http://localhost:3000/health
```

### Permission issues
Ensure files are owned by nodejs user:
```dockerfile
RUN chown -R nodejs:nodejs /app
USER nodejs
```

## Example Project Structure
```
myapp/
├── src/
│   ├── index.js
│   ├── routes/
│   └── controllers/
├── package.json
├── package-lock.json
├── Dockerfile
├── Dockerfile.dev
├── .dockerignore
└── docker-compose.yml
```

## Integration with Docker Compose

```yaml
version: '3.8'
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: production
      DATABASE_URL: postgresql://postgres:postgres@db:5432/myapp
    depends_on:
      - db
```
