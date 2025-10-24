# Go Dockerfiles

This directory contains production-ready and development Dockerfiles for Go applications.

## Files

- `Dockerfile` - Production-optimized multi-stage build (scratch base, ~5-10MB)
- `Dockerfile.alpine` - Production with Alpine base for additional tools (~15-20MB)
- `Dockerfile.dev` - Development environment with hot-reloading (Air)
- `.air.toml` - Configuration for Air hot-reloading
- `.dockerignore` - Files to exclude from Docker build context

## Production Dockerfile Features

### Dockerfile (Scratch-based)
- **Minimal size**: Final image ~5-10MB (only the binary)
- **Static binary**: No dependencies required
- **Secure**: No shell, minimal attack surface
- **Fast startup**: Immediate execution

### Dockerfile.alpine (Alpine-based)
- **Small size**: Final image ~15-20MB
- **Shell access**: For debugging and operations
- **Health checks**: Built-in wget for health checks
- **Non-root user**: Runs as appuser for security
- **Signal handling**: dumb-init for proper process management

## Building Images

### Production Build (Scratch)
```bash
# Basic build
docker build -t myapp:latest -f Dockerfile .

# With build args
docker build --build-arg VERSION=1.0.0 -t myapp:1.0.0 -f Dockerfile .

# Multi-platform build
docker buildx build --platform linux/amd64,linux/arm64 -t myapp:latest -f Dockerfile .
```

### Production Build (Alpine)
```bash
docker build -t myapp:alpine -f Dockerfile.alpine .
```

### Development Build
```bash
docker build -t myapp:dev -f Dockerfile.dev .
```

## Running Containers

### Production (Scratch)
```bash
docker run -d \
  --name myapp \
  -p 8080:8080 \
  -e DATABASE_URL=postgresql://user:pass@host:5432/db \
  -e REDIS_URL=redis://localhost:6379 \
  myapp:latest
```

### Production (Alpine)
```bash
docker run -d \
  --name myapp \
  -p 8080:8080 \
  --health-cmd="wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1" \
  --health-interval=30s \
  myapp:alpine

# Execute shell for debugging
docker exec -it myapp sh
```

### Development
```bash
# Run with hot-reload
docker run -d \
  --name myapp-dev \
  -p 8080:8080 \
  -p 2345:2345 \
  -v $(pwd):/app \
  myapp:dev

# View logs
docker logs -f myapp-dev
```

## Application Requirements

Your Go application should:

1. Have `go.mod` and `go.sum` files
2. Build a single binary
3. Implement a `/health` endpoint for health checks:

```go
package main

import (
    "encoding/json"
    "net/http"
)

func healthHandler(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusOK)
    json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

func main() {
    http.HandleFunc("/health", healthHandler)
    http.ListenAndServe(":8080", nil)
}
```

## Best Practices

### 1. Multi-stage Builds
Always use multi-stage builds to keep images small:
```dockerfile
FROM golang:1.21-alpine AS builder
# ... build steps ...
FROM scratch
COPY --from=builder /build/app /app
```

### 2. Static Binaries
Build static binaries for scratch images:
```dockerfile
CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .
```

### 3. Optimize Binary Size
Use linker flags to reduce size:
```dockerfile
go build -ldflags='-w -s' -o app .
# -w: Omit DWARF symbol table
# -s: Omit symbol table and debug info
```

### 4. Layer Caching
Copy go.mod before source code:
```dockerfile
COPY go.mod go.sum ./
RUN go mod download
COPY . .
```

### 5. Security
```dockerfile
# Use specific versions
FROM golang:1.21-alpine

# Run as non-root
USER appuser

# Scan for vulnerabilities
docker scan myapp:latest
```

## Development with Hot-Reload

The development Dockerfile includes [Air](https://github.com/cosmtrek/air) for automatic reloading:

1. Create `.air.toml` configuration (included)
2. Run development container:
```bash
docker run -v $(pwd):/app myapp:dev
```
3. Edit code - changes are automatically detected and rebuilt

## Size Comparison

| Base Image | Final Size | Use Case |
|------------|------------|----------|
| scratch | 5-10 MB | Production (minimal) |
| alpine | 15-20 MB | Production (with tools) |
| golang | 300+ MB | Development only |

## Building for Different Architectures

### AMD64 (x86_64)
```bash
docker build --platform linux/amd64 -t myapp:amd64 .
```

### ARM64 (Apple Silicon, AWS Graviton)
```bash
docker build --platform linux/arm64 -t myapp:arm64 .
```

### Multi-architecture
```bash
docker buildx create --use
docker buildx build --platform linux/amd64,linux/arm64 \
  -t myapp:latest --push .
```

## Integration with Docker Compose

```yaml
version: '3.8'
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.alpine
    ports:
      - "8080:8080"
    environment:
      DATABASE_URL: postgresql://postgres:postgres@db:5432/myapp
      REDIS_URL: redis://redis:6379
    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:8080/health"]
      interval: 30s
      timeout: 3s
      retries: 3
    depends_on:
      db:
        condition: service_healthy
```

## Troubleshooting

### Binary not found
Ensure your build command creates the binary in the expected location:
```dockerfile
RUN go build -o app .
```

### Permission denied
For Alpine builds, ensure proper ownership:
```dockerfile
RUN chown -R appuser:appuser /app
USER appuser
```

### Health check fails (scratch)
Scratch images can't run health check commands. Use Alpine or handle externally.

### CGO dependency issues
If your app requires CGO:
```dockerfile
# Use CGO_ENABLED=1 and include libc
FROM golang:1.21-alpine AS builder
RUN apk add --no-cache gcc musl-dev
RUN CGO_ENABLED=1 go build -o app .

FROM alpine:latest
# ... copy binary ...
```

## Example Project Structure

```
myapp/
├── cmd/
│   └── api/
│       └── main.go
├── internal/
│   ├── handler/
│   ├── model/
│   └── repository/
├── pkg/
│   └── utils/
├── go.mod
├── go.sum
├── Dockerfile
├── Dockerfile.alpine
├── Dockerfile.dev
├── .air.toml
├── .dockerignore
└── docker-compose.yml
```

## Performance Tips

### 1. Module caching
```dockerfile
COPY go.mod go.sum ./
RUN go mod download
# Changes to source won't invalidate this layer
```

### 2. Build cache
```bash
DOCKER_BUILDKIT=1 docker build --cache-from myapp:latest -t myapp:latest .
```

### 3. Parallel builds
```bash
DOCKER_BUILDKIT=1 docker build -t myapp:latest .
```

## Security Scanning

```bash
# Scan image for vulnerabilities
docker scan myapp:latest

# Use trivy
trivy image myapp:latest

# Use grype
grype myapp:latest
```
