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

#unpack marker files, default files, examples, etc
#permissions will be updated below so -p is no longer necessary
rm /kbox/kboxwww/common/*kuery*.php
/usr/bin/tar -xkpf /kbackup/upgrade/jkuery_pkg.tgz -C /

#create the symlink as the tar file created the real dir
ln -sFhf /kbox/samba/jkuery /kbox/kboxwww/jkuery

cd $jk/www
rm $jk/include/jkuery*
#build the includes based on all js scripts in the jkuery directory
for f in *.js
do
    echo building links...
        echo '<script type="text/javascript" src="'$www$f'"></script>' >> $jk/include/jkuery.js.inc
done
for f in *.css
do
        echo building links...
	echo '<link rel="stylesheet" href="'$www$f'" />' >> $jk/include/jkuery.css.inc
done

#build the includes for jkuery/adminui
cd $jk/www/adminui
for f in *.js
do
        echo building links...
        echo '<script type="text/javascript" src="'$www'adminui/'$f'"></script>' >> $jk/include/jkuery.adminui.js.inc
done
for f in *.css
do
        echo building links...
        echo '<link rel="stylesheet" href="'$www'adminui/'$f'" />' >> $jk/include/jkuery.adminui.css.inc
done

#build includes for jkuery/systemui
cd $jk/www/systemui
for f in *.js
do
        echo building links...
        echo '<script type="text/javascript" src="'$www'systemui/'$f'"></script>' >> $jk/include/jkuery.systemui.js.inc
done
for f in *.css
do
        echo building links...
        echo '<link rel="stylesheet" href="'$www'systemui/'$f'" />' >> $jk/include/jkuery.systemui.css.inc
done
   
#build includes for jkuery/userui
cd $jk/www/userui
for f in *.js
do
        echo building links...
        echo '<script type="text/javascript" src="'$www'userui/'$f'"></script>' >> $jk/include/jkuery.userui.js.inc
done
for f in *.css
do
        echo building links...
      echo '<link rel="stylesheet" href="'$www'userui/'$f'" />' >> $jk/include/jkuery.userui.css.inc
done

#any file that has been modified has "jkuery enabled" in it so restore that one from backup which will remove the jkuery stuff
#it will get re-added later if appropriate
#when a customer does an upgrade this will fail and prevent the older .bak from being restored
cd /kbox/kboxwww/include
for f in K*Header*.class.php
do
        grep -l "jkuery enabled" /kbox/kboxwww/include/$f | xargs cp /kbox/kboxwww/include/$f.bak 

done 


#loop over all header files in include and inject the scripts.  
# note that KPageHeader.class.php does not match the sed pattern even though it does go through the loop. that is ok
# to exclude a file from having it's headers modified simply add ".rename" to the end of it's name in /kbox/kboxwww/jkuery/markers  
#  e.g. /kbox/kbox/jkuery/markers/KPrintablePageHeader.rename would be excluded
cd /kbox/kboxwww/include

for f in K*Header*.php
do 
    cp /kbox/kboxwww/include/$f /kbox/kboxwww/include/$f.bak
done

cd $jk/www/markers
for f in KAdminPageHeader KWelcomePageHeader
do
    sed -f /kbackup/upgrade/adminheader.inc < /kbox/kboxwww/include/$f.class.php > /kbox/kboxwww/include/$f.class.php.jkuery
    mv /kbox/kboxwww/include/$f.class.php.jkuery /kbox/kboxwww/include/$f.class.php
done

for f in KSysPageHeader KWelcomePageHeaderSys
do
    sed -f /kbackup/upgrade/sysheader.inc < /kbox/kboxwww/include/$f.class.php > /kbox/kboxwww/include/$f.class.php.jkuery
    mv /kbox/kboxwww/include/$f.class.php.jkuery /kbox/kboxwww/include/$f.class.php
done

for f in KUserPageHeader
do
    sed -f /kbackup/upgrade/userheader.inc < /kbox/kboxwww/include/$f.class.php > /kbox/kboxwww/include/$f.class.php.jkuery
    mv /kbox/kboxwww/include/$f.class.php.jkuery /kbox/kboxwww/include/$f.class.php
done

for f in K*Header
do
    sed -f /kbackup/upgrade/header.inc < /kbox/kboxwww/include/$f.class.php > /kbox/kboxwww/include/$f.class.php.jkuery
    mv /kbox/kboxwww/include/$f.class.php.jkuery /kbox/kboxwww/include/$f.class.php
done

# map a  samba share to file depot
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
sed -f ./httpd.2.sed.conf /usr/local/etc/apache2/httpd.conf > ./httpd.conf.tmp
mv ./httpd.conf.tmp /usr/local/etc/apache2/httpd.conf
sed -f ./httpd.2.sed.conf /usr/local/etc/apache22/httpd.conf > ./httpd.conf.tmp
mv ./httpd.conf.tmp /usr/local/etc/apache22/httpd.conf

sed -I .nojkuery -f ./httpd.sed.conf /kbox/bin/kbserver/templates/httpd.conf.template
sed -I .nojkuery -f ./httpd.sed.conf /kbox/bin/kbserver/templates/httpd22.conf.template

#httpd.2.sed.conf is a dynamically generated file
sed -f ./httpd.2.sed.conf /kbox/bin/kbserver/templates/httpd.conf.template > ./httpd.conf.tmp
mv ./httpd.conf.tmp /kbox/bin/kbserver/templates/httpd.conf.template
sed -f ./httpd.2.sed.conf /kbox/bin/kbserver/templates/httpd22.conf.template > ./httpd.conf.tmp
mv ./httpd.conf.tmp /kbox/bin/kbserver/templates/httpd22.conf.template

#TODO test permissions being correct in the tar file and set by the tar file extract instead
#set permissions on all files from the tarball
#all includes get 444 root:wheel
#all www they are 644 root:wheel
chown root:wheel $jk/include/jkuery*
chmod 444 $jk/include/jkuery*
chown root:wheel /kbox/kboxwww/common/*kuery*
chmod 444 /kbox/kboxwww/common/*kuery*
find $jk/www -type f -name "*" -exec chown root:wheel '{}' \;
find $jk/www -type f -name "*" -exec chmod 644 '{}' \;
#this makes it so you cannot edit these placeholders
find $jk/www -type f -name "default.css" -exec chmod 444 '{}' \;
find $jk/www -type f -name "default.js" -exec chmod 444 '{}' \;

#v3 TODO move restart of apache to kbox_upgrade script
#/usr/local/etc/rc.d/samba restart
#/usr/local/etc/rc.d/apache2 restart
#/usr/local/etc/rc.d/apache22 restart
cd /kbackup/upgrade
