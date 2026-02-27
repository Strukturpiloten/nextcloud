<?php

ini_set('display_errors', '1');
ini_set('display_startup_errors', '1');
ini_set('log_errors', '0');

print("Nextcloud configuration script: started\n");

try {
    $env_vars = getenv();

    # Check for Nextcloud config.php file
    if (isset($env_vars['PODMAN_NEXTCLOUD_DATA_DIR_CONTAINER'])) {
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

    # Required environment variables
    $required_env_vars = [
        # SQL databse
        'NC_dbtype',
        'NC_dbhost',
        'NC_dbname',
        'NC_dbuser',
        'NC_dbpassword',
        # Admin user
        'NC_admin_user',
        'NC_admin_password',
    ];

    # Check and set required environment variables
    foreach ($required_env_vars as $env_var) {
        $config_name = ltrim($env_var, 'NC_');
        if (empty($env_vars[$env_var])) {
            print("Nextcloud configuration script: Error: Required environment variable ".$env_var." is not set\n");
            exit(1);
        } else {
            $CONFIG[$config_name] = $env_vars[$env_var];
        }
    }

    # Optional environment variables
    $optional_env_vars = [
        # Mail
        'NC_mail_sendmailmode',
        'NC_mail_smtpmode',
        'NC_mail_smtpsecure',
        'NC_mail_from_address',
        'NC_mail_domain',
        'NC_mail_smtphost',
        'NC_mail_smtpport',
        'NC_mail_smtpauth',
        'NC_mail_smtpname',
        'NC_mail_smtppassword',
    ];

    # Set/Unset optional environment variables
    foreach ($optional_env_vars as $env_var) {
        $config_name = ltrim($env_var, 'NC_');
        if (!empty($env_vars[$env_var])) {
            $CONFIG[$config_name] = $env_vars[$env_var];
        } elseif (empty($env_vars[$env_var]) && array_key_exists($config_name, $CONFIG)) {
            unset($CONFIG[$config_name]);
        }
    }

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
