<?php
/*
 * phpMyAdmin settings added by the Railway template "phpMyAdmin 5.2 with
 * MySQL 8.4 LTS".
 *
 * The official image's /etc/phpmyadmin/config.inc.php configures one server
 * from PMA_HOST / PMA_PORT (cookie login, arbitrary servers only when
 * PMA_ARBITRARY=1) and then includes /etc/phpmyadmin/config.user.inc.php with
 * $i pointing at that server. The image's entrypoint writes this file there
 * from the PMA_USER_CONFIG_BASE64 variable at every start.
 *
 * Edit this file, then run `python3 ../to-template.py --write` to refresh
 * PMA_USER_CONFIG_BASE64 in template.json.
 */

$railwayEnvTrue = ['1', 'true', 'yes', 'on'];

/*
 * Applied to every configured server (PMA_HOST, or each entry of PMA_HOSTS):
 * - root cannot log in through the web UI unless PMA_ALLOW_ROOT=true;
 * - every login needs a password (the image's config.inc.php allows empty ones);
 * - host names and driver errors are not shown on the login page.
 */
$railwayAllowRoot = in_array(
    strtolower(trim((string) getenv('PMA_ALLOW_ROOT'))),
    $railwayEnvTrue,
    true
);
foreach (array_keys($cfg['Servers']) as $railwayServer) {
    $cfg['Servers'][$railwayServer]['AllowRoot'] = $railwayAllowRoot;
    $cfg['Servers'][$railwayServer]['AllowNoPassword'] = false;
    $cfg['Servers'][$railwayServer]['hide_connection_errors'] = true;
}

/* Never offer a free-text server field, whatever PMA_ARBITRARY says. */
$cfg['AllowArbitraryServer'] = false;

/* Failed logins are written to the service log ("user denied: ..."). */
$cfg['AuthLog'] = 'php';
$cfg['AuthLogSuccess'] = false;

/* No error reports to phpmyadmin.net, no Git revision or phpinfo() in the UI. */
$cfg['SendErrorReports'] = 'never';
$cfg['ShowGitRevision'] = false;
$cfg['ShowPhpInfo'] = false;

unset($railwayEnvTrue, $railwayAllowRoot, $railwayServer);
