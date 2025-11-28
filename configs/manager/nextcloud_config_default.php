<?php

ini_set('display_errors', '1');
ini_set('display_startup_errors', '1');
ini_set('log_errors', '0');

print("Nextcloud configuration script: started\n");

# TODO @TheRealBecks: Remove temporary sleep
print("Temporary sleep for 30 seconds");
sleep(30);


try {
    $env_vars = getenv();

    # Check for Nextcloud config.php file
    if (
        isset($env_vars['PODMAN_NEXTCLOUD_DATA_DIR_CONTAINER'])
    ) {
        $nextcloud_config_file = $env_vars['PODMAN_NEXTCLOUD_DATA_DIR_CONTAINER'] . "/config/config.php";
    } else {
        print("Nextcloud configuration script: Error: PODMAN_NEXTCLOUD_DATA_DIR_CONTAINER is not set\n");
        exit(1);
    }

    # Include the Nextcloud config.php file
    if (
        is_file($nextcloud_config_file) &&
        is_readable($nextcloud_config_file)
    ) {
        # Include the config.php file: $CONFIG variable will be available afterwards
        require $nextcloud_config_file;
    } else {
        print("Nextcloud configuration script: Error: ".$nextcloud_config_file." file does not exist or is not readable\n");
        exit(1);
    }

    # Check if all environment variables are set
    $required_env_vars = [
        # SQL databse
        'NC_dbhost',
        'NC_dbname',
        'NC_dbuser',
        'NC_dbpassword',
        # admin user
        'NC_admin_user',
        'NC_admin_password',
    ];

    # Check if all required environment variables are set
    foreach ($required_env_vars as $env_var) {
        if (empty($env_vars[$env_var])) {
            print("Nextcloud configuration script: Error: Required environment variable ".$env_var." is not set\n");
            exit(1);
        }
    }

    # Change the settings with the environment variables
    $CONFIG['dbhost'] = $env_vars['NC_dbhost'];
    $CONFIG['dbname'] = $env_vars['NC_dbname'];
    $CONFIG['dbuser'] = $env_vars['NC_dbuser'];
    $CONFIG['dbpassword'] = $env_vars['NC_dbpassword'];
    $CONFIG['admin_user'] = $env_vars['NC_admin_user'];
    $CONFIG['admin_password'] = $env_vars['NC_admin_password'];

    # Set the to be written content
    $config_output = "<?php\n\n\$CONFIG = " . var_export($CONFIG, true) . ";\n";

    # Write the config.php file
    $config_file = new SplFileObject(filename: $nextcloud_config_file, mode:"w");
    $config_file->fwrite(data: $config_output);
    $config_file = null;

    print("Nextcloud configuration script: completed\n");
} catch (Exception $e) {
    print("Nextcloud configuration script: Error: " . $e->getMessage() . "\n");
    exit(1);
}

exit(0);
