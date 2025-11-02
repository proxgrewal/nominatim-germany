#!/bin/bash
set -euo pipefail

OSM_PBF="/nominatim/data.osm.pbf"
FLATNODE_FILE="/nominatim/flatnode.file"
PGDATA="/var/lib/postgresql/14/main"

mkdir -p /nominatim
chown -R nominatim:nominatim /nominatim

# Download PBF only if missing
if [ ! -f "$OSM_PBF" ]; then
    echo "Downloading Germany OSM extract..."
    curl -L -o "$OSM_PBF" https://download.geofabrik.de/europe/germany-latest.osm.pbf
else
    echo "Found existing OSM extract: $OSM_PBF"
fi

# Export env vars for Nominatim
export PBF_URL="$OSM_PBF"
export NOMINATIM_FLATNODE_FILE="$FLATNODE_FILE"
export THREADS=${THREADS:-$(nproc)}

echo "Using $THREADS threads..."
echo "Flatnode file: $NOMINATIM_FLATNODE_FILE"

# Import only if DB not initialized
if [ ! -f "$PGDATA/PG_VERSION" ]; then
    echo "Database not initialized. Starting import..."
    /app/init.sh --osmfile "$PBF_URL" \
                 --threads "$THREADS" \
                 --flatnodes "$NOMINATIM_FLATNODE_FILE"
else
    echo "Database already exists, skipping import."
fi

echo "Starting Nominatim..."
exec /app/run.sh
