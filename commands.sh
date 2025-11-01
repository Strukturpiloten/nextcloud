

wget -O data/nextcloud-31.0.7.tar.bz2 https://github.com/nextcloud-releases/server/releases/download/v31.0.9/nextcloud-31.0.7.tar.bz2

tar -xjf data/nextcloud-31.0.7.tar.bz2 -C data/

podman compose up -d --build


podman exec -it exablau_nextcloud_prod_manager /bin/sh

podman compose up -d --build && podman logs -f exablau_nextcloud_prod_manager






gosu www-data php /var/www/nextcloud/occ maintenance:install \
-n \
--database "${NC_dbtype}" \
--database-host "${NC_dbhost}" \
--database-name "${NC_dbname}" \
--database-user "${NC_dbuser}" \
--database-pass "${NC_dbpassword}" \
--data-dir "${NC_datadirectory}" \
--admin-user "${NC_admin_user}" \
--admin-pass "${NC_admin_password}"





rm -r nextcloud/.*
rm -r nextcloud/*
rm -r postgres/.*
rm -r postgres/*
rm -r nextcloud_data/.*
rm -r nextcloud_data/*
cp nextcloud-31.0.7.tar.bz2 nextcloud/
chown 165617:165617 nextcloud/nextcloud-31.0.7.tar.bz2





podman@cl1-standalone1:/mnt/data/podman/exablau_nextcloud> ls -alF
total 12
drwxr-xr-x. 1 podman podman   70 Sep 10 13:19 ./
drwxr-xr-x. 1 podman podman   34 Sep  4 10:58 ../
drwxr-xr-x. 1 podman podman   38 Sep 10 16:16 compose/
-rw-r--r--. 1 podman podman 5724 Sep 17 09:22 compose.yaml
drwxr-xr-x. 1 podman podman  136 Sep 16 12:06 data/
-rw-r--r--. 1 podman podman 3015 Sep 17 09:20 .env
drwxr-xr-x. 1 podman podman   12 Sep  3 13:00 nginx/
drwxr-xr-x. 1 podman podman   92 Sep  3 11:46 ssl/

podman@cl1-standalone1:/mnt/data/podman/exablau_nextcloud> ls -alF data/
total 221836
drwxr-xr-x. 1 podman podman       136 Sep 16 12:06 ./
drwxr-xr-x. 1 podman podman        70 Sep 10 13:19 ../
drwxr-xr-x. 1 165636 165637        84 Sep 17 11:53 clamav/
drwxr-xr-x. 1 165617 165617       526 Sep 17 11:57 nextcloud/
-rw-r--r--. 1 165617 165617 227150452 Sep 15 12:10 nextcloud-31.0.7.tar.bz2
drwxrwx---. 1 165617 165617       252 Sep 17 11:57 nextcloud_data/
drwx------. 1 165605 podman        12 Sep 16 11:51 postgres/
-rw-r--r--. 1 root   root         163 Sep 16 07:56 test.sh



gosu www-data php occ 