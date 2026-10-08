#!/usr/bin/env bash
set -euo pipefail
fails=0

# systemctl shim: no systemd as PID 1 in the container, so ubuntu-latest style
# `sudo systemctl start <svc>` is mapped onto the SysV service scripts.
[ "$(command -v systemctl)" = /usr/local/bin/systemctl ] || { echo "systemctl shim not first on PATH" >&2; fails=$((fails+1)); }

# Nothing runs at container start: the preinstalled services must be started explicitly.
for svc in mysql postgresql apache2 nginx; do
  if sudo service "$svc" status >/dev/null 2>&1; then echo "$svc running at container start" >&2; fails=$((fails+1)); fi
done
echo "ok: mysql/postgresql/apache2/nginx not running at start"

wait_for() {
  for _ in $(seq 1 30); do "$@" >/dev/null 2>&1 && return 0; sleep 2; done
  return 1
}

# MySQL: ubuntu-latest's documented root/root credentials.
if sudo systemctl start mysql.service && wait_for mysql -uroot -proot -e 'SELECT 1'; then
  echo "ok: mysql started via systemctl, root/root login"
else
  echo "mysql: start or root/root login failed" >&2; fails=$((fails+1))
fi
[ "$(sudo systemctl is-active mysql.service)" = active ] || { echo "systemctl is-active mysql != active" >&2; fails=$((fails+1)); }
sudo systemctl stop mysql.service || { echo "mysql stop failed" >&2; fails=$((fails+1)); }
if sudo systemctl is-active --quiet mysql; then echo "mysql still active after stop" >&2; fails=$((fails+1)); fi

# PostgreSQL through the same shim.
if sudo systemctl start postgresql && wait_for sudo -u postgres psql -tAc 'SELECT 1'; then
  echo "ok: postgresql started via systemctl"
else
  echo "postgresql: start or query failed" >&2; fails=$((fails+1))
fi
sudo systemctl stop postgresql || { echo "postgresql stop failed" >&2; fails=$((fails+1)); }

[ "$fails" -eq 0 ] || { echo "SMOKE FAILURES (services): $fails" >&2; exit 1; }
echo "OK: services (systemctl shim, mysql, postgresql)"
