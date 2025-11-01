#!/usr/bin/env sh
set -e

# Set directory ownerships
echo "Nextcloud directory ownerships: Starting"
if [ -n "${PODMAN_NEXTCLOUD_DATA_DIR_CONTAINER}" ] && [ -d "${PODMAN_NEXTCLOUD_DATA_DIR_CONTAINER}" ]; then
  chown www-data:www-data -R "${PODMAN_NEXTCLOUD_DATA_DIR_CONTAINER}"
else
  echo "Error: PODMAN_NEXTCLOUD_DATA_DIR_CONTAINER is not set or directory does not exist."
  exit 1
fi
if [ -n "${PODMAN_NEXTCLOUD_USER_DATA_DIR_CONTAINER}" ] && [ -d "${PODMAN_NEXTCLOUD_USER_DATA_DIR_CONTAINER}" ]; then
  chown www-data:www-data -R "${PODMAN_NEXTCLOUD_USER_DATA_DIR_CONTAINER}"
else
  echo "Error: PODMAN_NEXTCLOUD_USER_DATA_DIR_CONTAINER is not set or directory does not exist."
  exit 1
fi
echo "Nextcloud directory ownerships: Completed"

# Configure the Nextcloud instance
echo "Nextcloud script: Starting"
if [ -n "${PODMAN_MANAGER_NEXTCLOUD_SETUP_SCRIPT_FILE_CONTAINER}" ] && [ -e "${PODMAN_MANAGER_NEXTCLOUD_SETUP_SCRIPT_FILE_CONTAINER}" ]; then
  gosu www-data sh "${PODMAN_MANAGER_NEXTCLOUD_SETUP_SCRIPT_FILE_CONTAINER}"
else
  echo "Error: PODMAN_MANAGER_NEXTCLOUD_SETUP_SCRIPT_FILE_CONTAINER is not set or file does not exist."
  exit 1
fi
echo "Nextcloud script: Completed"

# Start the services
echo "Service: Starting cron"
# Run in foreground with log level 8 (debug)
crond -f -d 8
