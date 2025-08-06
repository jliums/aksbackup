#!/bin/bash

# Redis App Kubernetes Deployment Script
# This script builds the Docker image and deploys the application to Kubernetes

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="redis-app"
NAMESPACE="redis-app"
IMAGE_NAME="redis-app"
IMAGE_TAG="latest"
DOMAIN="redis-app.local"  # Change this to your domain

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

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if kubectl can connect to cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
    
    print_success "All prerequisites are met"
}

# Function to build Docker image
build_image() {
    print_status "Building Docker image..."
    
    if docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .; then
        print_success "Docker image built successfully"
    else
        print_error "Failed to build Docker image"
        exit 1
    fi
}

# Function to load image into kind/minikube (if applicable)
load_image_to_cluster() {
    print_status "Checking cluster type..."
    
    # Check if running on kind
    if kubectl config current-context | grep -q "kind"; then
        print_status "Detected kind cluster, loading image..."
        if kind load docker-image "${IMAGE_NAME}:${IMAGE_TAG}"; then
            print_success "Image loaded into kind cluster"
        else
            print_warning "Failed to load image into kind cluster, but continuing..."
        fi
    
    # Check if running on minikube
    elif kubectl config current-context | grep -q "minikube"; then
        print_status "Detected minikube cluster, loading image..."
        if minikube image load "${IMAGE_NAME}:${IMAGE_TAG}"; then
            print_success "Image loaded into minikube cluster"
        else
            print_warning "Failed to load image into minikube cluster, but continuing..."
        fi
    else
        print_status "Cluster type not detected or doesn't require image loading"
    fi
}

# Function to deploy to Kubernetes
deploy_to_k8s() {
    print_status "Deploying to Kubernetes..."
    
    # Apply Redis deployment first
    if kubectl apply -f k8s/redis-deployment.yaml; then
        print_success "Redis deployment applied"
    else
        print_error "Failed to apply Redis deployment"
        exit 1
    fi
    
    # Wait for Redis to be ready
    print_status "Waiting for Redis to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/redis -n $NAMESPACE
    
    # Apply app deployment
    if kubectl apply -f k8s/redis-app-deployment.yaml; then
        print_success "Redis App deployment applied"
    else
        print_error "Failed to apply Redis App deployment"
        exit 1
    fi
    
    # Wait for app to be ready
    print_status "Waiting for Redis App to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/redis-app -n $NAMESPACE
}

# Function to show deployment status
show_status() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}Deployment Status${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    print_status "Namespace:"
    kubectl get namespace $NAMESPACE 2>/dev/null || print_warning "Namespace not found"
    
    echo ""
    print_status "Deployments:"
    kubectl get deployments -n $NAMESPACE
    
    echo ""
    print_status "Pods:"
    kubectl get pods -n $NAMESPACE
    
    echo ""
    print_status "Services:"
    kubectl get services -n $NAMESPACE
    
    echo ""
    print_status "Ingress:"
    kubectl get ingress -n $NAMESPACE
}

# Function to show access information
show_access_info() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}Access Information${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Get service info
    SERVICE_PORT=$(kubectl get service redis-app-service -n $NAMESPACE -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
    
    if [ -n "$SERVICE_PORT" ]; then
        echo "Application deployed successfully!"
        echo ""
        echo "Access methods:"
        
        # Port forward method
        echo "1. Port Forward (for local testing):"
        echo "   kubectl port-forward service/redis-app-service 8080:80 -n $NAMESPACE"
        echo "   Then visit: http://localhost:8080"
        
        # Ingress method
        echo ""
        echo "2. Ingress (if nginx-ingress is configured):"
        echo "   Add to /etc/hosts: <INGRESS_IP> $DOMAIN"
        echo "   Then visit: http://$DOMAIN"
        echo "   Get ingress IP: kubectl get ingress redis-app-ingress -n $NAMESPACE"
        
        # LoadBalancer method (cloud)
        echo ""
        echo "3. LoadBalancer (cloud environments):"
        echo "   Change service type to LoadBalancer in k8s/redis-app-deployment.yaml"
        echo "   Then get external IP: kubectl get service redis-app-service -n $NAMESPACE"
    else
        print_warning "Service not found or not ready yet"
    fi
    
    echo ""
    echo "Useful commands:"
    echo "  View logs: kubectl logs -f deployment/redis-app -n $NAMESPACE"
    echo "  Scale app: kubectl scale deployment redis-app --replicas=3 -n $NAMESPACE"
    echo "  Delete all: kubectl delete namespace $NAMESPACE"
    echo ""
}

# Function to setup port forward
setup_port_forward() {
    print_status "Setting up port forward to access the application..."
    echo "The application will be available at http://localhost:8080"
    echo "Press Ctrl+C to stop port forwarding"
    echo ""
    kubectl port-forward service/redis-app-service 8080:80 -n $NAMESPACE
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  deploy          Build and deploy the application (default)"
    echo "  build           Build Docker image only"
    echo "  status          Show deployment status"
    echo "  port-forward    Setup port forwarding for local access"
    echo "  logs            Show application logs"
    echo "  delete          Delete the entire deployment"
    echo "  help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0              # Deploy the application"
    echo "  $0 build        # Build Docker image only"
    echo "  $0 status       # Show deployment status"
    echo "  $0 port-forward # Access app via port forward"
}

# Function to show logs
show_logs() {
    print_status "Showing application logs..."
    kubectl logs -f deployment/redis-app -n $NAMESPACE
}

# Function to delete deployment
delete_deployment() {
    print_warning "This will delete the entire Redis App deployment"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Deleting deployment..."
        kubectl delete namespace $NAMESPACE
        print_success "Deployment deleted"
    else
        print_status "Operation cancelled"
    fi
}

# Main execution
echo "🚀 Redis App Kubernetes Deployment"
echo ""

# Parse command line arguments
case "${1:-deploy}" in
    "build")
        check_prerequisites
        build_image
        ;;
    "deploy")
        check_prerequisites
        build_image
        load_image_to_cluster
        deploy_to_k8s
        show_status
        show_access_info
        ;;
    "status")
        show_status
        ;;
    "port-forward")
        setup_port_forward
        ;;
    "logs")
        show_logs
        ;;
    "delete")
        delete_deployment
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
