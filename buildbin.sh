#!/opt/local/bin/bash


if [ -z "$1" ]
  then
    BIN="kbox_patch_jkueryV2.0.bin"
    echo "No argument supplied using $BIN"
else 
    BIN="$1"
fi

echo "deleting OS files"
/usr/bin/find . -name ".*DS*" -exec rm {} \; 
echo "packaging www files"
/usr/bin/tar -czvf jkuery_pkg.tgz kbox/
/bin/mv jkuery_pkg.tgz upgrade/
echo "building bin files"
/usr/bin/tar -czvf $BIN ./upgrade/
echo "removing packaged (redundant files) for next build"
/bin/rm ./upgrade/jkuery_pkg.tgz

echo "$BIN file created"
