#!/bin/bash

# Docker Compose deployment script for Redis App

# Colors for output
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

show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  up      Start the application stack"
    echo "  down    Stop the application stack"
    echo "  build   Build the application image"
    echo "  logs    Show application logs"
    echo "  status  Show container status"
    echo ""
}

case "${1:-up}" in
    "up")
        print_status "Starting Redis App with Docker Compose..."
        docker-compose up -d
        print_success "Application started!"
        echo ""
        echo "Access the application at: http://localhost:3001"
        echo "Redis is available at: localhost:6379"
        echo ""
        echo "Use 'docker-compose logs -f' to view logs"
        ;;
    "down")
        print_status "Stopping Redis App..."
        docker-compose down
        print_success "Application stopped!"
        ;;
    "build")
        print_status "Building application image..."
        docker-compose build
        print_success "Build completed!"
        ;;
    "logs")
        docker-compose logs -f
        ;;
    "status")
        docker-compose ps
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    *)
        print_warning "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
