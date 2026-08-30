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
RUN apk add --no-cache bash tini
WORKDIR /app

# Install backend deps
COPY backend/package*.json ./backend/
RUN cd backend && npm ci --omit=dev --no-audit --no-fund

# Copy backend source
COPY backend/ ./backend/

# Copy built frontend
COPY --from=frontend-build /app/frontend/dist ./frontend/dist

# Create data dir (mounted as volume in real deploy)
RUN mkdir -p /app/backend/data /app/backend/data/uploads

# Environment
ENV NODE_ENV=production
ENV PORT=3000
ENV DB_DRIVER=sqlite
ENV SQLITE_PATH=/app/backend/data/pmo.db

EXPOSE 3000

# Run migration + seed (idempotent) before start
# Use ENTRYPOINT script so migration errors fail the container
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000/api/health || exit 1

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]
CMD ["node", "backend/src/index.js"]
