#!/usr/bin/env sh

#############################
# Be cautious with 'set' commands as some commands rely on ignoring errors.
#
# Be cautious with your changes as the Nextcloud or related services may fail.
# Wrongly configured databases will lead to a failed Nextcloud startup and therefore
# also 'occ' commands will fail immediately. If you need to fix your database configuration
# or other service configurations, please stop the Pod first.
# You can then open your Nextcloud 'config.php' in a text editor and fix the settings there.
#############################

set -e

echo "Installer script: Start configuration"

# Configure the SQL database type
if [ "${PODMAN_SQL_DATABASE}" = "mariadb" ]; then
  if [ -n "${MARIADB_HOST}" ] && [ -n "${MARIADB_DB}" ] && [ -n "${MARIADB_USER}" ] && [ -n "${MARIADB_PASSWORD}" ]; then
    echo "MariaDB will be used as database type"

    export NC_dbtype="mysql"
    export NC_dbhost="${MARIADB_HOST}"
    export NC_dbname="${MARIADB_DB}"
    export NC_dbuser="${MARIADB_USER}"
    export NC_dbpassword="${MARIADB_PASSWORD}"
    
    NC_dbtype="mysql"
    NC_dbhost="${MARIADB_HOST}"
    NC_dbname="${MARIADB_DB}"
    NC_dbuser="${MARIADB_USER}"
    NC_dbpassword="${MARIADB_PASSWORD}"
  else
    echo "Error: PODMAN_SQL_DATABASE has value 'mariadb' but MARIADB_HOST, MARIADB_DB, MARIADB_USER, and MARIADB_PASSWORD are not all set"
    exit 1
  fi
elif [ "${PODMAN_SQL_DATABASE}" = "mysql" ]; then
  if [ -n "${MYSQL_HOST}" ] && [ -n "${MYSQL_DB}" ] && [ -n "${MYSQL_USER}" ] && [ -n "${MYSQL_PASSWORD}" ]; then
    echo "MySQL will be used as database type"

    export NC_dbtype="mysql"
    export NC_dbhost="${MYSQL_HOST}"
    export NC_dbname="${MYSQL_DB}"
    export NC_dbuser="${MYSQL_USER}"
    export NC_dbpassword="${MYSQL_PASSWORD}"

    NC_dbtype="mysql"
    NC_dbhost="${MYSQL_HOST}"
    NC_dbname="${MYSQL_DB}"
    NC_dbuser="${MYSQL_USER}"
    NC_dbpassword="${MYSQL_PASSWORD}"
  else
    echo "Error: PODMAN_SQL_DATABASE has value 'mysql' but MYSQL_HOST, MYSQL_DB, MYSQL_USER, and MYSQL_PASSWORD are not all set"
    exit 1
  fi
elif [ "${PODMAN_SQL_DATABASE}" = "postgres" ]; then
  if [ -n "${POSTGRES_HOST}" ] && [ -n "${POSTGRES_DB}" ] && [ -n "${POSTGRES_USER}" ] && [ -n "${POSTGRES_PASSWORD}" ]; then
    echo "PostgreSQL will be used as database type"

    export NC_dbtype="pgsql"
    export NC_dbhost="${POSTGRES_HOST}"
    export NC_dbname="${POSTGRES_DB}"
    export NC_dbuser="${POSTGRES_USER}"
    export NC_dbpassword="${POSTGRES_PASSWORD}"
    
    NC_dbtype="pgsql"
    NC_dbhost="${POSTGRES_HOST}"
    NC_dbname="${POSTGRES_DB}"
    NC_dbuser="${POSTGRES_USER}"
    NC_dbpassword="${POSTGRES_PASSWORD}"
  else
    echo "Error: PODMAN_SQL_DATABASE has value 'postgres' but POSTGRES_HOST, POSTGRES_DB, POSTGRES_USER, and POSTGRES_PASSWORD are not all set"
    exit 1
  fi
else
  echo "Error: Unsupported or empty PODMAN_SQL_DATABASE value: ${PODMAN_SQL_DATABASE}"
  exit 1
fi

cd "${PODMAN_NEXTCLOUD_DATA_DIR_CONTAINER}"

installed=false

