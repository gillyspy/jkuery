#!/opt/local/bin/bash
VER="2.3"
FILE="kbox_patch_jkueryV"
FACTORY="http://engapps.test.kace.com/kbinfactory"
MINIFIER="http://closure-compiler.appspot.com/compile"
JSDIR="kbox/samba/jkuery/www/${VER}/"
EXCLUDEJS="excludejs.lst"
TMP="/tmp"


# test for connectivity
httptest ()
{
    echo "trying $1"
    site=$(curl --write-out %{http_code} --silent --output /dev/null $1)
    if [ "${site}" == '200' ] 
    then
	echo "status code ${site}"
    elif [ "${site}" == '302' ]
    then
	echo "status code ${site}"
    elif [ "${site}" == '301' ]
    then
	echo "status code ${site}"
    elif [ "${site}" == '405' ]
    then 
	echo "status code ${site}"
    else
	echo "$1 could not be reached"
	exit 1
    fi
    echo "$1 is reachable.  continuing....";
    return
}

buildit ()
{
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

    declare -a JSFILES=("jquery.jKuery.${VER}.js" 'jquery.aboutjKuery.js');
    declare -a MINFILES=("jquery.jKuery.${VER}.min.js" 'jquery.aboutjKuery.min.js');

    echo "" > ${EXCLUDEJS}
    for i in "${!JSFILES[@]}"
    do
	echo "     minifying ${JSDIR}${JSFILES[$i]}"
# using web service for minification
	/opt/local/bin/curl -s \
	    -d compilation_level=SIMPLE_OPTIMIZATIONS \
	    -d output_format=text \
	    -d output_info=compiled_code \
	    --data-urlencode "js_code@$JSDIR${JSFILES[$i]}" \
            $MINIFIER > ${JSDIR}${MINFILES[$i]}
	echo "     ${JSDIR}${MINFILES[$i]} created"
#some versions of tar (Mac) don't support --delete from tar balls so use exclude instead
	echo "*${JSDIR}${JSFILES[$i]}*" >> ${EXCLUDEJS}
    done

    echo "packaging www files"
    echo "excluding..."
    /bin/cat ${EXCLUDEJS}
    echo "including..."
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
    /sbin/md5 $TMP/$KBIN

    echo "removing bin and cleaning up"
    /bin/rm ./$BIN
    /bin/rm ${EXCLUDEJS}
    for i in "${!JSFILES[@]}"
    do
	/bin/rm ${JSDIR}${MINFILES[$i]}
    done

    echo "please apply $TMP/$KBIN to your test kbox"
    exit 0
}

echo "checking for connectivity"
httptest ${FACTORY}
httptest ${MINIFIER}

buildit
