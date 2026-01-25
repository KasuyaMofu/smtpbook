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

# Create Poweradmin tables
sudo -u postgres psql -d "$PG_DB" << 'EOSQL'
-- Poweradmin schema for PostgreSQL
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(64) NOT NULL,
    password VARCHAR(128) NOT NULL,
    fullname VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    description TEXT,
    perm_templ INT DEFAULT 0,
    active INT DEFAULT 0,
    use_ldap INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS perm_items (
    id SERIAL PRIMARY KEY,
    name VARCHAR(64) NOT NULL,
    descr TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS perm_templ (
    id SERIAL PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    descr TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS perm_templ_items (
    id SERIAL PRIMARY KEY,
    templ_id INT NOT NULL,
    perm_id INT NOT NULL
);

CREATE TABLE IF NOT EXISTS zones (
    id SERIAL PRIMARY KEY,
    domain_id INT NOT NULL,
    owner INT NOT NULL,
    comment TEXT,
    zone_templ_id INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS zone_templ (
    id SERIAL PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    descr TEXT NOT NULL,
    owner INT NOT NULL
);

CREATE TABLE IF NOT EXISTS zone_templ_records (
    id SERIAL PRIMARY KEY,
    zone_templ_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(6) NOT NULL,
    content VARCHAR(255) NOT NULL,
    ttl INT NOT NULL,
    prio INT NOT NULL
);

CREATE TABLE IF NOT EXISTS records_zone_templ (
    domain_id INT NOT NULL,
    record_id INT NOT NULL,
    zone_templ_id INT NOT NULL
);

CREATE TABLE IF NOT EXISTS migrations (
    version VARCHAR(255) NOT NULL,
    apply_time INT NOT NULL
);

-- Insert default permission items if not exist
INSERT INTO perm_items (name, descr) SELECT 'zone_master_add', 'User is allowed to add new master zones.' WHERE NOT EXISTS (SELECT 1 FROM perm_items WHERE name='zone_master_add');
INSERT INTO perm_items (name, descr) SELECT 'zone_slave_add', 'User is allowed to add new slave zones.' WHERE NOT EXISTS (SELECT 1 FROM perm_items WHERE name='zone_slave_add');
INSERT INTO perm_items (name, descr) SELECT 'zone_content_view_own', 'User is allowed to see the content and meta data of zones he owns.' WHERE NOT EXISTS (SELECT 1 FROM perm_items WHERE name='zone_content_view_own');
INSERT INTO perm_items (name, descr) SELECT 'zone_content_edit_own', 'User is allowed to edit the content of zones he owns.' WHERE NOT EXISTS (SELECT 1 FROM perm_items WHERE name='zone_content_edit_own');
INSERT INTO perm_items (name, descr) SELECT 'zone_meta_edit_own', 'User is allowed to edit the meta data of zones he owns.' WHERE NOT EXISTS (SELECT 1 FROM perm_items WHERE name='zone_meta_edit_own');
INSERT INTO perm_items (name, descr) SELECT 'zone_content_view_others', 'User is allowed to see the content and meta data of zones he does not own.' WHERE NOT EXISTS (SELECT 1 FROM perm_items WHERE name='zone_content_view_others');
INSERT INTO perm_items (name, descr) SELECT 'zone_content_edit_others', 'User is allowed to edit the content of zones he does not own.' WHERE NOT EXISTS (SELECT 1 FROM perm_items WHERE name='zone_content_edit_others');
INSERT INTO perm_items (name, descr) SELECT 'zone_meta_edit_others', 'User is allowed to edit the meta data of zones he does not own.' WHERE NOT EXISTS (SELECT 1 FROM perm_items WHERE name='zone_meta_edit_others');
INSERT INTO perm_items (name, descr) SELECT 'search', 'User is allowed to perform searches.' WHERE NOT EXISTS (SELECT 1 FROM perm_items WHERE name='search');
INSERT INTO perm_items (name, descr) SELECT 'supermaster_view', 'User is allowed to view supermasters.' WHERE NOT EXISTS (SELECT 1 FROM perm_items WHERE name='supermaster_view');
INSERT INTO perm_items (name, descr) SELECT 'supermaster_add', 'User is allowed to add new supermasters.' WHERE NOT EXISTS (SELECT 1 FROM perm_items WHERE name='supermaster_add');
INSERT INTO perm_items (name, descr) SELECT 'supermaster_edit', 'User is allowed to edit supermasters.' WHERE NOT EXISTS (SELECT 1 FROM perm_items WHERE name='supermaster_edit');
INSERT INTO perm_items (name, descr) SELECT 'user_is_ueberuser', 'User has full access. God-like. Sniff.' WHERE NOT EXISTS (SELECT 1 FROM perm_items WHERE name='user_is_ueberuser');
INSERT INTO perm_items (name, descr) SELECT 'user_view_others', 'User is allowed to see other users and their details.' WHERE NOT EXISTS (SELECT 1 FROM perm_items WHERE name='user_view_others');
INSERT INTO perm_items (name, descr) SELECT 'user_add_new', 'User is allowed to add new users.' WHERE NOT EXISTS (SELECT 1 FROM perm_items WHERE name='user_add_new');
INSERT INTO perm_items (name, descr) SELECT 'user_edit_own', 'User is allowed to edit their own details.' WHERE NOT EXISTS (SELECT 1 FROM perm_items WHERE name='user_edit_own');
INSERT INTO perm_items (name, descr) SELECT 'user_edit_others', 'User is allowed to edit other users.' WHERE NOT EXISTS (SELECT 1 FROM perm_items WHERE name='user_edit_others');
INSERT INTO perm_items (name, descr) SELECT 'user_passwd_edit_others', 'User is allowed to edit the password of other users.' WHERE NOT EXISTS (SELECT 1 FROM perm_items WHERE name='user_passwd_edit_others');
INSERT INTO perm_items (name, descr) SELECT 'user_edit_templ_perm', 'User is allowed to change the permission template that is assigned to a user.' WHERE NOT EXISTS (SELECT 1 FROM perm_items WHERE name='user_edit_templ_perm');
INSERT INTO perm_items (name, descr) SELECT 'templ_perm_add', 'User is allowed to add new permission templates.' WHERE NOT EXISTS (SELECT 1 FROM perm_items WHERE name='templ_perm_add');
INSERT INTO perm_items (name, descr) SELECT 'templ_perm_edit', 'User is allowed to edit existing permission templates.' WHERE NOT EXISTS (SELECT 1 FROM perm_items WHERE name='templ_perm_edit');

-- Create admin permission template if not exists
INSERT INTO perm_templ (name, descr) SELECT 'Administrator', 'Administrator template with full rights.' WHERE NOT EXISTS (SELECT 1 FROM perm_templ WHERE name='Administrator');

-- Link all permissions to admin template
INSERT INTO perm_templ_items (templ_id, perm_id)
SELECT pt.id, pi.id FROM perm_templ pt, perm_items pi
WHERE pt.name = 'Administrator' AND pi.name = 'user_is_ueberuser'
AND NOT EXISTS (SELECT 1 FROM perm_templ_items WHERE templ_id = pt.id AND perm_id = pi.id);

-- Create admin user if not exists (password: admin, using bcrypt hash)
INSERT INTO users (username, password, fullname, email, description, perm_templ, active)
SELECT 'admin', '$2y$10$azUNGBP/l9jFCQ8cGw0CbuVrVjKn/pTw8re2sAETisLEGvJi0FLTq', 'Administrator', 'admin@example.com', 'Administrator',
    (SELECT id FROM perm_templ WHERE name='Administrator'), 1
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username='admin');
EOSQL

# Re-grant permissions after creating new tables
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

# Assign all zones to admin user in Poweradmin
PGPASSWORD=$PG_PASS psql -h 127.0.0.1 -U $PG_USER -d $PG_DB << 'EOSQL'
INSERT INTO zones (domain_id, owner, comment)
SELECT d.id, (SELECT id FROM users WHERE username='admin'), ''
FROM domains d
WHERE NOT EXISTS (SELECT 1 FROM zones z WHERE z.domain_id = d.id);
EOSQL

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
