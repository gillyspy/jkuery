#!/opt/local/bin/bash
VER="2.1"
FILE="kbox_patch_jkueryV"
FACTORY="http://engapps.test.kace.com/kbinfactory"
MINIFIER="http://closure-compiler.appspot.com/compile"
JSDIR="kbox/samba/jkuery/www/2.1/"
EXCLUDEJS="excludejs.lst"
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
#TODO: add closure minification to these js files
declare -a JSFILES=('jquery.jKuery.2.1.js' 'jquery.aboutjKuery.js');
declare -a MINFILES=('jquery.jKuery.2.1.min.js' 'jquery.aboutjKuery.min.js');

echo "" > ${EXCLUDEJS}
for i in "${!JSFILES[@]}"
do
    echo "     minifying ${JSDIR}${JSFILES[$i]}"
    /opt/local/bin/curl -s \
	-d compilation_level=SIMPLE_OPTIMIZATIONS \
	-d output_format=text \
	-d output_info=compiled_code \
	--data-urlencode "js_code@$JSDIR${JSFILES[$i]}" \
        $MINIFIER \
     	> ${JSDIR}${MINFILES[$i]}
    echo "     ${JSDIR}${MINFILES[$i]} created"
#some versions of tar (Mac) don't support --delete from tar balls so use exclude instead
    echo "*${JSDIR}${JSFILES[$i]}*" >> ${EXCLUDEJS}
done

echo "packaging www files"
/usr/bin/tar -czv -X ${EXCLUDEJS} -f jkuery_pkg.tgz kbox/

/bin/mv jkuery_pkg.tgz upgrade/
echo "building temporary bin from files"
/usr/bin/tar -czvf $BIN ./upgrade/
echo "removing packaged (redundant files) for next build"
/bin/rm ./upgrade/jkuery_pkg.tgz
echo "generating kbin"
/opt/local/bin/curl --form uploadfile=@$BIN --form press=OK $FACTORY/index.php > /dev/null 2>&1

echo "downloading kbin"
/opt/local/bin/curl -o $TMP/$KBIN $FACTORY/tmp/$KBIN
echo "$TMP/$KBIN file created"

echo "removing bin and cleaning up"
/bin/rm ./$BIN
/bin/rm ${EXCLUDEJS}
for i in "${!JSFILES[@]}"
do
    /bin/rm ${JSDIR}${MINFILES[$i]}
done

echo "please apply $TMP/$KBIN to your test kbox"
