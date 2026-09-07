#!/bin/bash
# Docker entrypoint — wait for PG, apply migrations + seed, then start backend
set -e

echo "=== PMO Docker entrypoint ==="
cd /app

# Wait for Postgres (max 60s)
if [ -n "$DB_HOST" ]; then
  echo "Waiting for Postgres at $DB_HOST:${DB_PORT:-5432}..."
  for i in $(seq 1 60); do
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "${DB_PORT:-5432}" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; then
      echo "✓ Postgres ready"
      break
    fi
    if [ "$i" -eq 60 ]; then
      echo "❌ Postgres not ready after 60s — aborting"
      exit 1
    fi
    sleep 1
  done
fi

# Build DATABASE_URL from individual vars if not set
if [ -z "$DATABASE_URL" ] && [ -n "$DB_HOST" ]; then
  export DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT:-5432}/${DB_NAME}"
fi

# Apply migrations + seed (idempotent). FATAL on failure — never boot on a half-migrated DB.
echo "Initializing database..."
node backend/src/db/init.js
echo "✓ init ok"

echo "=== Starting backend ==="
exec "$@"
