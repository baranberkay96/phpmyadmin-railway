#!/bin/bash
# Readable source of the MySQL service's start command. Nothing is built from
# this folder: the service runs the official image (mysql:8.4.13, LTS) and
# template.json carries this script joined into one line:
#
#   /bin/bash -c '<this script>' mysql-start
#
# Regenerate it with `python3 ../to-template.py --write`. One-line rules: no
# single quotes, no backslashes, comments on their own lines, every line
# complete or ending in then/do/else.
#
# At every start it sizes InnoDB for the container and then execs the image's
# docker-entrypoint.sh mysqld. Deploy-form values never fail the start
# (STANDARD 8.29): a non-numeric or out-of-range value falls back to auto.
#   B (budget MB)       = MYSQL_MEMORY_LIMIT_MB, else the cgroup memory limit,
#                         capped at 8192 and at least 256
#   buffer pool         = MYSQL_BUFFER_POOL_MB, else B/2 (128 MB minimum)
#   max_connections     = MYSQL_MAX_CONNECTIONS, else B/8 (100..500)
# plus the settings Railway's own MySQL uses on its volumes (no native AIO, no
# binary log, no performance_schema) and utf8mb4. MYSQL_EXTRA_ARGS is checked
# with mysqld --validate-config first and ignored (with a warning) if mysqld
# rejects it, so a typo cannot crash-loop the database.
set -e
k() { v=$1; if [ $v -lt $2 ]; then v=$2; fi; if [ $v -gt $3 ]; then v=$3; fi; echo $v; }
n() { case "$1" in ""|*[!0-9]*) echo $2 ;; *) echo $1 ;; esac; }
H=$(( $(n "$(grep -m 1 MemTotal /proc/meminfo | tr -s " " | cut -d " " -f 2)" 1048576) / 1024 ))
L=$(cat /sys/fs/cgroup/memory.max 2>/dev/null || cat /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null || echo max)
M=$(( $(n "$L" $((H * 1048576))) / 1048576 ))
if [ $M -gt $H ]; then M=$H; fi
B=$(k $(n "$MYSQL_MEMORY_LIMIT_MB" $(k $M 256 8192)) 256 4194304)
P=$(k $(n "$MYSQL_BUFFER_POOL_MB" $(k $((B / 2)) 128 2097152)) 32 4194304)
C=$(k $(n "$MYSQL_MAX_CONNECTIONS" $(k $((B / 8)) 100 500)) 10 100000)
echo "mysql-start: budget ${B}MB (container ${M}MB, host ${H}MB), innodb_buffer_pool_size ${P}M, max_connections $C"
set -f
X="${MYSQL_EXTRA_ARGS:-}"
if [ -n "$X" ] && ! mysqld --user=mysql --validate-config $X > /tmp/mysql-validate.log 2>&1; then
echo "mysql-start: WARNING MYSQL_EXTRA_ARGS rejected by mysqld --validate-config, starting without it: $(grep -m 1 ERROR /tmp/mysql-validate.log)"
X=""
fi
exec docker-entrypoint.sh mysqld --innodb-use-native-aio=0 --disable-log-bin --performance-schema=0 --innodb-buffer-pool-size=${P}M --max-connections=$C --character-set-server=utf8mb4 --collation-server=utf8mb4_0900_ai_ci --max-allowed-packet=64M $X
