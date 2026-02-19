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

# Configure the Nextcloud instance
echo "Nextcloud script: Starting"
if [ -n "${PODMAN_INSTALLER_NEXTCLOUD_SETUP_SCRIPT_FILE_CONTAINER}" ] && [ -e "${PODMAN_INSTALLER_NEXTCLOUD_SETUP_SCRIPT_FILE_CONTAINER}" ]; then
  sh "${PODMAN_INSTALLER_NEXTCLOUD_SETUP_SCRIPT_FILE_CONTAINER}"
else
  echo "Error: PODMAN_INSTALLER_NEXTCLOUD_SETUP_SCRIPT_FILE_CONTAINER is not set or file does not exist."
  exit 1
fi
echo "Nextcloud script: Completed"

echo "Nextcloud setup completed. Installer container finished."
