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

echo "Manager script: Start configuration"

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

echo "Manager script: Configuration completed"
exit 0
