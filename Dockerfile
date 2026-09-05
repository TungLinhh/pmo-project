# PMO MVP - Multi-stage Dockerfile
# Stage 1: Build frontend
FROM node:20-alpine AS frontend-build
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm ci --no-audit --no-fund
COPY frontend/ ./
RUN npm run build

# Stage 2: Backend + serve frontend
FROM node:20-alpine
RUN apk add --no-cache bash tini postgresql-client
WORKDIR /app

# Install backend deps
COPY backend/package*.json ./backend/
RUN cd backend && npm ci --omit=dev --no-audit --no-fund

# Copy backend source
COPY backend/ ./backend/

# Copy drizzle migration files (needed for entrypoint)
COPY backend/drizzle ./backend/drizzle

# Copy built frontend
COPY --from=frontend-build /app/frontend/dist ./frontend/dist

# Create dirs
RUN mkdir -p /app/backend/data /app/backend/data/uploads /app/data

# Environment — PostgreSQL (was SQLite in v0.1.x)
ENV NODE_ENV=production \
    PORT=3000 \
    DB_HOST=postgres \
    DB_PORT=5432 \
    DB_NAME=pmo \
    DB_USER=pmo_user \
    DB_PASSWORD=pmo_dev_pwd

EXPOSE 3000

# Run migrations + start (entrypoint script)
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000/api/health || exit 1

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]
CMD ["node", "backend/src/index.js"]
