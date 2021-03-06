#!/bin/sh
# This file generates the includes and then puts them into the headers of the appropriate kbox pages
# /kbox/kboxwww/include
#/KAdminPageHeader.class.php
#/KPageHeader.class.php
#/KPrintablePageHeader.class.php
#/KSysPageHeader.class.php
#/KUserPageHeader.class.php
#/KWelcomePageHeader.class.php
#/KWelcomePageHeaderSys.class.php
# TODO use globals for $jk
jk=/kbox/samba/jkuery
www=/jkuery/www/
ver=2.3

#unpack marker files, default files, examples, etc
#permissions will be updated below so -p is no longer necessary on the tar command
#always overwrite service files
rm /kbox/kboxwww/common/*kuery*.php
#always overwrite base header include
rm /kbox/samba/jkuery/include/jkuery*
#always overwrite base release files
rm $jk/www/$ver/*
#always overwrite base markers
rm $jk/www/markers/*.rename

#move anything that was in the legacy \other\_utilities and \other\_examples folders before extraction into hidden
mv $jk/www/other/_examples $jk/www/hidden/
mv $jk/www/other/_utilities $jk/www/hidden/

# otherwise do not overwrite existing files. e.g. /kbox/samba/jkuery/www/markers/KGlobalHeader
/usr/bin/tar -xkf /kbackup/upgrade/jkuery_pkg.tgz -C /

#create the symlink as the tar file created the real dir
ln -sFhf /kbox/samba/jkuery /kbox/kboxwww/jkuery

cd $jk/www

#any header file that has been modified has string "jkuery enabled" in it so restore that one from backup which will remove the jkuery stuff
#it will get re-added later if appropriate
#if a customer does an upgrade this will fail as the header files will not have the string "jkuery enabled" and thus prevent the older .bak from being restored
#in other words -- only restore the backup header file if the production file contains "jkuery enabled"
cd /kbox/kboxwww/include
for f in K*Header*.class.php
do
        grep -l "jkuery enabled" /kbox/kboxwww/include/$f | xargs cp /kbox/kboxwww/include/$f.bak 

done 

# now same restore for smarty driven versions (e.g. 6.0)
cd /kbox/kboxwww/smarty_templates/ui/base
for f in base.tpl
do
    # jkuery string is sufficient here 
    grep -l "jkuery" $f | xargs cp $f.bak
done

# loop over all header files in include, back them up and inject the code that adds <script> and <link> tags
# all header files are now modified in 2.1+ and dynamically link what you need. You decide what gets linked by creating <script> and <link> tags in the relevant /kbox/samba/jkuery/www/markers/*eader* file
# this will do nothing in 6.0 and the smarty driven versions
cd /kbox/kboxwww/include

for f in K*Header*.php
do 
    if [ $f = "KPrintablePageHeader.class.php" ]
	then 
	continue
    fi
    # backup all header files
    cp /kbox/kboxwww/include/$f /kbox/kboxwww/include/$f.bak
    # inject header file into a temporary file
    sed -f /kbackup/upgrade/header.inc < /kbox/kboxwww/include/$f > /kbox/kboxwww/include/$f.jkuery
    # make temporary file permanent
    mv /kbox/kboxwww/include/$f.jkuery /kbox/kboxwww/include/$f
done

# for smarty driven versions put this in the base template
cd /kbox/kboxwww/smarty_templates/ui/base
for f in base.tpl
do 
    # backup base template
    cp $f $f.bak
    # strip jkuery from backed up file (due to bug with previous installer)
    cat $f.bak | grep -v 'jkuery' > $f.baktmp
    mv $f.baktmp $f.bak
    # inject base file with header logic 
    sed -f /kbackup/upgrade/basetpl.inc < $f > $f.jkuery
    # make file permanent
    mv $f.jkuery $f
done

# map a permanent samba share to file depot
#if it has jkuery in it then it's already configured so...
# restore the backup (.nojkuery) that does NOT have jkuery in it
grep -l "jkuery" /usr/local/etc/smb.conf | xargs cp /usr/local/etc/smb.conf.nojkuery 
grep -l "jkuery" /kbox/bin/kbserver/templates/smb.conf.template | xargs cp /kbox/bin/kbserver/templates/smb.conf.template.nojkuery 

#make a new backup (or first time backup most likely)
cp /usr/local/etc/smb.conf /usr/local/etc/smb.conf.nojkuery
cp /kbox/bin/kbserver/templates/smb.conf.template /kbox/bin/kbserver/templates/smb.conf.template.nojkuery

#apply jkuery changes to samba configuration file and template
sed -f /kbackup/upgrade/jkuerysamba.conf < /usr/local/etc/smb.conf.nojkuery > /usr/local/etc/smb.conf
sed -f /kbackup/upgrade/jkuerysamba.template.conf < /kbox/bin/kbserver/templates/smb.conf.template.nojkuery > /kbox/bin/kbserver/templates/smb.conf.template

# fix the httpd misconfigurations that allow php to be run in the new share
#if it has jkuery in it then it's already configured so...
# restore the backup (.nojkuery) that does NOT have jkuery in it
grep -l "jkuery" /usr/local/etc/apache2/httpd.conf | xargs cp /usr/local/etc/apache2/httpd.conf.nojkuery 
grep -l "jkuery" /usr/local/etc/apache22/httpd.conf | xargs cp /usr/local/etc/apache22/httpd.conf.nojkuery 
grep -l "jkuery" /kbox/bin/kbserver/templates/httpd.conf.template | xargs cp /kbox/bin/kbserver/templates/httpd.conf.template.nojkuery
grep -l "jkuery" /kbox/bin/kbserver/templates/httpd22.conf.template | xargs cp /kbox/bin/kbserver/templates/httpd22.conf.template.nojkuery

#make a new backup (or first time backup most likely)
#apply jkuery changes to apache configuration file and template
cd /kbackup/upgrade
sed -I .nojkuery -f ./httpd.sed.conf /usr/local/etc/apache2/httpd.conf
sed -I .nojkuery -f ./httpd.sed.conf /usr/local/etc/apache22/httpd.conf

#do not use -I again because a "nojkuery" version is already made
sed -f ./httpd.2.sed.conf /usr/local/etc/apache2/httpd.conf > ./httpd.conf.tmp
mv ./httpd.conf.tmp /usr/local/etc/apache2/httpd.conf
sed -f ./httpd.2.sed.conf /usr/local/etc/apache22/httpd.conf > ./httpd.conf.tmp
mv ./httpd.conf.tmp /usr/local/etc/apache22/httpd.conf

sed -f ./http.delete.sed.conf /usr/local/etc/apache2/httpd.conf > ./httpd.conf.tmp
mv ./httpd.conf.tmp /usr/local/etc/apache2/httpd.conf
sed -f ./http.delete.sed.conf /usr/local/etc/apache22/httpd.conf > ./httpd.conf.tmp
mv ./httpd.conf.tmp /usr/local/etc/apache22/httpd.conf

#do same to the templates
sed -I .nojkuery -f ./httpd.sed.conf /kbox/bin/kbserver/templates/httpd.conf.template
sed -I .nojkuery -f ./httpd.sed.conf /kbox/bin/kbserver/templates/httpd22.conf.template

#httpd.2.sed.conf is a dynamically generated file
sed -f ./httpd.2.sed.conf /kbox/bin/kbserver/templates/httpd.conf.template > ./httpd.conf.tmp
mv ./httpd.conf.tmp /kbox/bin/kbserver/templates/httpd.conf.template
sed -f ./httpd.2.sed.conf /kbox/bin/kbserver/templates/httpd22.conf.template > ./httpd.conf.tmp
mv ./httpd.conf.tmp /kbox/bin/kbserver/templates/httpd22.conf.template

sed -f http.delete.sed.conf /kbox/bin/kbserver/templates/httpd.conf.template > ./httpd.conf.tmp
mv ./httpd.conf.tmp /kbox/bin/kbserver/templates/httpd.conf.template
sed -f http.delete.sed.conf /kbox/bin/kbserver/templates/httpd22.conf.template > ./httpd.conf.tmp
mv ./httpd.conf.tmp /kbox/bin/kbserver/templates/httpd22.conf.template

#set permissions on all files from the tarball
#all includes get 444 root:wheel
chown root:wheel $jk/include/jkuery*
chmod 444 $jk/include/jkuery*

chown root:wheel /kbox/kboxwww/common/*kuery*.php
chmod 444 /kbox/kboxwww/common/*kuery*.php

#only relevant for 6.0
chown root:wheel /kbox/kboxwww/common/JSON.php
chmod 444 /kbox/kboxwww/common/JSON.php

#ftp owns most file share files (including customer created files  such that can be written via samba or ftp
#ftp user is forced as the proxy user for the samba connection
find $jk/www -type f -name "*" -exec chown ftp:wheel '{}' \;
find $jk/www -type f -name "*" -exec chmod 644 '{}' \;

#directories are readonly
find $jk/www -type d -name "*" -exec chown root:wheel '{}' \;
find $jk/www -type d -name "*" -exec chmod 755 '{}' \;

#read only readme files
find $jk/www -type f -name "readme*" -exec chown root:wheel {} \;
find $jk/www -type f -name "readme*" -exec chmod 444 {} \;

#saw a problem at a customer and this was the fix
chmod 755 $jk
chmod 755 $jk/www

#read only markers and release files
#customer can modify the header files
#read only release directory
chown ftp:wheel  $jk/www/markers/*
chown root:wheel $jk/www/markers/*.rename
chown root:wheel $jk/www/$ver/*
chown root:wheel $jk/www/$ver

chmod 644 $jk/www/markers/*
chmod 644 $jk/www/markers/*.rename 
chmod 644 $jk/www/$ver/*
chmod 755 $jk/www/$ver

#customer is a RW share for customer createad files
#make customer dir (if not already exists)
mkdir $jk/www/customer

mv $jk/www/adminui $jk/www/customer/
mv $jk/www/systemui $jk/www/customer/
mv $jk/www/userui $jk/www/customer/
mv $jk/www/other $jk/www/customer/

cd $jk/www
find . -maxdepth 1 -type d -name "*" -not "." -not -path "*/2.[0-9]" -not -path "*/markers" -not -path "*/customer" -not -path "*/hidden" -exec mv {} $jk/www/customer/ \; -print

chown -R ftp:wheel $jk/www/customer
chmod -R 755 $jk/www/customer
find $jk/www/customer -name "*" -exec chown ftp:wheel '{}' \;
find $jk/www/customer -type f -name "*" -exec chmod 644 '{}' \;
find $jk/www/customer -type d -name "*" -exec chmod 755 '{}' \;

cd /kbackup/upgrade
