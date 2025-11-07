# ==============================================================================
# Multi-stage build for React frontend
# ==============================================================================

# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Accept build argument for API URL
ARG VITE_API_URL=http://localhost:3000
ENV VITE_API_URL=${VITE_API_URL}

# Copy package files
COPY package*.json ./

# Install ALL dependencies (including dev dependencies needed for build)
RUN npm ci --silent

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM nginx:alpine AS production

# Copy custom nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy built application from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Add healthcheck
RUN apk add --no-cache curl
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:80/ || exit 1

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]