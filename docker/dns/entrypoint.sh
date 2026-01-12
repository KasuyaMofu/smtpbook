#!/bin/bash
set -e

DB_PATH="/var/lib/powerdns/pdns.sqlite3"
ZONE_DIR="/etc/powerdns/zones"

# Remove existing database and related files to start fresh
rm -f "$DB_PATH" "$DB_PATH-wal" "$DB_PATH-shm" "$DB_PATH-journal"

# Initialize SQLite database with PowerDNS schema
sqlite3 "$DB_PATH" < /usr/share/doc/pdns-backend-sqlite3/schema.sqlite3.sql 

# Import each zone file using zone2sql
for zonefile in "$ZONE_DIR"/*.zone; do
    if [ -f "$zonefile" ]; then
        filename=$(basename "$zonefile" .zone)
        echo "Importing zone: $filename"
        zone2sql --gsqlite --zone="$zonefile" --zone-name="$filename" | sqlite3 "$DB_PATH"
    fi
done

# Set proper permissions
chown pdns:pdns "$DB_PATH"

# Extract PTR records and generate Lua cache file
PTR_CACHE_FILE="/etc/powerdns/ptr-cache.lua"
echo "-- Auto-generated PTR cache" > "$PTR_CACHE_FILE"
echo "return {" >> "$PTR_CACHE_FILE"

sqlite3 "$DB_PATH" "SELECT content, name FROM records WHERE type='PTR' AND name LIKE '%.10.in-addr.arpa'" | while IFS='|' read -r hostname name; do
    # Convert reverse DNS name to IP (e.g., "10.1.255.10.in-addr.arpa" -> "10.255.1.10")
    ip=$(echo "$name" | sed 's/.in-addr.arpa$//' | awk -F. '{print $4"."$3"."$2"."$1}')
    echo "    [\"$ip\"] = \"$hostname\"," >> "$PTR_CACHE_FILE"
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
