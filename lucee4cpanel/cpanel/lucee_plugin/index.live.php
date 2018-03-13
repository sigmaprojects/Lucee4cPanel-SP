<?php
require_once '/usr/local/cpanel/php/cpanel.php';
$cpanel = new CPANEL();

$mydomains = $cpanel->uapi(
    'DomainInfo', 'list_domains'
);


header('Location: http://' . $mydomains['cpanelresult']['result']['data']['main_domain'] . ':8888/lucee/admin/web.cfm');

?>
