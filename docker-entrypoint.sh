#!/bin/bash
# Docker entrypoint - run migrations then start backend
set -e

echo "=== PMO Docker entrypoint ==="
cd /app

# Apply schema if SQLite DB not exist
if [ ! -f "$SQLITE_PATH" ]; then
  echo "Initializing SQLite at $SQLITE_PATH..."
  node backend/scripts/init-schema.mjs || echo "schema init failed (non-fatal)"
fi

# Seed users if not exists
node backend/seed-users.mjs 2>&1 | tail -3 || echo "user seed skipped"

echo "=== Starting backend ==="
exec "$@"
