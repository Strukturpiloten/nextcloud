<?php

ini_set('display_errors', '1');
ini_set('display_startup_errors', '1');
ini_set('log_errors', '0');

try {
    $env_vars = getenv();

    # Check for Nextcloud status.php file
    if (
        isset($env_vars['PODMAN_NEXTCLOUD_DATA_DIR_CONTAINER'])
    ) {
        $nextcloud_status_file = $env_vars['PODMAN_NEXTCLOUD_DATA_DIR_CONTAINER'] . "/status.php";
    } else {
        print("Nextcloud status script: Error: PODMAN_NEXTCLOUD_DATA_DIR_CONTAINER is not set\n");
        exit(1);
    }

    # Include the Nextcloud status.php file
    if (
        is_file($nextcloud_status_file) &&
        is_readable($nextcloud_status_file)
    ) {
        # Include the status.php file: $values variable will be available afterwards
        require $nextcloud_status_file;
    } else {
        print("Nextcloud status script: Error: ".$nextcloud_status_file." file does not exist or is not readable\n");
        exit(1);
    }
    # Create status file for healthcheck
    $healthcheck_file = "/dev/shm/nextcloud_status_healthy";
    if ($values['installed'] && !$values['needsDbUpgrade']) {
        # Healthy: Create file
        $file = fopen($healthcheck_file, "w");
        fclose($file);
    } else {
        # Unhealthy: Delete file
        if (file_exists($healthcheck_file)) {
            unlink($healthcheck_file);
        }
    }
    exit(0);
} catch (Exception $e) {
    print("Nextcloud status script: Error: " . $e->getMessage() . "\n");
    # Unhealthy: Delete file
    if (file_exists($healthcheck_file)) {
        unlink($healthcheck_file);
    }
    exit(1);
}
