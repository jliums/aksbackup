#!/bin/bash

# Docker Build and Test Script for Redis App

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Configuration
IMAGE_NAME="redis-app"
IMAGE_TAG="latest"
CONTAINER_NAME="redis-app-test"

echo "🔨 Redis App Docker Build and Test"
echo ""

# Function to cleanup previous containers
cleanup() {
    print_status "Cleaning up previous containers..."
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
}

# Function to build the image
build_image() {
    print_status "Building Docker image..."
    
    if docker build -t "$IMAGE_NAME:$IMAGE_TAG" .; then
        print_success "Docker image built successfully!"
        
        # Show image info
        echo ""
        print_status "Image information:"
        docker images | grep "$IMAGE_NAME"
        
        # Show image size
        IMAGE_SIZE=$(docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep "$IMAGE_NAME" | grep "$IMAGE_TAG" | awk '{print $3}')
        echo "Image size: $IMAGE_SIZE"
    else
        print_error "Failed to build Docker image"
        exit 1
    fi
}

# Function to test the image
test_image() {
    print_status "Testing the Docker image..."
    
    cleanup
    
    # Run the container
    print_status "Starting container..."
    if docker run -d \
        --name "$CONTAINER_NAME" \
        -p 3001:3001 \
        -e REDIS_HOST=host.docker.internal \
        -e REDIS_PORT=6379 \
        "$IMAGE_NAME:$IMAGE_TAG"; then
        print_success "Container started successfully!"
    else
        print_error "Failed to start container"
        exit 1
    fi
    
    # Wait a moment for the app to start
    print_status "Waiting for application to start..."
    sleep 5
    
    # Test health endpoint
    print_status "Testing health endpoint..."
    if curl -f http://localhost:3001/health > /dev/null 2>&1; then
        print_success "Health check passed!"
    else
        print_warning "Health check failed (this is expected if Redis is not running)"
    fi
    
    # Test frontend
    print_status "Testing frontend..."
    if curl -f http://localhost:3001 > /dev/null 2>&1; then
        print_success "Frontend is accessible!"
    else
        print_error "Frontend is not accessible"
    fi
    
    # Show container logs
    echo ""
    print_status "Container logs (last 10 lines):"
    docker logs --tail 10 "$CONTAINER_NAME"
    
    echo ""
    print_success "Build and basic tests completed!"
    echo ""
    echo "Access the application at: http://localhost:3001"
    echo ""
    echo "Commands:"
    echo "  View logs: docker logs -f $CONTAINER_NAME"
    echo "  Stop container: docker stop $CONTAINER_NAME"
    echo "  Remove container: docker rm $CONTAINER_NAME"
    echo "  Remove image: docker rmi $IMAGE_NAME:$IMAGE_TAG"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  build    Build the Docker image"
    echo "  test     Build and test the Docker image"
    echo "  cleanup  Remove test containers and images"
    echo "  help     Show this help message"
    echo ""
}

# Function to cleanup everything
cleanup_all() {
    print_status "Cleaning up containers and images..."
    cleanup
    docker rmi "$IMAGE_NAME:$IMAGE_TAG" 2>/dev/null || true
    print_success "Cleanup completed!"
}

# Parse command
case "${1:-test}" in
    "build")
        build_image
        ;;
    "test")
        build_image
        test_image
        ;;
    "cleanup")
        cleanup_all
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    *)
        print_error "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
