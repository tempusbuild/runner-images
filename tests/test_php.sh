#!/usr/bin/env bash
set -euo pipefail
fails=0
fail() { echo "$1" >&2; fails=$((fails+1)); }

php_series=8.3
php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' | grep -qx "$php_series" \
  || fail "php != ${php_series}: $(php --version | head -1)"

# Module names as `php -m` reports them for the ubuntu-latest package set (install-php.sh).
modules=$(php -m | tr '[:upper:]' '[:lower:]')
for mod in amqp apcu bcmath bz2 curl dba dom enchant gd gmp igbinary imagick imap intl ldap \
  mbstring memcache memcached mongodb mysqli mysqlnd odbc pdo_dblib pdo_firebird pdo_mysql pdo_odbc \
  pdo_pgsql pdo_sqlite pgsql pspell readline redis simplexml snmp soap sqlite3 tidy xdebug xml xmlreader \
  xmlwriter xsl yaml zip zmq "zend opcache"; do
  grep -qx "$mod" <<<"$modules" || fail "MISSING php extension: $mod"
done

# PCOV installed but disabled; Xdebug enabled (parity with ubuntu-latest).
[ -f "/etc/php/${php_series}/mods-available/pcov.ini" ] || fail "MISSING: pcov not installed"
! grep -qx pcov <<<"$modules" || fail "pcov should be installed but disabled"

for bin in php-cgi "php-fpm${php_series}" phpdbg pecl pear snmpget composer phpunit; do
  command -v "$bin" >/dev/null || fail "MISSING: $bin"
done
composer --version 2>/dev/null | grep -q '^Composer version 2\.' || fail "composer --version failed"
composer_bin=$(composer global config bin-dir --absolute 2>/dev/null) || composer_bin=""
[ "$composer_bin" = "$HOME/.config/composer/vendor/bin" ] || fail "composer global bin-dir is ${composer_bin:-unset}"
[[ ":$PATH:" == *":${composer_bin}:"* ]] || fail "composer global bin-dir not on PATH"

# setup-php reuses the preinstalled PHP (no PPA + apt reinstall) only if php-config reports the requested
# series and, on self-hosted runners, its helper packages are already present.
php-config --version | grep -q "^${php_series}\." || fail "php-config missing or != ${php_series}"
for pkg in apt-transport-https ca-certificates curl file make jq unzip autoconf automake gcc g++ gnupg; do
  dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q 'install ok installed' \
    || fail "MISSING setup-php self-hosted prerequisite package: $pkg"
done

[ "$fails" -eq 0 ] || { echo "SMOKE FAILURES (php): $fails" >&2; exit 1; }
echo "OK: php ${php_series} + extensions, composer, setup-php fast path"
