#!/bin/bash
set -e

ZONE_DIR="/etc/powerdns/zones"
PG_VERSION=$(ls /usr/lib/postgresql/ | head -1)
PG_BIN="/usr/lib/postgresql/$PG_VERSION/bin"
PG_DATA="/var/lib/postgresql/$PG_VERSION/main"
PG_USER="pdns"
PG_DB="pdns"
PG_PASS="pdns"

echo "Detected PostgreSQL version: $PG_VERSION"
echo "PostgreSQL bin: $PG_BIN"
echo "PostgreSQL data: $PG_DATA"

# Create log directory
mkdir -p /var/log/postgresql
chown postgres:postgres /var/log/postgresql

# Initialize PostgreSQL if not already done
if [ ! -d "$PG_DATA" ]; then
    mkdir -p "$PG_DATA"
    chown postgres:postgres "$PG_DATA"
    chmod 700 "$PG_DATA"
    sudo -u postgres "$PG_BIN/initdb" -D "$PG_DATA"
fi

# Configure PostgreSQL to listen on all interfaces
cat > "$PG_DATA/postgresql.conf" << 'EOF'
listen_addresses = '*'
port = 5432
max_connections = 100
shared_buffers = 128MB
dynamic_shared_memory_type = posix
log_destination = 'stderr'
logging_collector = off
log_line_prefix = '%t '
log_timezone = 'UTC'
datestyle = 'iso, mdy'
timezone = 'UTC'
lc_messages = 'C'
lc_monetary = 'C'
lc_numeric = 'C'
lc_time = 'C'
default_text_search_config = 'pg_catalog.english'
EOF

# Configure PostgreSQL authentication (allow all connections with password)
cat > "$PG_DATA/pg_hba.conf" << 'EOF'
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     trust
host    all             all             127.0.0.1/32            md5
host    all             all             0.0.0.0/0               md5
EOF

chown postgres:postgres "$PG_DATA/postgresql.conf" "$PG_DATA/pg_hba.conf"

# Start PostgreSQL
sudo -u postgres "$PG_BIN/pg_ctl" -D "$PG_DATA" -l /var/log/postgresql/postgresql.log start

# Wait for PostgreSQL to be ready
until sudo -u postgres psql -c 'SELECT 1' > /dev/null 2>&1; do
    echo "Waiting for PostgreSQL to start..."
    sleep 1
done

# Create database and user
sudo -u postgres psql -c "CREATE USER $PG_USER WITH PASSWORD '$PG_PASS';" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE $PG_DB OWNER $PG_USER;" 2>/dev/null || true
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $PG_DB TO $PG_USER;"

# Initialize PowerDNS schema
sudo -u postgres psql -d "$PG_DB" -f /usr/share/doc/pdns-backend-pgsql/schema.pgsql.sql 2>/dev/null || true

# Grant permissions on tables
sudo -u postgres psql -d "$PG_DB" -c "GRANT ALL ON ALL TABLES IN SCHEMA public TO $PG_USER;"
sudo -u postgres psql -d "$PG_DB" -c "GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO $PG_USER;"

# Import each zone file using zone2sql
for zonefile in "$ZONE_DIR"/*.zone; do
    if [ -f "$zonefile" ]; then
        filename=$(basename "$zonefile" .zone)
        echo "Importing zone: $filename"
        zone2sql --gpgsql --zone="$zonefile" --zone-name="$filename" | PGPASSWORD=$PG_PASS psql -h 127.0.0.1 -U $PG_USER -d $PG_DB
    fi
done

# Extract PTR records and generate Lua cache file
PTR_CACHE_FILE="/etc/powerdns/ptr-cache.lua"
echo "-- Auto-generated PTR cache" > "$PTR_CACHE_FILE"
echo "return {" >> "$PTR_CACHE_FILE"

PGPASSWORD=$PG_PASS psql -h 127.0.0.1 -U $PG_USER -d $PG_DB -t -A -F'|' \
    -c "SELECT content, name FROM records WHERE type='PTR' AND name LIKE '%.10.in-addr.arpa'" | while IFS='|' read -r hostname name; do
    if [ -n "$hostname" ] && [ -n "$name" ]; then
        # Convert reverse DNS name to IP (e.g., "10.1.255.10.in-addr.arpa" -> "10.255.1.10")
        ip=$(echo "$name" | sed 's/.in-addr.arpa$//' | awk -F. '{print $4"."$3"."$2"."$1}')
        echo "    [\"$ip\"] = \"$hostname\"," >> "$PTR_CACHE_FILE"
    fi
done

echo "}" >> "$PTR_CACHE_FILE"
chown pdns:pdns "$PTR_CACHE_FILE"

# Create socket directory for recursor
mkdir -p /run/pdns-recursor
chown pdns:pdns /run/pdns-recursor

# Start PowerDNS Authoritative Server in background (port 5300)
pdns_server --daemon=yes

# Wait for authoritative server to be ready
sleep 1

rsyslogd

# Start PowerDNS Recursor in foreground (port 53)
# Query logs will be visible in docker compose up output
(/usr/sbin/pdns_recursor --config-dir=/etc/powerdns 2>&1 | grep --line-buffered "lua" | sed -u -e 's/subsystem=.*//' -e 's/msg="//' -e 's/\\//g' -e 's/$"//' -e 's/^.\{16\}//' | logger -t pdns-recursor) &

touch /var/log/syslog
chown syslog:adm /var/log/syslog
chmod 640 /var/log/syslog

sleep infinity
