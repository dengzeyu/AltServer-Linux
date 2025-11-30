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
- **Two deployment modes**: Daemon mode (server) or CLI mode (one-off installations)

## 📱 Authentication: UDID, Apple ID, and Password

### 🔄 Daemon Mode (Default - Recommended)

The default Docker setup runs AltServer as a **background server** that automatically discovers iOS devices. In this mode:

- ✅ **No UDID required** - automatically detected
- ✅ **No Apple ID/Password in Docker** - enter in AltStore on iOS device
- ✅ **Persistent server** for multiple app installations
- ✅ **Network discovery** of iOS devices

#### How it works:
1. **AltServer runs continuously** in Docker container
2. **AltStore on iOS** discovers the server automatically via network
3. **Apple ID and password** are entered securely in AltStore on your iOS device
4. **Device UDID** is detected automatically when iOS device connects
5. **No sensitive credentials** stored in Docker configuration

### 🔧 CLI Mode (One-off Installations)

For automation or one-time IPA installations, you can pass credentials directly:

#### Method 1: Direct Command Execution
```bash
# Run IPA installation with credentials
docker run --rm \
  -v /path/to/your/app.ipa:/app.ipa \
  altserver-linux:latest \
  AltServer -u "YOUR-DEVICE-UDID" -a "your-apple-id@example.com" -p "your-password" /app.ipa
```

#### Method 2: Environment Variables
```bash
# Create .env.local file (add to .gitignore!)
echo "ALT_UDID=00008030-001234567890001E" >> .env.local
echo "ALT_APPLEID=your-apple-id@example.com" >> .env.local
echo "ALT_PASSWORD=abcd-efgh-ijkl-mnop" >> .env.local

# Run with environment variables
docker run --rm --env-file .env.local \
  -v ./app.ipa:/app.ipa \
  altserver-linux:latest \
  AltServer -u "${ALT_UDID}" -a "${ALT_APPLEID}" -p "${ALT_PASSWORD}" /app.ipa
```

#### Method 3: Docker Compose with Command Override
```yaml
# docker-compose.cli.yml
version: '3.8'
services:
  altserver:
    image: altserver-linux:latest
    command: ["AltServer", "-u", "${ALT_UDID}", "-a", "${ALT_APPLEID}", "-p", "${ALT_PASSWORD}", "/app.ipa"]
    volumes:
      - ./app.ipa:/app.ipa
    environment:
      - ALT_UDID=${ALT_UDID}
      - ALT_APPLEID=${ALT_APPLEID}
      - ALT_PASSWORD=${ALT_PASSWORD}
```

### 🔒 Security Best Practices

#### Use App-Specific Passwords
Always use app-specific passwords, not your main Apple ID password:
```
Create app-specific passwords at: https://appleid.apple.com
Example: abcd-efgh-ijkl-mnop
```

#### Protect Your Credentials
```bash
# Never commit credentials to version control
echo ".env.local" >> .gitignore
echo "*.secret" >> .gitignore

# Use Docker secrets for production
services:
  altserver:
    secrets:
      - apple_id
      - apple_password
    command: ["AltServer", "-u", "${ALT_UDID}", "-a", "/run/secrets/apple_id", "-p", "/run/secrets/apple_password"]
```

### 📋 How to Get Your Device UDID

#### Method 1: From AltStore (Easiest)
1. Open AltStore on your iOS device
2. Go to Settings → Device ID
3. Copy the displayed UDID

#### Method 2: From Mac (with USB connection)
```bash
# Connect device via USB and run
system_profiler SPUSBDataType | grep "Serial Number"
# Or using idevice_id (requires libimobiledevice)
idevice_id -l
```

#### Method 3: From Xcode
1. Open Xcode → Window → Devices and Simulators
2. Select your iOS device
3. Copy the Identifier value

#### Method 4: From iTunes
1. Connect device to computer
2. Open iTunes and select your device
3. Click on serial number to reveal UDID
4. Right-click and copy

### 🎯 Recommended Usage by Scenario

#### Personal Use (Recommended)
```bash
# Deploy daemon server (no credentials needed)
docker compose up -d

# Use AltStore on iOS device:
# - Enter Apple ID and password in AltStore settings
# - Install apps normally through AltStore
# - Let AltStore handle automatic UDID detection
```

#### Development/Testing
```bash
# Use CLI mode for testing specific builds
docker run --rm --env-file .env.local \
  -v ./build/MyApp.ipa:/app.ipa \
  altserver-linux:latest \
  AltServer -u "${ALT_UDID}" -a "${ALT_APPLEID}" -p "${ALT_PASSWORD}" /app.ipa
```

#### CI/CD Automation
```yaml
# GitHub Actions example
- name: Install IPA with AltServer
  run: |
    docker run --rm \
      -e ALT_UDID=${{ secrets.DEVICE_UDID }} \
      -e ALT_APPLEID=${{ secrets.APPLE_ID }} \
      -e ALT_PASSWORD=${{ secrets.APPLE_PASSWORD }} \
      -v ./MyApp.ipa:/app.ipa \
      altserver-linux:latest \
      AltServer -u "${ALT_UDID}" -a "${ALT_APPLEID}" -p "${ALT_PASSWORD}" /app.ipa
```

#### Multiple Device Management
```bash
# Deploy server once, connect multiple devices
docker compose up -d

# Each device:
# - Connects to same network
# - Uses AltStore with same Apple ID or different IDs
# - Gets automatic UDID detection
# - No additional configuration needed
```

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

### Option 3: Self-Hosted Anisette Server (Recommended for Privacy)

Deploy your own anisette server using [Dadoum/anisette-v3-server](https://github.com/Dadoum/anisette-v3-server):

```bash
# Start self-hosted anisette server
docker-compose --profile anisette up -d

# Configure AltServer to use your local anisette server
# Edit .env and set:
ANISETTE_SERVER=http://anisette-server:8080

# Restart AltServer to use new anisette server
docker-compose restart altserver
```

#### Benefits of Self-Hosted Anisette:
- ✅ **Privacy**: Your Apple ID credentials never leave your network
- ✅ **Reliability**: No dependency on external services
- ✅ **Control**: Full control over authentication process
- ✅ **Offline Capability**: Works without internet connection to external services
- ✅ **No Rate Limits**: No restrictions from public anisette servers

#### Self-Hosted Anisette Configuration:
```yaml
# In docker-compose.yml
services:
  anisette-server:
    image: dadoum/anisette-v3-server:latest
    environment:
      - ANISETTE_SERVER_PORT=8080
      - ANISETTE_DEBUG=0
      - ANISETTE_LOG_LEVEL=info
    volumes:
      - ./anisette-data:/data  # Persistent data storage
    ports:
      - "8080:8080"
```

#### Managing Self-Hosted Anisette:
```bash
# Check anisette server status
docker logs altserver-anisette

# Test anisette server connectivity
curl -v http://localhost:8080/health

# View anisette server logs
docker logs -f altserver-anisette

# Restart anisette server
docker-compose restart anisette-server

# Backup anisette data
sudo tar czf anisette-backup.tar.gz anisette-data/
```

### Option 4: External Anisette Server

If you have an existing anisette server:

```bash
# Configure to use external server
ANISETTE_SERVER=http://your-anisette-server.com:8080
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