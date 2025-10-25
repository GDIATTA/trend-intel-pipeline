#!/usr/bin/env bash
set -euo pipefail
PGHOST=${POSTGRES_HOST:-localhost}
PGPORT=${POSTGRES_PORT:-5432}
PGUSER=${POSTGRES_USER:-postgres}
PGPASSWORD=${POSTGRES_PASSWORD:-postgres}
PGDATABASE=${POSTGRES_DB:-trends}
export PGPASSWORD


until docker compose exec -T db pg_isready -U "$PGUSER" -d "$PGDATABASE"; do sleep 2; done


for f in sql/01_schema.sql sql/02_helpers.sql sql/03_rollups_views.sql; do
echo "Running $f"; cat "$f" | docker compose exec -T db psql -U "$PGUSER" -d "$PGDATABASE" ;
done