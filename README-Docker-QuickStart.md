# AltServer-Linux Docker Quick Start Guide

Deploy AltServer-Linux using Docker with network device discovery - perfect for Portainer deployment.

## 🚀 Quick Start (5 Minutes)

### 1. Clone and Setup
```bash
git clone --recursive https://github.com/NyaMisty/AltServer-Linux
cd AltServer-Linux
cp .env.example .env
```

### 2. Choose Your Deployment Method

#### Option A: Docker Compose (Simple)
```bash
# Build and start
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f altserver
```

#### Option B: Portainer (Recommended)
1. Open Portainer web interface
2. Go to **Stacks** → **Add stack**
3. Name: `altserver-deployment`
4. Copy contents from `docker-compose.portainer.yml`
5. Configure environment variables:
   ```
   ANISETTE_SERVER=https://armconverter.com/anisette/irGb3Quww8zrhgqnzmrx
   TZ=America/New_York  # Your timezone
   DEBUG=0              # 1 for basic debug
   ```
6. Click **Deploy the stack**

### 3. Verify Deployment
```bash
# Check if container is running
docker ps --format "table {{.Names}}\t{{.Status}}"

# Check container health
docker inspect altserver | grep Health -A 5

# View logs
docker logs altserver
```

## 📱 Connect iOS Device & Authentication

### 🔑 How Authentication Works

The Docker setup runs in **daemon mode** (server mode) which means:

- ✅ **No UDID, Apple ID, or password needed in Docker**
- ✅ **Enter Apple ID and password in AltStore on iOS device**
- ✅ **UDID detected automatically** when device connects
- ✅ **Secure authentication** handled by AltStore app

### Network Setup Requirements:
- ✅ iOS device and Docker host on same WiFi network
- ✅ AltStore installed on iOS device
- ✅ Internet access for anisette server authentication
- ✅ Apple ID credentials ready for AltStore setup

### Connection Steps:
1. **Make sure your iOS device is on WiFi** (same network as Docker host)
2. **Open AltStore on your iOS device**
3. **AltServer should automatically discover your Docker AltServer**
4. **Enter Apple ID and password** in AltStore when prompted
5. **Install apps normally** through AltStore

### 🔐 Authentication Details:
- **Apple ID**: Enter in AltStore → Settings
- **Password**: Use app-specific password (recommended)
- **UDID**: Auto-detected by AltStore when device connects
- **Multiple devices**: Each device gets automatic UDID detection

### If Using Command Line (Advanced)
```bash
# For one-off installations with specific credentials
docker run --rm \
  -v /path/to/app.ipa:/app.ipa \
  altserver-linux:latest \
  AltServer -u "DEVICE-UDID" -a "apple-id@example.com" -p "app-password" /app.ipa
```

### How to Get Your Device UDID (if needed)
1. **From AltStore (Easiest)**: Open AltStore → Settings → Device ID
2. **From Mac**: `system_profiler SPUSBDataType | grep "Serial Number"`
3. **From iTunes**: Connect device → Click serial number → Copy UDID

### Troubleshooting Authentication:
- **Device not found**: Check WiFi connection and network discovery
- **Authentication failed**: Verify Apple ID and app-specific password
- **Port blocked**: Ensure UDP port 2255 is open on your network

## 🔧 Configuration Options

### Environment Variables (.env)
```bash
# Anisette server (authentication service)
ANISETTE_SERVER=https://armconverter.com/anisette/irGb3Quww8zrhgqnzmrx

# Timezone for proper logging
TZ=America/New_York

# Debug level (0=none, 1=basic, 2=verbose)
DEBUG=0

# USB compatibility (usually not needed)
NO_SUBSCRIBE=0
```

### Optional: Custom Anisette Server
```bash
# Enable local anisette server
docker compose --profile anisette up -d

# Or in Portainer, add "anisette" to profiles
# Set ANISETTE_SERVER=http://anisette-server:8080
```

## 📊 Monitoring

### Check Container Status
```bash
# Real-time logs
docker logs -f altserver

# Resource usage
docker stats altserver

# Health status
docker ps --format "table {{.Names}}\t{{.Status}}"
```

### Common Issues
- **Device not found**: Check network connectivity and WiFi
- **Authentication failed**: Verify anisette server URL is accessible
- **Container crashes**: Check logs with `docker logs altserver`

## 🛠 Advanced Configuration

### Resource Limits
```yaml
# In docker-compose.yml
deploy:
  resources:
    limits:
      memory: 512M
      cpus: '1.0'
```

### Custom Networks
```yaml
# For firewall-restricted environments
networks:
  altserver-net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

### Backup Data
```bash
# Backup configuration and data
docker run --rm \
  -v altserver_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/altserver-backup.tar.gz -C /data .
```

## 🔒 Security Features

- ✅ Runs as non-root user
- ✅ Minimal attack surface (Alpine Linux)
- ✅ Read-only system files where possible
- ✅ Configurable resource limits
- ✅ Health monitoring and logging

## 📋 Portainer Stack Configuration

For easy copy-paste into Portainer:

```yaml
version: '3.8'

services:
  altserver:
    image: altserver-linux:latest
    container_name: altserver
    restart: unless-stopped
    network_mode: host
    environment:
      - ALTSERVER_ANISETTE_SERVER=https://armconverter.com/anisette/irGb3Quww8zrhgqnzmrx
      - TZ=America/New_York
      - DEBUG=0
    volumes:
      - altserver_data:/app/data
      - altserver_logs:/app/logs
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '1.0'
    healthcheck:
      test: ["CMD", "pgrep", "-f", "AltServer"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  altserver_data:
  altserver_logs:
```

## 🆘 Troubleshooting

### Container Won't Start
```bash
# Check logs
docker logs altserver

# Check configuration
docker compose config

# Rebuild if needed
docker compose up --build -d
```

### iOS Device Not Connecting
1. Verify same network connection
2. Check firewall allows UDP port 2255
3. Restart AltStore on iOS device
4. Test anisette server connectivity:
   ```bash
   curl -v https://armconverter.com/anisette/irGb3Quww8zrhgqnzmrx
   ```

### Performance Issues
```bash
# Monitor resources
docker stats altserver

# Check disk space
docker system df

# Clean up if needed
docker system prune -f
```

## 📚 Documentation

- **Full Documentation**: `README-Docker.md`
- **Environment Variables**: `.env.example`
- **Troubleshooting Guide**: See "Common Issues" section above
- **GitHub Issues**: [AltServer-Linux Issues](https://github.com/NyaMisty/AltServer-Linux/issues)

## 🎯 Success Checklist

- [ ] Docker container running (`docker ps`)
- [ ] Health check passing
- [ ] iOS device on same network
- [ ] AltStore discovers AltServer
- [ ] Can install apps through AltStore
- [ ] Logs show successful connections

If all items are checked, your AltServer-Linux Docker deployment is working perfectly! 🎉

---

**Need Help?**
- Check the full documentation: `README-Docker.md`
- Review environment options in `.env.example`
- Open an issue on GitHub for specific problems