# Check if nextcloud is already installed
if [ -f occ ]; then
  installed=true
  version_installed=$(php occ --version | awk '{print $2}')
fi

# Install Nextcloud
if [ "$installed" = false ]; then
  echo "Nextcloud installation started"
  echo "Nextcloud v${NEXTCLOUD_VERSION} will be installed"

  wget -O "nextcloud-${NEXTCLOUD_VERSION}.tar.bz2" \
    "https://github.com/nextcloud-releases/server/releases/download/v${NEXTCLOUD_VERSION}/nextcloud-${NEXTCLOUD_VERSION}.tar.bz2"
  echo "Nextcloud download completed"

  tar -xjf "nextcloud-${NEXTCLOUD_VERSION}.tar.bz2" --strip-components=1
  rm "nextcloud-${NEXTCLOUD_VERSION}.tar.bz2"
  echo "Nextcloud unpacking completed"

  php occ maintenance:install \
    -n \
    --data-dir "${NC_datadirectory}" \
    --database "${NC_dbtype}" \
    --database-host "${NC_dbhost}" \
    --database-name "${NC_dbname}" \
    --database-user "${NC_dbuser}" \
    --database-pass "${NC_dbpassword}" \
    --admin-user "${NC_admin_user}" \
    --admin-pass "${NC_admin_password}"
  
  echo "Nextcloud installation completed"
fi

echo "Nextcloud Setup: started"

# Changing the database settings isn't working with the 'occ' command as it always needs a working database connection.
# Therefore we will directly edit the config.php file.
if [ -n "${PODMAN_INSTALLER_NEXTCLOUD_CONFIG_SCRIPT_FILE_CONTAINER}" ]; then
  echo "Run Nextcloud configuration script: ${PODMAN_INSTALLER_NEXTCLOUD_CONFIG_SCRIPT_FILE_CONTAINER}"
  php -c "${PHP_INI_DIR}/php.ini-development" "${PODMAN_INSTALLER_NEXTCLOUD_CONFIG_SCRIPT_FILE_CONTAINER}"
else
  echo "Error: PODMAN_INSTALLER_NEXTCLOUD_CONFIG_SCRIPT_FILE_CONTAINER is not set"
  exit 1
fi

# Nextcloud has some strange behaviour when executing commands:
# Return code 1 with "already installed" message instead of 0 when an app is already installed
# Return code 1 with "Could not download app" when trying to install an app that is already installed, but disabled
# Warning log messages instead of error messages when commands clearly fail
# So let's ignore ALL error and warning and simply try to execute all 'occ' commands...:
set +e

# TODO @TheRealBecks: Manual configuration of "trusted_domains" as a workaround for https://github.com/nextcloud/server/issues/49658
# Reset trusted_domains
echo "Nextcloud trusted_domains"
php occ -n config:system:set trusted_domains --type=string --value="localhost"
# Set trusted_domains
counter=0
for domain in ${NEXTCLOUD_TRUSTED_DOMAINS}; do
    php occ -n config:system:set trusted_domains ${counter} --type=string --value="${domain}"
    counter=$((counter + 1))
done

# Valkey
php occ -n config:system:set 'redis' 'host' --type=string --value="${VALKEY_HOST}"
php occ -n config:system:set 'redis' 'port' --type=string --value="${VALKEY_PORT}"
php occ -n config:system:set 'redis' 'dbindex' --type=integer --value="${NEXTCLOUD_REDIS_DBINDEX}"
php occ -n config:system:set 'redis' 'timeout' --type=float --value="${NEXTCLOUD_REDIS_TIMEOUT}"
php occ -n config:system:set 'redis' 'read_timeout' --type=float --value="${NEXTCLOUD_REDIS_READ_TIMEOUT}"
php occ -n config:system:set 'memcache.local' --type=string --value='\OC\Memcache\Redis'
php occ -n config:system:set 'memcache.distributed' --type=string --value='\OC\Memcache\Redis'
php occ -n config:system:set 'memcache.locking' --type=string --value='\OC\Memcache\Redis'

