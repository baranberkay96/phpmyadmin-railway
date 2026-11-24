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

Measured on the test deploy (2026-11-24): phpMyAdmin 42-59 MiB idle. MySQL: 680-780 MiB with an 8 GB container limit (buffer pool auto-sized to 3.8 GB, partly touched at start); **370 MiB with a simulated Trial limit of 1 GB** (pool 476 MB, `serviceInstanceLimitsUpdate`). CPU < 0.02 vCPU idle.

| Service | Idle RAM | Typical RAM | CPU |
|---|---|---|---|
| phpMyAdmin | 45 MB | 60-300 MB (imports/exports, up to `PMA_APACHE_WORKERS` × `MEMORY_LIMIT`) | < 0.01 idle |
| MySQL | 370 MB (1 GB plan) to 750 MB (8 GB plan) | up to the buffer pool + ~300 MB | 0.01-0.5 |

Estimated cost: idle ≈ $4-8/month (0.4-0.8 GB RAM + ~1 GB volume); typical ≈ $8-15/month. Minimum plan: **Trial** runs it (MySQL sizes itself to the 1 GB limit, measured 370 MiB); Hobby recommended for real data. Lower `MYSQL_MEMORY_LIMIT_MB` to shrink MySQL on large plans.

## Verification checklist

- [x] Both services SUCCESS; `/` 200 (login page).
- [x] Cookie login as `railway` with `MYSQL_PASSWORD` works; wrong password refused; `root` refused while `PMA_ALLOW_ROOT=false`, accepted after setting it to `true`.
- [x] Through phpMyAdmin: `CREATE TABLE`, `INSERT`, `SELECT` in database `railway` (MySQL 8.4.13, caching_sha2_password works with PHP mysqlnd).
- [x] MySQL redeploy: data kept.
- [x] `MYSQL_EXTRA_ARGS=--bogus-option` and `MYSQL_BUFFER_POOL_MB=abc` (STANDARD 8.29): MySQL SUCCESS; `mysqld --validate-config` rejected the option, a warning was logged and MySQL started without it; pool fell back to auto. `--sql-mode=TRADITIONAL` was accepted.
- [x] 1 GB memory limit (Trial simulation): pool 476 MB, max_connections 119, 370 MiB steady.
- [ ] Post-publish deploy by the real template id (`ship.py publish`).

## Open questions

- phpMyAdmin's configuration storage (bookmarks, history tables) is not set up; it is optional and phpMyAdmin offers to create it in a database the user picks.
