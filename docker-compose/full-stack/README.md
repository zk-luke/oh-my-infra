# Full Stack Docker Compose Setup

This directory contains a complete Docker Compose configuration for a full-stack application with PostgreSQL and Redis.

## Features

- PostgreSQL 16 database
- Redis 7 cache
- Shared network for service communication
- Health checks for all services
- Ready for application integration
- Optional Nginx reverse proxy configuration

## Architecture

```
┌─────────────┐
│   Nginx     │ (Optional)
│   :80/:443  │
└──────┬──────┘
       │
┌──────▼──────┐
│ Application │
│    :3000    │
└──┬────────┬─┘
   │        │
   │        │
┌──▼────┐ ┌─▼──────┐
│Postgres│ │ Redis  │
│ :5432  │ │ :6379  │
└────────┘ └────────┘
```

## Quick Start

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` file with your configuration

3. Start the infrastructure services:
   ```bash
   docker-compose up -d postgres redis
   ```

4. Verify services are healthy:
   ```bash
   docker-compose ps
   ```

5. (Optional) Uncomment and configure the app service in `docker-compose.yml` for your application

## Service URLs

When services communicate within Docker Compose:
- **PostgreSQL**: `postgres:5432` (internal hostname)
- **Redis**: `redis:6379` (internal hostname)

From host machine:
- **PostgreSQL**: `localhost:5432`
- **Redis**: `localhost:6379`
- **Application**: `localhost:3000`

## Connection Strings

### For Application Container (Internal)
```bash
# PostgreSQL
DATABASE_URL=postgresql://postgres:postgres@postgres:5432/myapp

# Redis
REDIS_URL=redis://:redis@redis:6379
```

### For Development (External)
```bash
# PostgreSQL
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/myapp

# Redis
REDIS_URL=redis://:redis@localhost:6379
```

## Adding Your Application

1. Uncomment the `app` service in `docker-compose.yml`
2. Place your Dockerfile in `./app/Dockerfile`
3. Update environment variables as needed
4. Run:
   ```bash
   docker-compose up -d
   ```

## Useful Commands

```bash
# Start all services
docker-compose up -d

# Start specific services
docker-compose up -d postgres redis

# View logs
docker-compose logs -f

# View logs for specific service
docker-compose logs -f postgres

# Stop services
docker-compose down

# Stop and remove all data
docker-compose down -v

# Restart a service
docker-compose restart postgres

# Check service status
docker-compose ps

# Execute command in container
docker-compose exec postgres psql -U postgres
```

## Scaling Considerations

For production deployments, consider:
- Using managed database services (AWS RDS, ElastiCache)
- Implementing database replication
- Setting up Redis Sentinel or Cluster
- Using Docker Swarm or Kubernetes for orchestration
- Implementing proper backup strategies
- Setting resource limits

## Backup & Restore

### PostgreSQL Backup
```bash
docker-compose exec postgres pg_dump -U postgres myapp > backup.sql
```

### PostgreSQL Restore
```bash
docker-compose exec -T postgres psql -U postgres myapp < backup.sql
```

### Redis Backup
```bash
docker-compose exec redis redis-cli -a redis SAVE
docker cp app-redis:/data/dump.rdb ./redis-backup.rdb
```

## Monitoring

Add monitoring services by extending the compose file:
- Prometheus for metrics
- Grafana for visualization
- Loki for log aggregation
