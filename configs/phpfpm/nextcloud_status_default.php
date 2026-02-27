<?php

ini_set('display_errors', '1');
ini_set('display_startup_errors', '1');
ini_set('log_errors', '0');

try {
    $env_vars = getenv();

    # Check for Nextcloud status.php file
    if (isset($env_vars['PODMAN_NEXTCLOUD_DATA_DIR_CONTAINER'])) {
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
        # Prevent status.php from echoing output directly
        ob_start();
        require $nextcloud_status_file;
        ob_end_clean();
    } else {
        print("Nextcloud status script: Error: ".$nextcloud_status_file." file does not exist or is not readable\n");
        exit(1);
    }
    # Check health state
    # If status.php fails and $values does not exist it will also be unhealthy
    if (isset($values) && $values['installed'] && !$values['needsDbUpgrade']) {
        # Healthy
        exit(0);
    } else {
        # Unhealthy
        exit(1);
    }
} catch (Exception $e) {
    # Error and unhealthy
    print("Nextcloud status script: Error: " . $e->getMessage() . "\n");
    exit(1);
}
