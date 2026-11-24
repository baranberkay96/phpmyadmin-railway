# Deploy and Host phpMyAdmin with Railway

phpMyAdmin is the classic web interface for MySQL and MariaDB. This template deploys phpMyAdmin 5.2 with cookie login, connected over Railway's private network to a bundled MySQL 8.4 LTS database, so you can create tables, run SQL and import dumps from your browser minutes after deploying. It can manage any existing Railway MySQL or MariaDB too.

## About Hosting phpMyAdmin

phpMyAdmin is a PHP application served by Apache. It stores no data of its own: every login is a MySQL account, checked by the database server (cookie authentication). Hosting it means running the web service with sensible PHP limits for imports, pointing it at a database host, and making sure it never becomes an open door to your network. This template pins phpMyAdmin and MySQL to exact image digests, keeps MySQL private (no public port), disables the free-text server field and password-less logins, blocks root logins by default, logs failed logins, and sizes MySQL's InnoDB buffer pool from the container's memory limit instead of a fixed 1 GB.

## Common Use Cases

- Browse, search and edit rows of a Railway MySQL or MariaDB database
- Import `.sql` dumps (up to 64 MB by default) and export tables or whole databases
- Create tables, indexes, views and users with a visual editor
- Run ad-hoc SQL and inspect query plans
- Give a teammate a database login without installing a desktop client

## Dependencies for phpMyAdmin Hosting

- phpMyAdmin web application (`phpmyadmin` official image, Apache variant)
- A MySQL or MariaDB server to manage (bundled: MySQL 8.4 LTS)

### Deployment Dependencies

- phpMyAdmin documentation: https://docs.phpmyadmin.net/en/latest/
- phpMyAdmin Docker image: https://hub.docker.com/_/phpmyadmin
- MySQL 8.4 reference manual: https://dev.mysql.com/doc/refman/8.4/en/
- Railway private networking: https://docs.railway.com/guides/private-networking

### Implementation Details

| Service | Image | Purpose | Public |
|---|---|---|---|
| phpMyAdmin | `phpmyadmin:5.2.3-apache` (digest-pinned) | Web UI on port 80, cookie login | HTTPS domain |
| MySQL | `mysql:8.4.13` (digest-pinned, LTS) | Database, volume `/var/lib/mysql` | No (private network only) |

**First login**

1. Open the MySQL service → Variables and copy `MYSQL_USER` (default `railway`) and `MYSQL_PASSWORD`.
2. Open the phpMyAdmin public domain and log in with them. The `railway` database is ready.
3. For server-wide work (creating databases or users), set `PMA_ALLOW_ROOT=true` on phpMyAdmin, redeploy, and log in as `root` with `MYSQL_ROOT_PASSWORD`. Set it back to `false` when done.

Passwords are set when MySQL first initialises its volume; changing the variables later does not change them (use phpMyAdmin's *User accounts* tab instead).

**Manage another Railway database** (MySQL or MariaDB, same project): on the phpMyAdmin service set `PMA_HOST` to that service's private domain (for example `${{MySQL.RAILWAY_PRIVATE_DOMAIN}}` or `{service}.railway.internal`) and `PMA_PORT` to `3306`, then redeploy. Railway's own MySQL template logs in as `root`, so also set `PMA_ALLOW_ROOT=true`. Several servers: empty `PMA_HOST` and set `PMA_HOSTS` (and `PMA_PORTS`) to comma-separated lists; phpMyAdmin then shows a server drop-down on the login page, and the template's login rules apply to every entry. A database in another project or provider needs its TCP proxy host and port. You can delete the bundled MySQL service if you only manage other databases.

**Connect your apps to the bundled MySQL**: reference `${{MySQL.MYSQL_URL}}` (app user) in your app's variables. MySQL has no public port; enable a TCP proxy on the MySQL service if you need to reach it from outside Railway.

**MySQL tuning**: `MYSQL_MEMORY_LIMIT_MB`, `MYSQL_BUFFER_POOL_MB` and `MYSQL_MAX_CONNECTIONS` default to `auto` (half the container memory for the buffer pool, capped at an 8 GB budget). Extra server options go in `MYSQL_EXTRA_ARGS`. Invalid values fall back to `auto`; they never stop MySQL from starting.

**Scaling and upgrades**: phpMyAdmin is stateless; raise `PMA_APACHE_WORKERS` for many users, or add replicas. To upgrade, change the image tag and digest in the service settings. MySQL stays on the 8.4 LTS series; moving to 9.x is a one-way upgrade, so take a dump first (phpMyAdmin *Export*, or `mysqldump`).

**Security notes**: only phpMyAdmin is public, and every action needs a MySQL login. There is no free-text server field, so the login page cannot be used to probe other hosts. This is a community template and is not affiliated with the phpMyAdmin project or Oracle.

### Why Deploy phpMyAdmin on Railway?

Railway runs phpMyAdmin and MySQL side by side on a private network with persistent volumes, HTTPS and logs handled for you. One click gives you a working database plus a browser admin for it, and the same phpMyAdmin can manage the other MySQL and MariaDB services in your project.