# Whiteboard
echo "Nextcloud app: Configure Whiteboard"
php occ -n config:app:set whiteboard collabBackendUrl --value="https://${NEXTCLOUD_DOMAIN}/whiteboard"
php occ -n -q config:app:set whiteboard jwt_secret_key --value="${WHITEBOARD_JWT_SECRET_KEY}"

# Apps: install, remove, enable, disable, update
echo "Nextcloud app: Install Apps"
for app in ${NEXTCLOUD_APPS_INSTALLED}; do
    php occ -n app:install --verbose "${app}"
done

echo "Nextcloud app: Remove Apps"
for app in ${NEXTCLOUD_APPS_REMOVED}; do
    php occ -n app:remove --verbose "${app}"
done

echo "Nextcloud app: Enable Apps"
for app in ${NEXTCLOUD_APPS_ENABLED}; do
    php occ -n app:enable --verbose "${app}"
done

echo "Nextcloud app: Disable Apps"
for app in ${NEXTCLOUD_APPS_DISABLED}; do
    php occ -n app:disable --verbose "${app}"
done

echo "Nextcloud app: Update Apps"
php occ -n app:update --all

# App: files_antivirus
echo "Nextcloud app: Configure files_antivirus"
php occ -n config:app:set --value "${CLAMAV_AV_HOST}" --type=string files_antivirus av_host
php occ -n config:app:set --value "${CLAMAV_AV_PORT}" --type=string files_antivirus av_port
php occ -n config:app:set --value "${CLAMAV_AV_MODE}" --type=string files_antivirus av_mode
php occ -n config:app:set --value "${CLAMAV_AV_SOCKET}" --type=string files_antivirus av_socket
php occ -n config:app:set --value "${CLAMAV_AV_CMD_OPTIONS}" --type=string files_antivirus av_cmd_options
php occ -n config:app:set --value "${CLAMAV_AV_INFECTION_ACTION}" --type=string files_antivirus av_infected_action
php occ -n config:app:set --value "${CLAMAV_AV_STREAM_MAX_LENGTH}" --type=string files_antivirus av_stream_max_length
php occ -n config:app:set --value "${CLAMAV_AV_MAX_FILE_SIZE}" --type=string files_antivirus av_max_file_size
php occ -n config:app:set --value "${CLAMAV_AV_SCAN_FIRST_BYTES}" --type=string files_antivirus av_scan_first_bytes
php occ -n config:app:set --value "${CLAMAV_AV_ICAP_MODE}" --type=string files_antivirus av_icap_mode
php occ -n config:app:set --value "${CLAMAV_AV_ICAP_REQUEST_SERVICE}" --type=string files_antivirus av_icap_request_service
php occ -n config:app:set --value "${CLAMAV_AV_ICAP_RESPONSE_HEADER}" --type=string files_antivirus av_icap_response_header
php occ -n config:app:set --value "${CLAMAV_AV_ICAP_TLS}" --type=string files_antivirus av_icap_tls
php occ -n config:app:set --value "${CLAMAV_AV_BLOCK_UNSCANNABLE}" --type=string files_antivirus av_block_unscannable
php occ -n config:app:set --value "${CLAMAV_AV_BLOCK_UNREACHABLE}" --type=string files_antivirus av_block_unreachable

# Other
echo "Nextcloud system: Set maintenance window"
# 01:00am UTC and 05:00am UTC 
php occ -n config:system:set maintenance_window_start --type=integer --value=1

echo "Nextcloud background jobs: cron"
php occ -n background:cron

# Add missing database configs
echo "Nextcloud DB: Add missing columns"
php occ -n db:add-missing-columns

echo "Nextcloud DB: Add missing indices"
php occ -n db:add-missing-indices

echo "Nextcloud DB: Add missing primary keys"
php occ -n db:add-missing-primary-keys

echo "Nextcloud maintenance: Start repair operations, can take quite some time"
php occ -n maintenance:repair --include-expensive

echo "Installer script: Configuration completed"

# Set the maintenance mode according to the environment setting
if [ "${NEXTCLOUD_MAINTENANCE}" = "off" ]; then
  echo "Nextcloud maintenance: mode off"
  php occ -n maintenance:mode --off
else
  echo "Nextcloud maintenance: mode on - as per environment setting"
fi

echo "Installer script: Setup completed successfully"
exit 0
