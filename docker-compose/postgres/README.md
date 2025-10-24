# PostgreSQL Docker Compose Setup

This directory contains a Docker Compose configuration for running PostgreSQL with pgAdmin.

## Features

- PostgreSQL 16 (Alpine-based for smaller image size)
- pgAdmin 4 for database management UI
- Persistent data volumes
- Health checks
- Configurable via environment variables
- Initialization scripts support

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

- **PostgreSQL**: `localhost:5432` (or custom port from .env)
- **pgAdmin**: `http://localhost:5050` (or custom port from .env)

## Default Credentials

### PostgreSQL
- User: `postgres`
- Password: `postgres`
- Database: `myapp`

### pgAdmin
- Email: `admin@admin.com`
- Password: `admin`

## Initialization Scripts

Place SQL scripts in `./init-scripts/` directory. They will be executed in alphabetical order when the container is first created.

Example:
```bash
mkdir init-scripts
echo "CREATE TABLE users (id SERIAL PRIMARY KEY, name VARCHAR(100));" > init-scripts/01-create-tables.sql
```

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

# Connect to PostgreSQL via CLI
docker-compose exec postgres psql -U postgres -d myapp

# Backup database
docker-compose exec postgres pg_dump -U postgres myapp > backup.sql

# Restore database
docker-compose exec -T postgres psql -U postgres myapp < backup.sql
```

## Connecting from Application

Use the following connection string format:
```
postgresql://postgres:postgres@localhost:5432/myapp
```

Or configure your application with:
- Host: `localhost`
- Port: `5432`
- Database: `myapp`
- User: `postgres`
- Password: `postgres`
