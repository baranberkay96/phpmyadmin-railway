# NOTICE: phpMyAdmin template

## Software deployed

| Component | Licence | Source |
|---|---|---|
| phpMyAdmin 5.2.3 | GPL-2.0-or-later (© The phpMyAdmin contributors) | https://www.phpmyadmin.net, official image `phpmyadmin:5.2.3-apache`, used unmodified |
| MySQL Community Server 8.4 LTS | GPL-2.0 (with Oracle's FOSS exception) | official image `mysql:8.4.13`, used unmodified |

## Written for this template

- `services/phpmyadmin/pma-start.sh`, `services/phpmyadmin/config.user.inc.php`, `services/mysql/mysql-start.sh`, `services/to-template.py`, `template.json`, `README.md`, `TEMPLATE.md`, this file. MIT, © 2026 the template author. The phpMyAdmin start script and config are reused from the same author's "MariaDB 12.3 LTS with phpMyAdmin and Backups" template.
- Nothing is built: both services run the official images; template.json carries the scripts as start commands and the config as a base64 variable that the phpMyAdmin image's own entrypoint writes to `/etc/phpmyadmin/config.user.inc.php`.

## Upstream sources checked (2026-11-24, read only; nothing was executed locally)

- `phpmyadmin/docker`: `apache/Dockerfile`, `docker-entrypoint.sh`, `config.inc.php` (PMA_HOST/PMA_HOSTS/PMA_PORT, PMA_ABSOLUTE_URI, PMA_USER_CONFIG_BASE64, UPLOAD_LIMIT, MEMORY_LIMIT).
- `docker-library/mysql` 8.4 `docker-entrypoint.sh` (MYSQL_ROOT_PASSWORD, MYSQL_DATABASE, MYSQL_USER/MYSQL_PASSWORD on first init).
- Docker Hub index digests of both images; Railway's MySQL base service (`_railway-base/mysql.json`).

## Market templates reviewed

`HHegL4` (phpMyAdmin), `p_f5uS` (PhpMyAdmin + MySQL), `wordpress-mariadb-phpmyadmin-protected`: read for topology and variables only. Nothing was copied.

## Names and affiliation

phpMyAdmin is a project of the phpMyAdmin contributors (Software Freedom Conservancy). MySQL is a trademark of Oracle Corporation. This is a community template, not affiliated with or endorsed by either.
