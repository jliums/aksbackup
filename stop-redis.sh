#!/bin/bash

# Simple script to stop Redis Docker container

CONTAINER_NAME="redis-app-redis"

echo "🛑 Stopping Redis Docker container..."

if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
    docker stop "$CONTAINER_NAME"
    echo "✅ Redis container stopped"
else
    echo "ℹ️  Redis container is not running"
fi

if docker ps -aq -f name="$CONTAINER_NAME" | grep -q .; then
    docker rm "$CONTAINER_NAME"
    echo "✅ Redis container removed"
fi

echo "🏁 Done!"
