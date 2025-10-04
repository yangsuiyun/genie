# 🐳 Docker Compose Guide for Pomodoro Genie

This guide helps you set up and manage the Docker Compose environment for the Pomodoro Genie application.

## Quick Setup

### 1. Fix Docker Permissions (if needed)

```bash
# Add your user to docker group
sudo usermod -aG docker $USER

# Apply changes (logout/login or run this)
newgrp docker

# Test Docker without sudo
docker ps
```

### 2. Run Setup Script

```bash
# Make setup script executable and run it
chmod +x setup-docker.sh
./setup-docker.sh
```

This script will:
- ✅ Check Docker and Docker Compose installation
- ✅ Create `.env` file with secure generated values
- ✅ Create database migration file if missing
- ✅ Pull Docker images
- ✅ Start all Supabase services
- ✅ Verify services are running

## Manual Setup (Alternative)

### 1. Create Environment File

```bash
# Copy and customize environment variables
cp .env.example .env

# Edit with your preferred values
nano .env
```

### 2. Start Services

```bash
# Start all services in background
docker-compose up -d

# View logs
docker-compose logs -f

# Check status
docker-compose ps
```

## Service Management

### Starting Services

```bash
# Start all services
docker-compose up -d

# Start specific service
docker-compose up -d db

# Start with logs visible
docker-compose up
```

### Stopping Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (deletes all data!)
docker-compose down -v

# Stop specific service
docker-compose stop db
```

### Monitoring Services

```bash
# Check service status
docker-compose ps

# View logs for all services
docker-compose logs

# View logs for specific service
docker-compose logs db
docker-compose logs rest

# Follow logs in real-time
docker-compose logs -f

# View last 50 lines
docker-compose logs --tail=50
```

## Service URLs

Once running, these services will be available:

| Service | URL | Purpose |
|---------|-----|---------|
| **Supabase Studio** | http://localhost:3000 | Database management UI |
| **PostgreSQL** | localhost:5432 | Database connection |
| **PostgREST API** | http://localhost:54321 | REST API for database |
| **Realtime** | http://localhost:4000 | Real-time subscriptions |
| **Meta API** | http://localhost:8080 | Database metadata API |

## Database Access

### Using psql (command line)

```bash
# Connect to database
docker-compose exec db psql -U postgres -d postgres

# Or from host (if psql installed)
psql -h localhost -p 5432 -U postgres -d postgres
```

### Using Supabase Studio

1. Open http://localhost:3000
2. Use the connection details from your `.env` file

### Database Connection String

```
postgresql://postgres:YOUR_PASSWORD@localhost:5432/postgres
```

Replace `YOUR_PASSWORD` with the value from your `.env` file.

## Troubleshooting

### Port Conflicts

If you get port conflicts, check what's using the ports:

```bash
# Check what's using port 3000
sudo lsof -i :3000

# Check all conflicting ports
sudo lsof -i :3000 -i :5432 -i :54321 -i :4000 -i :8080
```

Stop conflicting services or change ports in `docker-compose.yml`.

### Permission Issues

```bash
# If you get permission denied errors
sudo chown -R $USER:$USER .

# Fix Docker socket permissions
sudo chmod 666 /var/run/docker.sock
```

### Service Won't Start

```bash
# Check service logs
docker-compose logs service_name

# Restart specific service
docker-compose restart service_name

# Remove and recreate service
docker-compose rm service_name
docker-compose up -d service_name
```

### Database Connection Issues

```bash
# Check if database is ready
docker-compose exec db pg_isready -U postgres

# Check database logs
docker-compose logs db

# Reset database (WARNING: deletes all data)
docker-compose down -v
docker-compose up -d
```

## Environment Variables

Key variables in `.env` file:

| Variable | Description | Example |
|----------|-------------|---------|
| `POSTGRES_PASSWORD` | Database password | `secure_password_123` |
| `JWT_SECRET` | JWT signing secret | `your-32-char-secret` |
| `SUPABASE_ANON_KEY` | Public API key | `generated-anon-key` |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key | `generated-service-key` |

## Integration with Manual Tests

Update your manual test configuration:

```bash
# In backend/tests/manual/.env
BACKEND_URL=http://localhost:54321
DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/postgres
```

## Development Workflow

### Daily Development

```bash
# Start development environment
docker-compose up -d

# Check everything is running
docker-compose ps

# View logs during development
docker-compose logs -f

# Stop when done
docker-compose down
```

### Database Changes

```bash
# After modifying backend/migrations/init.sql
docker-compose down -v  # Remove old data
docker-compose up -d    # Start with new schema

# Or apply migrations to running database
docker-compose exec db psql -U postgres -d postgres -f /docker-entrypoint-initdb.d/migrations.sql
```

### Reset Everything

```bash
# Complete reset (deletes all data!)
docker-compose down -v
docker system prune -f
./setup-docker.sh
```

## Production Deployment

For production, you'll want to:

1. Use external managed database (not Docker)
2. Set up proper secrets management
3. Configure SSL/TLS
4. Set up backup strategies
5. Use container orchestration (Kubernetes, Docker Swarm)

## Backup and Restore

### Backup Database

```bash
# Create backup
docker-compose exec db pg_dump -U postgres postgres > backup_$(date +%Y%m%d_%H%M%S).sql

# Compressed backup
docker-compose exec db pg_dump -U postgres postgres | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz
```

### Restore Database

```bash
# Restore from backup
cat backup_20231003_123456.sql | docker-compose exec -T db psql -U postgres postgres

# Restore compressed backup
gunzip -c backup_20231003_123456.sql.gz | docker-compose exec -T db psql -U postgres postgres
```

## Next Steps

After Docker Compose is running:

1. **Test the setup**: `curl http://localhost:54321/`
2. **Access Supabase Studio**: http://localhost:3000
3. **Run manual tests**: `cd backend/tests/manual && make test-all`
4. **Start backend development**: Implement your Go API server
5. **Configure Flutter app**: Update API endpoints to use localhost:54321

---

**Need Help?**
- Check Docker Compose logs: `docker-compose logs`
- Verify services: `docker-compose ps`
- Restart services: `docker-compose restart`
- Full reset: `docker-compose down -v && ./setup-docker.sh`