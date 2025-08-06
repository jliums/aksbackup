# Multi-stage Dockerfile for Redis App
# Stage 1: Build the frontend
FROM node:20-alpine AS frontend-builder

WORKDIR /app

# Copy package files for frontend
COPY package*.json ./
COPY quasar.config.ts ./
COPY tsconfig.json ./

# Copy frontend source files needed by Quasar prepare
COPY src/ ./src/
COPY public/ ./public/
COPY index.html ./
COPY .env* ./
COPY eslint.config.js ./

# Copy server files for compilation
COPY server/ ./server/

# Install ALL dependencies (including dev dependencies for build)
RUN npm ci

# Copy rest of config files
COPY .prettierrc.json ./
COPY postcss.config.js ./

# Copy boot files
COPY src/boot/ ./src/boot/

# Build the frontend
RUN npm run build

# Stage 2: Build the backend and final image
FROM node:20-alpine AS production

WORKDIR /app

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy package files
COPY package.production.json ./package.json

# Install only runtime dependencies for backend (use npm install instead of ci for prod package)
RUN npm install && npm cache clean --force

# Copy backend source and compile it
COPY server/ ./server/

# Copy the built frontend from the build stage
COPY --from=frontend-builder /app/dist/spa ./public

# Create necessary directories and set permissions
RUN mkdir -p /app/logs && \
    chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "const http=require('http');const options={hostname:'localhost',port:3001,path:'/health',timeout:2000};const req=http.request(options,(res)=>{process.exit(res.statusCode===200?0:1)});req.on('error',()=>process.exit(1));req.on('timeout',()=>process.exit(1));req.end();"

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Use TypeScript with ts-node
CMD ["npm", "start"]
