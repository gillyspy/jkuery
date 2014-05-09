#!/usr/local/bin/php
<?php // -*- php -*-
/*
* use this utility to fix the ORIGIN settings in the httpd.conf file
* steps:
* copy this file and install_utils.inc to a temp place like /kbackup/gwip
* change permissions on fixorigins.sh to 755
* run fixorigins.sh
*/
include_once('./install_utils.inc');
createHttpSed();
exec('sed -f ./httpd.2.sed.conf /usr/local/etc/apache22/httpd.conf > ./httpd.conf.tmp');
exec('mv ./httpd.conf.tmp /usr/local/etc/apache22/httpd.conf');

exec('sed -f ./httpd.2.sed.conf /kbox/bin/kbserver/templates/httpd22.conf.template > ./httpd.conf.tmp');
exec('mv ./httpd.conf.tmp /kbox/bin/kbserver/templates/httpd22.conf.template');

exec('/usr/local/etc/rc.d/apache22 restart')
?>
