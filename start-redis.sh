#!/bin/bash

# Redis Docker Setup Script
# This script runs Redis in Docker and exposes it to localhost:6379

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_NAME="redis-app-redis"
REDIS_PORT="6379"
REDIS_PASSWORD=""  # Set a password if needed
REDIS_VERSION="7-alpine"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is installed and running
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        echo "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi

    print_success "Docker is installed and running"
}

# Function to stop existing Redis container
stop_existing_container() {
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        print_warning "Stopping existing Redis container..."
        docker stop "$CONTAINER_NAME" > /dev/null 2>&1
    fi

    if docker ps -aq -f name="$CONTAINER_NAME" | grep -q .; then
        print_warning "Removing existing Redis container..."
        docker rm "$CONTAINER_NAME" > /dev/null 2>&1
    fi
}

# Function to start Redis container
start_redis() {
    print_status "Starting Redis container..."
    
    # Build docker run command
    DOCKER_CMD="docker run -d \
        --name $CONTAINER_NAME \
        -p $REDIS_PORT:6379 \
        --restart unless-stopped"
    
    # Add password if configured
    if [ -n "$REDIS_PASSWORD" ]; then
        DOCKER_CMD="$DOCKER_CMD redis:$REDIS_VERSION redis-server --requirepass $REDIS_PASSWORD"
    else
        DOCKER_CMD="$DOCKER_CMD redis:$REDIS_VERSION"
    fi
    
    # Execute the command
    if eval $DOCKER_CMD > /dev/null 2>&1; then
        print_success "Redis container started successfully!"
    else
        print_error "Failed to start Redis container"
        exit 1
    fi
}

# Function to test Redis connection
test_connection() {
    print_status "Testing Redis connection..."
    
    # Wait a moment for Redis to fully start
    sleep 2
    
    # Test connection
    if [ -n "$REDIS_PASSWORD" ]; then
        TEST_CMD="docker exec $CONTAINER_NAME redis-cli -a $REDIS_PASSWORD ping"
    else
        TEST_CMD="docker exec $CONTAINER_NAME redis-cli ping"
    fi
    
    if eval $TEST_CMD > /dev/null 2>&1; then
        print_success "Redis is responding to ping!"
    else
        print_warning "Redis container is running but not responding yet. It may need a moment to fully start."
    fi
}

# Function to show connection info
show_connection_info() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}Redis is now running and ready for connections!${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Connection Details:"
    echo "  Host: localhost"
    echo "  Port: $REDIS_PORT"
    if [ -n "$REDIS_PASSWORD" ]; then
        echo "  Password: $REDIS_PASSWORD"
    else
        echo "  Password: (none)"
    fi
    echo "  Database: 0"
    echo ""
    echo "Container Details:"
    echo "  Name: $CONTAINER_NAME"
    echo "  Image: redis:$REDIS_VERSION"
    echo ""
    echo "Useful Commands:"
    echo "  View logs: docker logs $CONTAINER_NAME"
    echo "  Stop Redis: docker stop $CONTAINER_NAME"
    echo "  Connect with CLI: docker exec -it $CONTAINER_NAME redis-cli"
    if [ -n "$REDIS_PASSWORD" ]; then
        echo "  Connect with password: docker exec -it $CONTAINER_NAME redis-cli -a $REDIS_PASSWORD"
    fi
    echo ""
    echo "Use these settings in your Redis App to connect!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -p, --port PORT     Set Redis port (default: 6379)"
    echo "  -w, --password PWD  Set Redis password (default: none)"
    echo "  -v, --version VER   Set Redis version (default: 7-alpine)"
    echo "  -s, --stop          Stop and remove Redis container"
    echo "  -r, --restart       Restart Redis container"
    echo "  -l, --logs          Show Redis container logs"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  # Start Redis with default settings"
    echo "  $0 -p 6380          # Start Redis on port 6380"
    echo "  $0 -w mypassword    # Start Redis with password"
    echo "  $0 --stop           # Stop Redis container"
    echo "  $0 --logs           # Show Redis logs"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--port)
            REDIS_PORT="$2"
            shift 2
            ;;
        -w|--password)
            REDIS_PASSWORD="$2"
            shift 2
            ;;
        -v|--version)
            REDIS_VERSION="$2"
            shift 2
            ;;
        -s|--stop)
            print_status "Stopping Redis container..."
            stop_existing_container
            print_success "Redis container stopped and removed"
            exit 0
            ;;
        -r|--restart)
            print_status "Restarting Redis container..."
            stop_existing_container
            start_redis
            test_connection
            show_connection_info
            exit 0
            ;;
        -l|--logs)
            if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
                echo "Redis container logs:"
                docker logs "$CONTAINER_NAME"
            else
                print_error "Redis container is not running"
                exit 1
            fi
            exit 0
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
echo "🚀 Redis Docker Setup for Redis App"
echo ""

# Check if Docker is available
check_docker

# Stop any existing container
stop_existing_container

# Start Redis
start_redis

# Test the connection
test_connection

# Show connection information
show_connection_info
