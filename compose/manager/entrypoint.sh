#!/usr/bin/env sh
set -e

# Check existence of directories
echo "Checking Nextcloud directories"
if ! [ -n "${PODMAN_NEXTCLOUD_DATA_DIR_CONTAINER}" ] && ! [ -d "${PODMAN_NEXTCLOUD_DATA_DIR_CONTAINER}" ]; then
  echo "Error: PODMAN_NEXTCLOUD_DATA_DIR_CONTAINER is not set or directory does not exist."
  exit 1
fi
if ! [ -n "${PODMAN_NEXTCLOUD_USER_DATA_DIR_CONTAINER}" ] && ! [ -d "${PODMAN_NEXTCLOUD_USER_DATA_DIR_CONTAINER}" ]; then
  echo "Error: PODMAN_NEXTCLOUD_USER_DATA_DIR_CONTAINER is not set or directory does not exist."
  exit 1
fi

echo "Execute healthcheck once"
php -f "${PODMAN_MANAGER_HEALTHCHECK_FILE_CONTAINER}"

echo "Service: Starting cron"
# Run supercronic in foreground
supercronic -split-logs "${PODMAN_MANAGER_CRON_ROOT_FILE_CONTAINER}"
