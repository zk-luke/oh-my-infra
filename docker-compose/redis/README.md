# Redis Docker Compose Setup

This directory contains a Docker Compose configuration for running Redis with Redis Commander.

## Features

- Redis 7 (Alpine-based for smaller image size)
- Redis Commander for Redis management UI
- Persistent data with AOF (Append Only File)
- Password protection
- Health checks
- Configurable via environment variables
- Custom Redis configuration support

## Quick Start

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` file with your desired configuration

3. Start the services:
   ```bash
   docker-compose up -d
   ```

4. Check the status:
   ```bash
   docker-compose ps
   ```

## Accessing Services

- **Redis**: `localhost:6379` (or custom port from .env)
- **Redis Commander**: `http://localhost:8081` (or custom port from .env)

## Default Credentials

### Redis
- Password: `redis`

### Redis Commander
- Username: `admin`
- Password: `admin`

## Configuration

The `redis.conf` file contains Redis configuration. You can modify it to customize Redis behavior.

Key settings:
- Persistence: RDB snapshots + AOF enabled
- Memory policy: `allkeys-lru` (evict least recently used keys)
- Password: Set via command line (can also be set in redis.conf)

## Useful Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# Stop and remove volumes (WARNING: deletes all data)
docker-compose down -v

# Connect to Redis CLI
docker-compose exec redis redis-cli -a redis

# Monitor Redis commands in real-time
docker-compose exec redis redis-cli -a redis MONITOR

# Get Redis info
docker-compose exec redis redis-cli -a redis INFO

# Check memory usage
docker-compose exec redis redis-cli -a redis INFO memory

# Flush all data (WARNING: deletes all data)
docker-compose exec redis redis-cli -a redis FLUSHALL
```

## Connecting from Application

### Node.js Example
```javascript
const redis = require('redis');
const client = redis.createClient({
  host: 'localhost',
  port: 6379,
  password: 'redis'
});
```

### Python Example
```python
import redis
r = redis.Redis(
  host='localhost',
  port=6379,
  password='redis',
  decode_responses=True
)
```

### Go Example
```go
import "github.com/go-redis/redis/v8"

rdb := redis.NewClient(&redis.Options{
    Addr:     "localhost:6379",
    Password: "redis",
    DB:       0,
})
```

## Data Persistence

Redis is configured with both RDB and AOF persistence:

- **RDB**: Snapshots taken at intervals (every 60s if 10000 keys changed)
- **AOF**: Every write operation is logged (appendfsync everysec)

This provides a good balance between performance and data safety.
