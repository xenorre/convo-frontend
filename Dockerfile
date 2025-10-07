# =====================================================
# Multi-stage Docker build for React TypeScript app
# =====================================================

# -----------------------------------------------------
# Stage 1: Build Stage
# -----------------------------------------------------
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs
RUN adduser -S reactjs -u 1001

# Copy package files
COPY package*.json ./

    # Install all dependencies (including dev dependencies needed for build)
    RUN npm ci --no-audit --no-fund

# Copy source code
COPY . .

# Set build-time environment variables
ARG VITE_API_URL
ARG VITE_WS_URL
ARG VITE_NODE_ENV=production
ARG VITE_APP_NAME=ConvoChat

ENV VITE_API_URL=$VITE_API_URL
ENV VITE_WS_URL=$VITE_WS_URL
ENV VITE_NODE_ENV=$VITE_NODE_ENV
ENV VITE_APP_NAME=$VITE_APP_NAME

# Build the application
RUN npm run build

# Remove dev dependencies to reduce image size
RUN npm prune --production

# -----------------------------------------------------
# Stage 2: Production Stage
# -----------------------------------------------------
FROM nginx:1.25-alpine AS production

# Install curl for health checks
RUN apk add --no-cache curl

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx-default.conf /etc/nginx/conf.d/default.conf

# Copy built application from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy health check script
COPY docker/healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/healthcheck.sh

# Create nginx user and set permissions
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d
RUN touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

# Switch to nginx user for security
USER nginx

# Expose port
EXPOSE 8080

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh

# Start nginx
CMD ["nginx", "-g", "daemon off;"]