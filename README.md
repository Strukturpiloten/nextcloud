# podman_nextcloud

A Nextcloud container solution using Free and Open Source (FOSS) tools 🤝

This project is being tested againt [Podman](https://github.com/containers/podman) as container runtime with [docker/compose](https://github.com/docker/compose) as compose engine.

Future goals are to also support Kubernetes.

> [!NOTE]  
> 🚧🚧🚧
> 
> This project is still under heavy development. Do not use in production setups! 
> There will be breaking changes in the near future.
> 
> 🚧🚧🚧

## Index

- [Support by Strukturpiloten](#support-by-strukturpiloten)
- [Motivation](#motivation)
- [Other Projects](#other-projects)
  - [Nextcloud All-in-One](#nextcloud-all-in-one)
  - [Nextcloud Docker Container](#nextcloud-docker-container)
  - [Linuxserver Nextcloud](#linuxserver-nextcloud)
- [Prerequisites](#prerequisites)
  - [Podman Setup](#podman-setup)
  - [User Setup](#user-setup)
  - [Allow Non-Root Users to Bind to Privileged Ports](#allow-non-root-users-to-bind-to-privileged-ports)
  - [Firewall](#firewall)
- [Installation](#installation)
  - [Preparation](#preparation)
  - [Environment Variables](#environment-variables)
  - [Configs](#configs)
    - [Minimal Example Setup](#minimal-example-setup)
    - [All Configs](#all-configs)
  - [SSL Certificates](#ssl-certificates)
    - [Creating Self-Signed SSL Certificates](#creating-self-signed-ssl-certificates)
  - [First Start](#first-start)
- [Resources](#resources)
  - [PHP-FPM](#php-fpm)
  - [Nginx](#nginx)
  - [Whiteboard](#whiteboard)
  - [TURN](#turn)
  - [HPB](#hpb)
  - [Recording](#recording)
- [External Issues affecting this Project](#external-issues-affecting-this-project)
  - [Nextcloud](#nextcloud)
- [Contribution](#contribution)

## Support by Strukturpiloten

<p align="center">
  <a href="https://www.strukturpiloten.de"><img src="https://www.strukturpiloten.de/wp-content/uploads/2025/04/logo-strukturpiloten-1.png" alt="Strukturpiloten Logo" width="40%" height="40%"></a>
</p>

[Strukturpiloten](https://www.strukturpiloten.de) is a German IT consulting company focusing on process optimization, automaton, Linux, networking, and DevOps. If you need professional support for your IT projects, feel free to [contact](https://www.strukturpiloten.de/kontakt/) us! 👋

## Motivation

We at [Strukturpiloten](https://www.strukturpiloten.de) love Free and Open Source Software (FOSS) and therefore also want to use FOSS software as underlay. When it comes to container runtimes we prefer [Podman](https://github.com/containers/podman) ([Website](https://podman.io/)) over Docker due to its daemonless architecture and improved security model.

There are already official and community backed Nextcloud Docker containers available, but none of them support Podman out of the box. This project aims to provide an easy to use Nextcloud setup using Podman as container runtime in the first step. Furthermore we intend to provide a Kubernetes setup that can be derived from this Podman project in the near future.

## Other Projects

All other projects that we know of use Docker as container runtime. The official Nextcloud container even needs a `docker.sock` bind mount to work.

### Nextcloud All-in-One

Official Nextcloud [All-in-One](https://github.com/nextcloud/all-in-one) Docker project. To run this project root access to the `docker.sock` is required.

### Nextcloud Docker Container

Community backed [Nextcloud](https://github.com/nextcloud/docker) Docker container. Can be used as stand-alone container that accesses other services (database, etc.) or can be used with a `compose.yaml` file.

### Linuxserver Nextcloud

The LinuxServer.io project also has a [Nextcloud](https://docs.linuxserver.io/images/docker-nextcloud/) docker container. Can be used as stand-alone container that accesses other services (database, etc.) or can be used with a `compose.yaml` file.

## Prerequisites

### Podman Setup

Podman requires a proper setup for non-root users. Please follow the official Podman [installation instructions](https://podman.io/docs/installation).

The following packages need to be installed, but package names may differ depending on your Linux distribution:

- `podman`
- `docker-compose` - not to be confused with `podman-compose`!

Sadly this project is not compatible with `podman-compose` as `podman-compose` lacks several fundamental features that are already implemented in `docker-compose` 😢

Podman Quadlets have not been implemented by this project as many people using Docker and `docker/compose` don't know about Quadlets yet. Therefore we stick to the more common `docker/compose` way of doing things.

It is also recommended to set up IPv4 and IPv6 (dual-stack) on your system.

### User Setup

There's a whole example setup with commands at the end of this chapter.

Create a username and group for running the containers, e.g.:

- User: `podman`
- Group: `podman`

Make your user services reboot persistent by enabling linger for your `podman` user:

```bash
loginctl enable-linger podman
```

Also add the `podman.sock` systemd socket for non-root users. Run this command with your `podman` user:

```bash
systemctl --user enable --now podman.socket
```

The whole setup looks like this:

```bash
username=podman
groupadd ${username}
useradd -g ${username} -m ${username}
loginctl enable-linger ${username}
sudo -u ${username} systemctl --user enable --now podman.socket
```

You can access the `podman` user with another account with `sudo` rights:

```bash
sudo -i -u podman
```

### Allow Non-Root Users to Bind to Privileged Ports

Allow non-root users to bind to privileged ports <1024.

Run these commands as root to allow non-root users to bind to privileged ports starting from port 0. The second command will make it persistent across reboots:

> [!CAUTION]
> This change impacts the whole system and allow also non-root users to bind to privileged ports. Make sure that you understand the security implications of this change.

```bash
echo 'net.ipv4.ip_unprivileged_port_start=0' >> /etc/sysctl.conf
sysctl -p
```

### Firewall

Make sure that the following ports and protocols are open in your firewall:

- `80/tcp`: HTTP/1.1, HTTP/2
- `80/udp`: HTTP/3
- `443/tcp`: HTTP/1.1 with TLS/SSL, HTTP/2 with TLS
- `443/udp`: HTTP/3 with TLS

## Installation

This section will show a step-by-step example installation.

The setup differentiates between these directories:

- This repository is only used for the logic and **not** your (user) data and configs
- `data`: Store your (user) files in one or multiple data directories
- `configs`: Store your config files in one or multiple config directories

Therefore these directories will be used for this example setup:

- `/mnt/nextcloud`: Parent working directory (pwd)
- `/mnt/nextcloud/configs`: Your config files
- `/mnt/nextcloud/data`: Your (user) files
- `/mnt/nextcloud/podman-nextcloud`: This repository

### Preparation

So let's start:

```bash
cd /mnt/nextcloud
```

```bash
mkdir data
mkdir configs
```

Clone the repository to your local machine:

```bash
git clone https://github.com/Strukturpiloten/podman-nextcloud.git
```

There are now three directories in `/mnt/nextcloud`:

- `configs`
- `data`
- `podman-nextcloud`

### Environment Variables

Copy the example environment file and edit it to your needs:

```bash
cd /mnt/nextcloud
```

```bash
cp podman-nextcloud/.env.example configs/.env
```

Check if `UID` and `GID` variables are set for your `podman` user. You can get the values with these commands:

```bash
echo "$UID"
echo "$GID"
```

If they are not set you can get the values:

```bash
id -u
id -g
```

Edit the `configs/.env` file and set at least the following variables:

- `PODMAN_NAMESPACE`: E.g. `customername`, `yourcompanyname`
- `PODMAN_STAGE`: E.g. `test`,  `prod`
- Change `PODMAN_UID` and `PODMAN_GID` if needed
- All variables containing the following values:
  - `/your/absolute/path/to/`: Set the absolute paths to your data and config directories
  - `a_secure_password`: Use a separate secure password for each variable
  - `domain.example.com`: Your domain name
- `NEXTCLOUD_SMTP_`, `NEXTCLOUD_MAIL_` and `NEXTCLOUD_DEFAULT_` variables

The following variables will **not** be changed for this example setup, because we will use the default config files where possible. These are the default values that are also present in our `.env` file. The `configs` path refers to `/mnt/nextcloud/podman-nextcloud/configs` and **not** `/mnt/nextcloud/configs` as the environment variables are consumed be `podman compose` in the `podman-nextcloud` directory. The default values are relative and not absolute paths:

```bash
PODMAN_PHPFPM_CONF_FILE_HOST=configs/phpfpm/conf/zzz-www.conf
# PODMAN_PHPFPM_CONF_FILE_HOST=/your/absolute/path/to/configs/phpfpm/conf/zzz-www.conf

PODMAN_PHPFPM_INI_FILE_HOST=configs/phpfpm/ini/nextcloud.ini
# PODMAN_PHPFPM_INI_FILE_HOST=/your/absolute/path/to/configs/phpfpm/ini/nextcloud.ini

PODMAN_PHPFPM_CRON_ROOT_FILE_HOST=configs/phpfpm/cron/cron_root
# PODMAN_PHPFPM_CRON_ROOT_FILE_HOST=/your/absolute/path/to/configs/phpfpm/cron/cron_root
```

That leads us to the following **changes** in the `configs/.env` file for this example:

```bash
# namespace and stage
PODMAN_NAMESPACE=examplecompany
PODMAN_STAGE=prod

# PODMAN_UID=${UID}
# PODMAN_GID=${GID}
PODMAN_UID=2000
PODMAN_GID=2000

# databases
PODMAN_SQL_DATABASE=postgres
PODMAN_KEY_VALUE_DATABASE=valkey

# data paths
PODMAN_SSL_DIR_HOST=/mnt/nextcloud/configs/ssl
PODMAN_NGINX_CONF_DIR_HOST=/mnt/nextcloud/configs/nginx/conf
PODMAN_CLAMAV_DATA_DIR_HOST=/mnt/nextcloud/data/clamav
PODMAN_POSTGRES_DATA_DIR_HOST=/mnt/nextcloud/data/postgres
PODMAN_VALKEY_DATA_DIR_HOST=/mnt/nextcloud/data/valkey
PODMAN_NEXTCLOUD_DATA_DIR_HOST=/mnt/nextcloud/data/nextcloud
PODMAN_NEXTCLOUD_USER_DATA_DIR_HOST=/mnt/nextcloud/data/nextcloud_data

# secrets - do not use these example secrets for your setup!
POSTGRES_PASSWORD=doNotUseThisSecretForPostgres
WHITEBOARD_JWT_SECRET_KEY=doNotUseThisSecretForWhiteboard
VALKEY_PASSWORD=doNotUseThisSecretForValkey
NEXTCLOUD_ADMIN_PASSWORD=doNotUseThisSecretForNextcloudAdminUser

NEXTCLOUD_DOMAIN=nextcloud.example.com
NEXTCLOUD_TRUSTED_DOMAINS="localhost nextcloud.example.com"

NEXTCLOUD_SMTP_HOST=nix
NEXTCLOUD_SMTP_SECURE=nix
NEXTCLOUD_SMTP_PORT=nix
NEXTCLOUD_SMTP_AUTHTYPE=nix
NEXTCLOUD_SMTP_NAME=nix
NEXTCLOUD_MAIL_FROM_ADDRESS=nix
NEXTCLOUD_MAIL_DOMAIN=nix

NEXTCLOUD_DEFAULT_LANGUAGE=de_DE
NEXTCLOUD_DEFAULT_PHONE_REGION=DE
NEXTCLOUD_DEFAULT_TIMEZONE=Europe/Berlin
```

### Configs

Now we need to create the config directories and files. As bare minimum the Nginx config file needs to be changed, check the [Minimal Example Setup](#minimal-example-setup) for further details. Depending on your needs you can also copy/create all config files and edit them to your needs, check the [All Configs](#all-configs) section.

#### Minimal Example Setup

For your example setup we only need to edit the Nginx config file. Therefore we will only create the required directories and copy the default config files into our `configs` directory.

```bash
cd /mnt/nextcloud
```

```bash
mkdir -p configs/nginx/conf
```

Copy the default file into the directory:

```bash
cp podman-nextcloud/configs/nginx/conf/nextcloud_default.conf configs/nginx/conf/nextcloud.conf
```

You need to edit the Nginx `nextcloud.conf` file as it contains the default domain `cloud.example.com` that needs to be changed to your domain like this:

```bash
sed -i 's/cloud.example.com/yourdomain.example.com/g'  configs/nginx/conf/nextcloud.conf
```

All other config files use some default values that can be used out of the box for a small setups.

#### All Configs

If you need to change all service configs you need to create the following directories:

```bash
cd /mnt/nextcloud
```

```bash
mkdir -p configs/nginx/conf
mkdir -p configs/phpfpm/conf
mkdir -p configs/phpfpm/ini

#  SQL database (choose your fighter)
mkdir -p configs/mariadb
mkdir -p configs/mysql
mkdir -p configs/postgres

# key-value database
mkdir -p configs/valkey

# Key-value database
mkdir -p configs/valkey

# Nextcloud scripts for the "manager" container
mkdir -p configs/manager
```

Copy all default files into the directories:

```bash
# nginx
cp podman-nextcloud/configs/nginx/conf/nextcloud_default.conf configs/nginx/conf/nextcloud.conf

# phpfpm
cp podman-nextcloud/configs/phpfpm/conf/zzz-www_default.conf configs/phpfpm/conf/zzz-www.conf
cp podman-nextcloud/configs/phpfpm/ini/nextcloud_default.ini configs/phpfpm/ini/nextcloud.ini

# manager
cp podman-nextcloud/configs/manager/nextcloud_config_default.php configs/manager/nextcloud_config.php
cp podman-nextcloud/configs/manager/nextcloud_setup_default.sh configs/manager/
```

There are no default config files for MariaDB, MySQL, Postgres and Valkey, so you need to create them on your own if needed. Also check the environment variables containing path values in `configs/.env` that need to be uncommented and set accordingly. The path variable names end with `_FILE_HOST` and `_DIR_HOST`.

You need to edit the Nginx `nextcloud.conf` file as it contains the default domain `cloud.example.com` that needs to be changed to your domain like this:

```bash
sed -i 's/cloud.example.com/yourdomain.example.com/g'  configs/nginx/conf/nextcloud.conf
```

All other config files use some default values that can be used out of the box for a small setups.

### SSL Certificates

Depending on your needs and your other setups you may or may not want to use a separate SSL directory. In this case we will use it as it's a simple way to move forward with this example setup:

```bash
cd /mnt/nextcloud
```

```bash
mkdir -p configs/ssl
```

The path `/mnt/nextcloud/configs/ssl` has also been set for the environment variable `PODMAN_SSL_DIR_HOST`.

You need to put your SSL certificate and key into the `configs/ssl` directory. The default Nginx config `nextcloud_default.conf` references these file names:

```bash
ssl_certificate.crt
ssl_certificate_key.key
```

#### Creating Self-Signed SSL Certificates

If you don't have SSL certificates yet, you can create self-signed certificates for testing purposes:

```bash
cd /mnt/nextcloud
```

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-subj "/C=XX/ST=StateName/L=CityName/O=CompanyName/OU=CompanySectionName/CN=CommonNameOrHostname" \
-keyout configs/ssl/ssl_certificate_key.key -out configs/ssl/ssl_certificate.crt
```

### First Start

We chose Postgres as SQL database for this example setup. Therefore we will use the `postgres` profile when starting the containers. You can use one of these profile names for the SQL database:

- `mariadb`
- `mysql`
- `postgres`

```bash
cd /mnt/nextcloud
```

```bash
cd podman-nextcloud
```

```bash
podman compose --env-file "../configs/.env" --profile "postgres" up -d --build
```

Wait for the containers to build. Afterwards check their status:

```bash
podman ps
```

The output will look like this:

```bash
CONTAINER ID  IMAGE                           COMMAND               CREATED         STATUS                   PORTS                  NAMES
29d755bf2a4d  docker.io/library/tempcloud...                        34 minutes ago  Up 34 minutes            6379/tcp               tempcloud2-nextcloud-prod-valkey-1
31e6257367e1  docker.io/clamav/clamav:1.5...                        34 minutes ago  Up 34 minutes            3310/tcp, 7357/tcp     tempcloud2-nextcloud-prod-clamav-1
dd227375136e  ghcr.io/nextcloud-releases/...                        34 minutes ago  Up 34 minutes (healthy)  3002/tcp               tempcloud2-nextcloud-prod-whiteboard-1
2da070fd3166  docker.io/library/postgres:...  postgres              34 minutes ago  Up 34 minutes            5432/tcp               tempcloud2-nextcloud-prod-postgres-1
343ec463b816  docker.io/library/nginx:1.2...  nginx -g daemon o...  34 minutes ago  Up 34 minutes            0.0.0.0:80->80/tcp...  tempcloud2-nextcloud-prod-nginx-1
d3fa28c652c6  docker.io/library/tempcloud...  php-fpm               34 minutes ago  Up 34 minutes            9000/tcp               tempcloud2-nextcloud-prod-phpfpm-1
ecc2cd2b5032  docker.io/library/tempcloud...  sh /etc/entrypoin...  34 minutes ago  Up 34 minutes            9000/tcp               tempcloud2-nextcloud-prod-manager-1
```

The first startup may take some time. You can check the logs of the startup with:

```bash
podman logs -f tempcloud2-nextcloud-prod-manager-1
```

The installation and configuration will be finished when these log lines appear (...yes, the `crond` line feed is partly broken in the container 😀):

```bash
Nextcloud configuration: completed
Nextcloud maintenance: mode off
Maintenance mode already disabled
Manager script: Setup completed successfully
Nextcloud script: Completed
Service: Starting cron
    0 [>---------------------------]    0 [->--------------------------]    0 [--->------------------------]    0 [----->----------------------]    0 [------->--------------------]    0 [--------->------------------]crond: crond (busybox 1.37.0) started, log level 8
crond: USER root pid 280 cmd gosu www-data php -f ${PODMAN_NEXTCLOUD_DATA_DIR_CONTAINER}/cron.php
```

Open your browser and enter your domain name. You should see the Nextcloud login page. You can now log in with the `admin` user and the password you set for the variable `NEXTCLOUD_ADMIN_PASSWORD` in the `configs/.env` file.

> [!NOTE]  
> Sometimes you need to login **twice** at the very first startup.

## Resources

Overview of the used documentations, projects and containers.

### PHP-FPM

<https://github.com/docker-library/php>
<https://hub.docker.com/_/php>

### Nginx

<https://github.com/nginx/docker-nginx>
<https://hub.docker.com/_/nginx>

### Whiteboard

<https://github.com/nextcloud/whiteboard>
<https://help.nextcloud.com/t/how-do-i-setup-the-websocket-server-for-whiteboard-real-time-collaboration/229171/3>

### TURN

<https://github.com/coturn/coturn>
<https://hub.docker.com/r/coturn/coturn>
<https://help.nextcloud.com/t/howto-setup-nextcloud-talk-with-turn-server/30794/112>
<https://www.c-rieger.de/nextcloud-und-coturn/>

Use an external TURN server or use our Coturn project for Podman (coming soon™️).

### HPB

<https://github.com/strukturag/nextcloud-spreed-signaling>
<https://www.c-rieger.de/nextcloud-hpb-talk-signaling-server/>
<https://help.nextcloud.com/t/high-performance-backend-talk-easiest-and-simplest/206836/3>
<https://help.nextcloud.com/t/server-stun-and-high-performance-backend-server-talk/190072/3>
<https://help.nextcloud.com/t/nextcloud-talk-high-performance-backend/167217/16>

### Recording

<https://github.com/nextcloud/nextcloud-talk-recording>

## External Issues affecting this Project

### Nextcloud

<https://github.com/nextcloud/server/issues/26109>
<https://github.com/nextcloud/server/issues/49658>

## Contribution

Contributions are very welcome! If you find any issues or have ideas for improvements, please open an issue and a pull request. Feel free to open a discussion for general questions or suggestions.

Thank you for your support! ❤️
