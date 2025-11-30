# Multi-architecture production Dockerfile for AltServer-Linux
# Network-only mode (no USB device passthrough required)

# Build stage using Alpine Linux
FROM alpine:3.15 AS builder

# Set build arguments
ARG TARGETARCH
ARG BUILDPLATFORM

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    cmake \
    make \
    ninja \
    git \
    curl \
    wget \
    clang \
    clang-dev \
    boost-static \
    boost-dev \
    libressl-dev \
    util-linux-dev \
    zlib-dev \
    zlib-static \
    bash \
    vim \
    python3

# Create build environment
RUN mkdir -p /buildenv
WORKDIR /buildenv

# Install corecrypto (downloaded from Apple)
RUN curl -JO 'https://developer.apple.com/file/?file=security&agree=Yes' \
    -H 'Referer: https://developer.apple.com/security/' && \
    unzip -q corecrypto.zip && \
    rm corecrypto.zip

WORKDIR /buildenv/corecrypto
RUN mkdir build && cd build && \
    CC=clang CXX=clang++ cmake .. && \
    sed -i -E 's|^(all: CMakeFiles/corecrypto_perf)|#\1|' CMakeFiles/Makefile2 && \
    sed -i -E 's|^(all: CMakeFiles/corecrypto_test)|#\1|' CMakeFiles/Makefile2 && \
    make -j$(nproc) && \
    make install

WORKDIR /buildenv

# Install cpprestsdk
RUN git clone --recursive https://github.com/microsoft/cpprestsdk && \
    cd cpprestsdk && \
    sed -i 's|-Wcast-align||' "./Release/CMakeLists.txt" && \
    mkdir build && cd build && \
    cmake -DBUILD_SHARED_LIBS=0 .. && \
    make -j$(nproc) && \
    make install

WORKDIR /buildenv

# Install libzip
RUN git clone https://github.com/nih-at/libzip && \
    cd libzip && \
    mkdir build && cd build && \
    cmake -DBUILD_SHARED_LIBS=0 .. && \
    make -j$(nproc) && \
    make install

# Set up source code
WORKDIR /src
COPY . .

# Initialize git submodules (if needed)
RUN if [ ! -d "upstream_repo" ]; then \
        git submodule update --init --recursive; \
    fi

# Build AltServer-Linux
RUN mkdir -p build && \
    make -f ../Makefile -j$(nproc) && \
    ls -la build/AltServer-*

# Runtime stage - minimal Alpine Linux
FROM alpine:3.15

# Set labels for metadata
LABEL maintainer="AltServer-Linux Docker Deployment"
LABEL description="AltServer for AltStore, running on Linux with network device support"
LABEL version="1.0"

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

# Copy compiled binary from builder stage
ARG TARGETARCH
COPY --from=builder /src/build/AltServer-${TARGETARCH} /usr/local/bin/AltServer

# Make binary executable
RUN chmod +x /usr/local/bin/AltServer && \
    chown altserver:altserver /usr/local/bin/AltServer

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
CMD ["AltServer"]