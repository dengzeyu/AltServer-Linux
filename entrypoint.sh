#!/bin/bash

# AltServer-Linux Docker Entrypoint Script
# Handles container initialization and configuration

set -e

# Function to log messages with timestamp
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Function to handle errors
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Function to check environment variables
check_env() {
    log "Checking environment variables..."

    # Set defaults for required variables
    export ALTSERVER_ANISETTE_SERVER=${ALTSERVER_ANISETTE_SERVER:-"https://armconverter.com/anisette/irGb3Quww8zrhgqnzmrx"}
    export ALTSERVER_NO_SUBSCRIBE=${ALTSERVER_NO_SUBSCRIBE:-0}
    export TZ=${TZ:-UTC}
    export ALTSERVER_DEBUG=${ALTSERVER_DEBUG:-0}

    log "Environment configuration:"
    log "  Anisette Server: ${ALTSERVER_ANISETTE_SERVER}"
    log "  No Subscribe: ${ALTSERVER_NO_SUBSCRIBE}"
    log "  Timezone: ${TZ}"
    log "  Debug Level: ${ALTSERVER_DEBUG}"
}

# Function to setup directories
setup_directories() {
    log "Setting up directories..."

    # Ensure data directory exists
    mkdir -p /app/data /app/logs

    # Set proper permissions
    chmod 755 /app /app/data /app/logs

    # Create log file if it doesn't exist
    touch /app/logs/altserver.log
    chmod 644 /app/logs/altserver.log

    log "Directory setup completed"
}

# Function to test network connectivity
test_connectivity() {
    log "Testing network connectivity..."

    # Test DNS resolution
    if ! nslookup google.com > /dev/null 2>&1; then
        log "WARNING: DNS resolution may not be working properly"
    fi

    # Test connectivity to anisette server
    if curl -s --connect-timeout 10 "${ALTSERVER_ANISETTE_SERVER}" > /dev/null 2>&1; then
        log "Successfully connected to anisette server"
    else
        log "WARNING: Cannot reach anisette server at ${ALTSERVER_ANISETTE_SERVER}"
    fi
}

# Function to display container information
display_info() {
    log "AltServer-Linux Docker Container"
    log "================================"
    log "Version: $(cat /usr/local/bin/AltServer --version 2>/dev/null || echo 'Unknown')"
    log "Architecture: $(uname -m)"
    log "Kernel: $(uname -r)"
    log "Container IP: $(hostname -i || echo 'Unknown')"
    log "Working Directory: $(pwd)"
    log "User: $(whoami)"
    log "UID: $(id -u)"
    log "GID: $(id -g)"
    log ""
}

# Function to handle signals
cleanup() {
    log "Received termination signal, shutting down gracefully..."
    # Kill AltServer process if running
    if pgrep -f AltServer > /dev/null; then
        pkill -TERM -f AltServer
        sleep 2
        # Force kill if still running
        if pgrep -f AltServer > /dev/null; then
            pkill -KILL -f AltServer
        fi
    fi
    log "Cleanup completed"
    exit 0
}

# Function to start AltServer
start_altserver() {
    log "Starting AltServer-Linux..."

    # Check if binary exists and is executable
    if [ ! -x "/usr/local/bin/AltServer" ]; then
        error_exit "AltServer binary not found or not executable"
    fi

    # Display help if requested
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        exec /usr/local/bin/AltServer --help
    fi

    # Start AltServer with provided arguments
    if [ $# -eq 0 ]; then
        log "Starting AltServer in daemon mode..."
        exec /usr/local/bin/AltServer
    else
        log "Starting AltServer with arguments: $*"
        exec /usr/local/bin/AltServer "$@"
    fi
}

# Main execution flow
main() {
    # Set up signal handlers
    trap cleanup SIGTERM SIGINT SIGQUIT

    log "Initializing AltServer-Linux Docker container..."

    # Perform setup tasks
    check_env
    setup_directories
    test_connectivity
    display_info

    log "Initialization completed successfully"

    # Start AltServer
    start_altserver "$@"
}

# Execute main function with all arguments
main "$@"