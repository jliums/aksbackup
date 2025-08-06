# Redis App (dsfasfa)

A Quasar Vue.js application with Redis connectivity for managing Redis connections and monitoring ping entries.

## Features

- **Settings Page**: Configure Redis connection settings and ping timer intervals
- **Dashboard**: Execute Redis commands and view ping entries in a table
- **Real-time Updates**: Auto-refresh ping entries every 5 seconds
- **Backend Integration**: Node.js/Express server for Redis operations

## Technologies Used

- **Frontend**: Quasar Framework (Vue 3 + TypeScript)
- **Backend**: Node.js + Express + TypeScript
- **Database**: Redis
- **State Management**: Pinia
- **HTTP Client**: Axios

## Prerequisites

- Node.js (v18 or higher)
- npm or yarn
- Redis server running locally or remotely
- Docker (optional - for running Redis locally)

## Installation

1. Clone the repository and navigate to the project folder
2. Install dependencies:
   ```bash
   npm install
   ```

## Running Redis with Docker (Recommended for Development)

The easiest way to get started is to use the included Docker script to run Redis locally:

```bash
# Start Redis in Docker (default: localhost:6379, no password)
./start-redis.sh

# Start Redis with custom port
./start-redis.sh -p 6380

# Start Redis with password
./start-redis.sh -w mypassword

# Start Redis with custom port and password
./start-redis.sh -p 6380 -w mypassword

# Stop Redis container
./stop-redis.sh
# or
./start-redis.sh --stop

# View Redis logs
./start-redis.sh --logs

# Restart Redis
./start-redis.sh --restart

# Show help
./start-redis.sh --help
```

After starting Redis with Docker, use these connection settings in the app:

- **Host**: `localhost`
- **Port**: `6379` (or your custom port)
- **Password**: (leave empty unless you set one)
- **Database**: `0`

## Running the Application

### Development Mode

1. **Start the backend server:**

   ```bash
   npm run server:dev
   ```

   The server will run on `http://localhost:3001`

2. **Start the frontend (in a new terminal):**
   ```bash
   npm run dev
   ```
   The app will be available at `http://localhost:9000`

### Production Mode

1. **Build the frontend:**

   ```bash
   npm run build
   ```

2. **Start the backend server:**
   ```bash
   npm run server
   ```

## Usage

1. **Configure Redis Connection:**
   - Navigate to the Settings page
   - Enter your Redis host, port, password (if required), and database number
   - Click "Connect" to establish the connection

2. **Set Up Ping Timer:**
   - In the Settings page, configure the ping interval (in seconds)
   - Click "Start Ping Timer" to begin automated ping entries

3. **Query Redis:**
   - Go to the Dashboard page
   - Use the command interface to execute Redis commands
   - View ping entries in the table below

## Project Structure

```
redis-app/
├── src/                    # Frontend source code
│   ├── pages/             # Vue pages
│   │   ├── IndexPage.vue  # Dashboard page
│   │   └── SettingsPage.vue # Settings page
│   ├── stores/            # Pinia stores
│   │   └── redis.ts       # Redis state management
│   ├── types/             # TypeScript type definitions
│   └── ...
├── server/                # Backend server
│   └── index.ts          # Express server with Redis endpoints
└── ...
```

## API Endpoints

- `POST /api/redis/connect` - Connect to Redis
- `GET /api/redis/ping` - Test Redis connection
- `POST /api/redis/command` - Execute Redis command
- `POST /api/redis/start-ping` - Start ping timer
- `POST /api/redis/stop-ping` - Stop ping timer
- `GET /api/redis/ping-entries` - Get ping entries
- `DELETE /api/redis/ping-entries` - Clear ping entries

## Environment Variables

Create a `.env` file in the root directory:

```env
PORT=3001
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0
```

## Deployment

### Docker Deployment

For containerized deployment with Docker Compose:

```bash
# Start the entire stack (app + Redis)
./deploy-docker.sh up

# View logs
./deploy-docker.sh logs

# Stop the stack
./deploy-docker.sh down

# Build only
./deploy-docker.sh build
```

The application will be available at `http://localhost:3001`

### Kubernetes Deployment

For production deployment on Kubernetes:

```bash
# Deploy to Kubernetes (builds image and deploys)
./deploy-k8s.sh

# Build Docker image only
./deploy-k8s.sh build

# Check deployment status
./deploy-k8s.sh status

# Setup port forwarding for local access
./deploy-k8s.sh port-forward

# View application logs
./deploy-k8s.sh logs

# Delete the entire deployment
./deploy-k8s.sh delete
```

**Prerequisites for Kubernetes:**

- `kubectl` installed and configured
- Access to a Kubernetes cluster (local or cloud)
- For local testing: kind, minikube, or Docker Desktop with Kubernetes

**Access the application:**

1. **Port Forward (recommended for testing):**

   ```bash
   ./deploy-k8s.sh port-forward
   # Then visit http://localhost:8080
   ```

2. **Ingress (requires nginx-ingress controller):**
   - Configure your ingress controller
   - Update the domain in `k8s/redis-app-deployment.yaml`
   - Add the domain to your `/etc/hosts` file

3. **LoadBalancer (cloud environments):**
   - Change service type to `LoadBalancer` in the deployment YAML
   - Use the external IP provided by your cloud provider
