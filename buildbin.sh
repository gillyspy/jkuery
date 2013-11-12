#!/opt/local/bin/bash
VER="2.1"
FILE="kbox_patch_jkueryV"
FACTORY="http://engapps.test.kace.com/kbinfactory"
TMP="/tmp"
if [ -z "$1" ]
  then
    BIN="$FILE$VER.bin"
    KBIN="$FILE$VER.kbin"
    echo "No argument supplied using $BIN"
else 
    KBIN="$1.kbin"
    BIN="$1.bin"
fi

echo "deleting OS files"
/usr/bin/find . -name ".*DS*" -exec rm {} \; 
echo "packaging www files"
/usr/bin/tar -czvf jkuery_pkg.tgz kbox/
/bin/mv jkuery_pkg.tgz upgrade/
echo "building temporary bin from files"
/usr/bin/tar -czvf $BIN ./upgrade/
echo "removing packaged (redundant files) for next build"
/bin/rm ./upgrade/jkuery_pkg.tgz
echo "generating kbin"
/opt/local/bin/curl --form uploadfile=@$BIN --form press=OK $FACTORY/index.php > /dev/null 2>&1
echo "removing bin"
/bin/rm ./$BIN
echo "downloading kbin"
/opt/local/bin/curl -o $TMP/$KBIN $FACTORY/tmp/$KBIN

echo "$TMP/KBIN file created"
echo "please apply to your test kbox"
