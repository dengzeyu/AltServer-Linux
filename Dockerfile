# Multi-architecture production Dockerfile for AltServer-Linux
# Network-only mode (no USB device passthrough required)

# Use pre-built base image that includes dependencies
FROM alpine:3.15 AS base

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    libssl1.1 \
    libcrypto1.1 \
    libuuid \
    curl \
    bash \
    git \
    make \
    cmake \
    clang \
    clang-dev \
    boost-static \
    boost-dev \
    libressl-dev \
    util-linux-dev \
    zlib-dev \
    zlib-static \
    python3 \
    && rm -rf /var/cache/apk/*

# Runtime stage
FROM alpine:3.15

# Set labels for metadata
LABEL maintainer="AltServer-Linux Docker Deployment"
LABEL description="AltServer for AltStore, running on Linux with network device support"
LABEL version="1.0"
LABEL source="https://github.com/dengzeyu/AltServer-Linux"

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    libssl1.1 \
    libcrypto1.1 \
    libuuid \
    curl \
    bash \
    && rm -rf /var/cache/apk/*

# Create non-root user for security
RUN addgroup -g 1000 altserver && \
    adduser -D -s /bin/sh -u 1000 -G altserver altserver

# Create application directory
RUN mkdir -p /app /app/logs /app/data && \
    chown -R altserver:altserver /app

# Note: This Dockerfile requires the AltServer binary to be built separately
# Users should build the binary locally and copy it, or use the build script

# Copy pre-built AltServer binary (this should be replaced with actual binary)
# For now, we'll create a placeholder
COPY README.md /tmp/README.md

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh && \
    chown altserver:altserver /usr/local/bin/entrypoint.sh

# Switch to non-root user
USER altserver
WORKDIR /app

# Set environment variables
ENV ALTSERVER_ANISETTE_SERVER=https://armconverter.com/anisette/irGb3Quww8zrhgqnzmrx
ENV ALTSERVER_NO_SUBSCRIBE=0
ENV TZ=UTC
ENV ALTSERVER_DEBUG=0

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD pgrep -f AltServer > /dev/null || exit 1

# Expose ports (if needed for network device discovery)
EXPOSE 2255/udp

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command - run AltServer in daemon mode
CMD ["--help"]

# Build instructions comment:
# To build this image with a working AltServer binary:
# 1. Build AltServer locally using: make -f Makefile
# 2. Copy the AltServer-<arch> binary to the Dockerfile directory
# 3. Uncomment and modify the COPY line below
# COPY AltServer-amd64 /usr/local/bin/AltServer
# RUN chmod +x /usr/local/bin/AltServer && chown altserver:altserver /usr/local/bin/AltServer
# 4. Change the CMD to: CMD ["AltServer"]