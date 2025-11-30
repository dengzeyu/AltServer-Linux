# AltServer-Linux Docker Deployment

This guide covers deploying AltServer-Linux using Docker and Docker Compose, with specific instructions for Portainer deployment.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Portainer Deployment](#portainer-deployment)
- [Network Device Connection](#network-device-connection)
- [Anisette Server Options](#anisette-server-options)
- [Monitoring and Maintenance](#monitoring-and-maintenance)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)

## Overview

This Docker deployment provides:

- **Network-only operation**: No USB device passthrough required
- **Multi-architecture support**: amd64, arm64, armv7
- **Configurable anisette server**: Use default public server or deploy your own
- **Portainer optimization**: Ready for stack deployment
- **Health monitoring**: Built-in health checks and logging
- **Resource management**: Configurable limits and reservations

## Prerequisites

### Required Software

- **Docker**: Version 20.10 or later
- **Docker Compose**: Version 1.29 or later
- **Portainer**: Version 2.0 or later (if using Portainer deployment)

### System Requirements

- **Memory**: Minimum 512MB available RAM
- **Storage**: Minimum 1GB free disk space
- **Network**: Internet access for anisette server communication
- **iOS Device**: Connected to the same network as the Docker host

### Network Setup

For network device connection, ensure:

1. **Same Network**: iOS device and Docker host on the same network
2. **Network Discovery**: UDP port 2255 open on Docker host (if using firewall)
3. **DNS Resolution**: Proper DNS configuration for anisette server access

## Quick Start

### 1. Clone Repository

```bash
git clone --recursive https://github.com/NyaMisty/AltServer-Linux
cd AltServer-Linux
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit configuration (optional)
nano .env
```

### 3. Build and Deploy

```bash
# Build Docker image
docker build -t altserver-linux:latest .

# Start services
docker-compose up -d

# View logs
docker-compose logs -f altserver
```

### 4. Verify Deployment

```bash
# Check container status
docker-compose ps

# Check health status
docker inspect altserver | grep Health -A 5
```

## Configuration

### Environment Variables

Key configuration options in `.env`:

```bash
# Anisette server URL
ANISETTE_SERVER=https://armconverter.com/anisette/irGb3Quww8zrhgqnzmrx

# Timezone
TZ=America/New_York

# Debug level (0-2)
DEBUG=0

# USB compatibility (usually not needed)
NO_SUBSCRIBE=0
```

### Resource Limits

Configure memory and CPU limits:

```yaml
# In docker-compose.yml
deploy:
  resources:
    limits:
      memory: 512M
      cpus: '1.0'
    reservations:
      memory: 256M
      cpus: '0.5'
```

## Portainer Deployment

### 1. Create New Stack

1. Open Portainer web interface
2. Navigate to **Stacks**
3. Click **Add stack**
4. Name: `altserver-deployment`

### 2. Configure Stack

**Web Editor Configuration:**

```yaml
# Use the Portainer-optimized configuration
# Copy contents from docker-compose.portainer.yml
```

**Environment Variables:**

```bash
# Configure in Portainer environment section
ANISETTE_SERVER=https://armconverter.com/anisette/irGb3Quww8zrhgqnzmrx
TZ=America/New_York
DEBUG=0
```

### 3. Deploy Stack

1. Click **Deploy the stack**
2. Monitor deployment in **Containers** section
3. Check container logs for any issues

### 4. Optional Anisette Server

To use a custom anisette server:

1. Add `anisette` to **Profiles** in stack configuration
2. Set `ANISETTE_SERVER=http://anisette-server:8080`
3. Redeploy the stack

## Network Device Connection

### Using Network Discovery

AltServer-Linux supports network-based iOS device discovery:

1. **Ensure Network Access**:
   ```bash
   # Test UDP connectivity
   nc -u -l 2255
   ```

2. **Configure iOS Device**:
   - Connect to WiFi
   - Install AltStore on iOS device
   - AltStore should discover network AltServer automatically

3. **Firewall Configuration**:
   ```bash
   # Allow UDP port 2255 (if using ufw)
   sudo ufw allow 2255/udp

   # Allow UDP port 2255 (if using firewalld)
   sudo firewall-cmd --add-port=2255/udp --permanent
   sudo firewall-cmd --reload
   ```

### Using netmuxd (Alternative)

For advanced network device management:

```bash
# Deploy netmuxd container (optional)
docker run -d \
  --name netmuxd \
  --network host \
  jkcoxson/netmuxd:latest
```

## Anisette Server Options

### Option 1: Default Public Server

```bash
# No configuration needed
ANISETTE_SERVER=https://armconverter.com/anisette/irGb3Quww8zrhgqnzmrx
```

### Option 2: Alternative Public Servers

```bash
# Alternative public anisette servers
ANISETTE_SERVER=https://anisette.nya.software
# or
ANISETTE_SERVER=https://api.anisette.org/v1
```

### Option 3: Custom Anisette Server

Enable the built-in anisette server:

```bash
# Start with anisette profile
docker-compose --profile anisette up -d

# Configure AltServer to use local anisette
ANISETTE_SERVER=http://anisette-server:8080
```

## Monitoring and Maintenance

### Health Monitoring

```bash
# Check container health
docker ps --format "table {{.Names}}\t{{.Status}}"

# Detailed health information
docker inspect altserver | jq '.[0].State.Health'
```

### Log Management

```bash
# View real-time logs
docker-compose logs -f altserver

# View last 100 lines
docker-compose logs --tail=100 altserver

# Export logs
docker-compose logs altserver > altserver-logs.txt
```

### Resource Monitoring

```bash
# Container resource usage
docker stats altserver

# Detailed container inspection
docker inspect altserver | jq '.[0].HostConfig.Resources'
```

### Updates and Maintenance

```bash
# Update Docker image
docker-compose pull
docker-compose up -d

# Backup data volume
docker run --rm -v altserver_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/altserver-data-backup.tar.gz -C /data .

# Cleanup unused images
docker image prune -f
```

## Troubleshooting

### Common Issues

#### 1. Container Won't Start

```bash
# Check container logs
docker logs altserver

# Verify image exists
docker images | grep altserver

# Check for port conflicts
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

#### 2. Network Device Not Found

```bash
# Check network configuration
docker exec -it altserver ip addr show

# Test UDP port availability
netstat -uln | grep 2255

# Verify firewall settings
sudo ufw status
# or
sudo firewall-cmd --list-all
```

#### 3. Anisette Server Connection Failed

```bash
# Test connectivity from container
docker exec -it altserver curl -v https://armconverter.com/anisette/irGb3Quww8zrhgqnzmrx

# Check DNS resolution
docker exec -it altserver nslookup armconverter.com

# Verify environment variables
docker exec -it altserver env | grep ANISETTE
```

#### 4. Memory Issues

```bash
# Check memory usage
docker stats altserver --no-stream

# Increase memory limit in docker-compose.yml
deploy:
  resources:
    limits:
      memory: 1G
```

### Debug Mode

Enable debug logging:

```bash
# Set debug level in .env
DEBUG=2

# Or override in docker-compose
environment:
  - ALTSERVER_DEBUG=2

# Restart with debug
docker-compose up -d
docker-compose logs -f altserver
```

### Container Shell Access

```bash
# Access container shell
docker exec -it altserver /bin/bash

# Check running processes
docker exec -it altserver ps aux

# Test network connectivity
docker exec -it altserver ping 8.8.8.8
```

## Advanced Configuration

### Custom Dockerfile Modifications

For custom builds:

```dockerfile
# Custom additions to Dockerfile
# Add custom tools
RUN apk add --no-cache htop curl

# Custom environment
ENV CUSTOM_VAR=value
```

### Multi-Host Deployment

For Docker Swarm or multi-node setups:

```yaml
# docker-compose.swarm.yml
version: '3.8'
services:
  altserver:
    image: altserver-linux:latest
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.labels.altserver == true
```

### External Database Integration

For persistent data storage:

```yaml
services:
  altserver:
    volumes:
      - altserver_data:/app/data
      - external_db_data:/external/data
```

### Backup and Restore

```bash
# Automated backup script
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
docker run --rm \
  -v altserver_data:/data \
  -v /backup:/backup \
  alpine tar czf /backup/altserver-backup-${DATE}.tar.gz -C /data .

# Restore script
#!/bin/bash
BACKUP_FILE=$1
docker run --rm \
  -v altserver_data:/data \
  -v /backup:/backup \
  alpine tar xzf /backup/${BACKUP_FILE} -C /data
```

## Support

- **GitHub Issues**: [AltServer-Linux Issues](https://github.com/NyaMisty/AltServer-Linux/issues)
- **Documentation**: [Main Project README](README.md)
- **Community**: [Discussions](https://github.com/NyaMisty/AltServer-Linux/discussions)

## License

This Docker deployment follows the same license as the main AltServer-Linux project. See [LICENSE](LICENSE) for details.