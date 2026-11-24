# phpMyAdmin 5.2 with MySQL 8.4 LTS: Railway template spec

## Listing

| Field | Value |
|---|---|
| Name | **phpMyAdmin 5.2 with MySQL 8.4 LTS** |
| Description | MySQL web admin with its own login, plus a ready MySQL 8.4 LTS database. (72 chars) |
| Category | Storage |
| Tags | phpmyadmin, mysql, database, admin, gui, sql, lts |
| Icon | `https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/phpmyadmin.svg` |
| Repo | `baranberkay96/phpmyadmin-railway` (sources of the start commands; both services run official images) |

Relation to our `89-mariadb` listing ("MariaDB 12.3 LTS with phpMyAdmin and Backups"): that one is database-first (MariaDB, backups to a Bucket). This one is phpMyAdmin-first with MySQL 8.4 LTS, and documents managing any other Railway MySQL/MariaDB.

## Base market templates (checked 2026-11-24)

| Code | Name | Total deploys | Stack | Problems |
|---|---|---|---|---|
| `HHegL4` | phpMyAdmin | 449 | `linuxserver/phpmyadmin` (unpinned), `PMA_ARBITRARY=1` | No database; **free-text server field on a public page** (can probe any host); resolver hack; no healthcheck |
| `p_f5uS` | PhpMyAdmin + MySQL | 239 | `mysql:9`, `phpmyadmin/phpmyadmin:latest` | **Root password in `PMA_PASSWORD`/`PMA_USER`** → config auth, the UI opens without any login; arbitrary servers; MySQL TCP proxy public; 1 GB-pool-style defaults |
| `wordpress-mariadb-phpmyadmin-protected` | WordPress + MariaDB + phpMyAdmin | 40 | third-party repos, Caddy basic auth | 8-char basic-auth secrets; unpinned |

Kept: official `phpmyadmin` image with `PMA_HOST`/`PMA_PORT` on the private network; MySQL service variables in Railway's naming (`MYSQLHOST`, `MYSQL_URL`, ...).

## Improvements over market templates

1. **A login is always required** (cookie auth): no stored credentials in phpMyAdmin, no empty passwords, root login off unless `PMA_ALLOW_ROOT=true`, applied to every configured server.
2. **No free-text server field** (`AllowArbitraryServer=false` whatever `PMA_ARBITRARY` says), connection errors hidden, failed logins logged.
3. **MySQL 8.4 LTS** (supported to 2032) instead of an innovation release; digest-pinned; private only.
4. **Memory-aware InnoDB sizing** from the cgroup limit (half for the buffer pool, connections from the budget), every value overridable, bad values fall back to auto (STANDARD 8.29).
5. App user `railway` with its own password for daily use; root kept for server-wide work.
6. Apache sized for a container (10 prefork workers), one MPM guaranteed, versions hidden, PHP errors to the log.

## Pinned versions

| Service | Source | Version | Checked |
|---|---|---|---|
| phpMyAdmin | `phpmyadmin:5.2.3-apache@sha256:1195ef91…a006` | 5.2.3 (image rebuilt 2026-11-24) | 2026-11-24 |
| MySQL | `mysql:8.4.13@sha256:8c233bad…be00` | 8.4.13 LTS | 2026-11-24 |

## Services

### phpMyAdmin

- Official image, start command from `services/phpmyadmin/pma-start.sh` (joined by `services/to-template.py`), config from `services/phpmyadmin/config.user.inc.php` (`PMA_USER_CONFIG_BASE64`).
- Public domain, `targetPort` 80, `PORT=80`, healthcheck `/` (login page, 300 s), restart `ON_FAILURE` ×10. Stateless (no volume).

### MySQL

- Official image, start command from `services/mysql/mysql-start.sh`: InnoDB sizing, then `docker-entrypoint.sh mysqld --innodb-use-native-aio=0 --disable-log-bin --performance-schema=0 ...` (Railway's MySQL flags).
- Volume `/var/lib/mysql`, private only, no healthcheck (no HTTP; phpMyAdmin is the template's health target), restart `ON_FAILURE` ×10, 60 s draining.

## Resource estimate

RESOURCE_PLACEHOLDER

## Verification checklist

CHECKLIST_PLACEHOLDER

## Open questions

- phpMyAdmin's configuration storage (bookmarks, history tables) is not set up; it is optional and phpMyAdmin offers to create it in a database the user picks.
