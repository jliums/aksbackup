# Copilot Instructions for Redis App

<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

This is a Quasar Vue.js application with Redis connectivity. The project includes:

## Key Features:

- **Settings Page**: Redis connection configuration and ping timer settings
- **Main Page**: Redis query interface and ping entries display in a table
- **Backend Integration**: Node.js/Express server for Redis operations
- **TypeScript**: Full TypeScript support throughout the application

## Technologies Used:

- Quasar Framework (Vue 3 with TypeScript)
- Redis client for Node.js
- Pinia for state management
- Axios for HTTP requests
- Composition API with script setup

## Code Style Guidelines:

- Use TypeScript interfaces for type definitions
- Follow Vue 3 Composition API best practices
- Use Quasar components and styling
- Implement proper error handling for Redis operations
- Keep components modular and reusable

## Project Structure:

- `src/pages/` - Main application pages
- `src/components/` - Reusable Vue components
- `src/stores/` - Pinia stores for state management
- `src/types/` - TypeScript type definitions
- `server/` - Backend API for Redis operations
