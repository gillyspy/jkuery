<?php

include_once('globals.inc');
include_once('DBUtils.inc');
include_once('common.inc');

function clearSmartyCache(){
  //  smarty/ui/templates_c", SMARTY_TMP_DIR)
  if ( defined('SMARTY_TMP_DIR') ) {
    exec('rm ' . SMARTY_TMP_DIR . '/smarty/ui/templates_c/*');
  }
  exec('/usr/bin/find /tmp -name "*php.tpl.php" -delete');

} // clearSmartyCache ;

function _u_dbConnect($dbname)
{
    try {
      if($dbname == 'KBSYS'){
	$db = dbConnectSys();
      } else {
	$db = dbConnect();
      }
      /* $db = ADONewConnection('mysql');
        $db->NConnect('localhost', 'root', 'kbox19', $dbname);
        $ADODB_FETCH_MODE = ADODB_FETCH_ASSOC;
      */
    } catch (Exception $e) {
        return NULL;
    }
    return $db;
}


function logu($str, $console=false)
{
  if(!$debug && $onlyondbg){
    //if only logged on debug then exit when debug is off
    return;
  }
  
  if(trim($str) === "")
    return;

    $timed = date("D M j G:i:s T Y");
    print("[$timed] [notice] $str\n");
    if(strpos($str, '"') === false) {
        exec("echo \"[$timed] [notice] $str\">>".KB_LOG_DIR."update_log");
        if($console) {
            exec("echo \"[$timed] [notice] $str\">>/dev/console");
        }
    } else {
        exec("echo '[$timed] [notice] $str'>>".KB_LOG_DIR."update_log");
        if($console) {
            exec("echo '[$timed] [notice] $str'>>/dev/console");
        }
    }
}
function getCurrentVersion()
{
    // this gets called before we know what version we're running
  $db =  _u_dbConnect('KBSYS');
    if(!$db) {
        $db = _u_dbConnect('KBDB');
    }
    $sql = "select BUILD
              from KBOX_VERSION
             where PACKAGE='KB_LICENSE_CORE'
          order by MAJOR, MINOR, BUILD
             limit 1";
    $rset = $db->Execute($sql);
    $curVersion = $rset->fields['BUILD'];
    return intval($curVersion);
}


function getOrgIds()
{
    $db =  _u_dbConnect('KBSYS');
    $orgs = $db->GetCol("select ID from ORGANIZATION order by ID");
    return $orgs;
}


function getBNames()
{
    $orgs = getOrgIds();
    foreach($orgs as $i)
       $BNames[] = "B$i";
    return $BNames;
}

function getRNames()
{
    $orgs = getOrgIds();
    foreach($orgs as $i)
       $RNames[] = "R$i";
    return $RNames;
}

function createJSD($file="jkuery.sql")
{
  try{
    exec("/bin/cat /kbackup/upgrade/$file | /usr/local/bin/mysql -f -uroot -pkbox19 KBSYS >>".KB_LOG_DIR."update_log");
    $db =  _u_dbConnect('KBSYS');
    $sql = "select QUERY_TYPE from JKUERY.JSON";
    if($debugit === true){
      logu($sql,true);
    }
    $db->Execute($sql);
    logu("able to query from database object",true);
    logu("Database Objects Created",true);
    return true;
  } catch (Exception $e) {
    // object does not exist so something failed
    if($debugit === true){
      logu("not able to query from database object",true);
      logu($sql,true);
    }
    logu("Database Object creation failed",true);
    return false;
  }
}

function createBNames()
{
	$db =  _u_dbConnect('KBSYS');
	$ret=true;
	$BNames = getBNames();
	foreach($BNames as $u) {
		try{
			$db->Execute("GRANT SELECT, INSERT, UPDATE, DELETE ON `JKUERY`.* TO '$u'@'%'");
			$db->Execute("GRANT select on `KBSYS`.`NETWORK_SETTINGS` to '$u'@'%'");
		}catch (Exception $e){
			return false;
		}
	}
		$RNames = getRNames();
	foreach($RNames as $u) {
		try{
			$db->Execute("GRANT SELECT ON `JKUERY`.* TO '$u'@'%'");
		}catch (Exception $e){
			return false;
		}
	}
		return $ret;
}

function dbGrants(){
  $ret = false;
  try{
    $db =  _u_dbConnect('KBSYS');
    $pwd = esc_sql($db->GetOne("select concat('*',PASSWORD) from KBSYS.USER where ID=10"));
    $db->Execute("GRANT select, insert, delete, update on `JKUERY`.* to 'jkuery'@'%' identified by password $pwd");
    logu("'jkuery' user grants completed",true);
    if($debugit){
      logu("'jkuery' user given same password as admin account",true);
    }
    $ret = true;
  } catch (Exception $e){
    logu("There was a problem assigning permissions for 'jkuery' user.",true);
  }
  return createBNames() && $ret;
}


function checkDBfilesExists($table="JKUERY")
{
  
  $filename1 = "/kbox/mysql/var/$table";
  $ret = true;  
  if($debugit===true){
    logu("Filename1 is $filename1",true);
  }

  if (!file_exists($filename1)) {
    logu("Database objects $filename1 do not exist yet",true);
    $ret = false;
  } else {

    logu("Database objects $filename1 do exist",true);
  }
  return $ret;
}

function checkTokensTableExists()
{
  return checkDBFilesExists($table="JKUERY/TOKENS.MYI");
}

function exitCleanup($jKueryDone=false){
  exec("cp /kbackup/upgrade/readme.txt /kbox/samba/jkuery/www/readme.txt");
	if($debugit!= true){

		// Done remove cleanup and remove script
		if (file_exists('/kbackup/kbox_upgrade_pkg.gz')) {
		  	exec("rm -f /kbackup/kbox_upgrade_pkg.gz");
		}
		if (file_exists('/kbackup/upgrade')) {
		  	exec("rm -rf /kbackup/upgrade");
		}
	}

	if($jKueryDone){
		logu("jKuery successfully installed",true);
		restartServices();

	} else {
	  logu("jKuery not successfully installed. Please see errors and contact Dell Kace",true);
	  logu("jKuery not successfully installed. Services not restarted",true);
	}

	exit();
}

function restartServices(){
  logu("restarting file share and webserver",true);
	exec('/usr/local/etc/rc.d/apach2/restart');
	exec('/usr/local/etc/rc.d/samba restart');
	exec('/usr/local/etc/rc.d/apache22 restart');
}

function setJkueryVersion($ver="2.0"){
  // primary key on KBSYS.SETTINGS is NAME so this works;
  $sql = "replace into KBSYS.SETTINGS(NAME,VALUE) values ('JKUERY_VERSION',".esc_sql($ver).")";
  try{
    $db =   _u_dbConnect('KBSYS');
    $db->Execute($sql);
  } catch(Exception $e){
    logu("Problem setting jKuery version",true);
    logu($e->GetMessage(),true);
    return false;
  }
  return true; 
} // end setJkueryVersion

function getJkueryVersion(){
  // get jkuery version.  default is 1.2
  if( checkDBfilesExists("JKUERY") ){
    $sql = "select VALUE from KBSYS.SETTINGS where NAME = 'JKUERY_VERSION' UNION ALL select '1.2' VALUE";
    try{
    $db =   _u_dbConnect('KBSYS');
      $ver = $db->GetOne($sql);
    } catch(Exception $e){
      $ver = false;
    }
  } else {
    $ver = "0";
  }
  logu('jKuery version detected: '.$ver);
  return $ver;
} // end getJkueryVersion

function escapeRgx($str){
   $newstr = '';
   for($i=0; $i < strlen($str); $i++){
       $asc = ord($str[$i]);
       if( ($asc < 48 || $asc > 57) && ($asc < 65 || $asc > 90) && ($asc < 97 || $asc > 122)){
	 $newstr .= '\\';
       }
       $newstr .= $str[$i];
   }
   return $newstr;
} // end escapeRgx

function getOriginsRgx(){
  $chk = (int)versionCompare( getJkueryVersion(), "2.0", true);
  //logu($chk);
  $rgx = false;
  if($chk >= 0){
    $sql = "select concat( '^(',group_concat(ORIGIN separator '|'), ')$' ) RGX from JKUERY.TOKENS UNION ALL select '^$' RGX";
    //logu($sql,true,true);
    
    try{
    $db =   _u_dbConnect('KBSYS');
      $rgx = $db->GetOne($sql) ;
      $rgx = preg_replace('/\//','\\/',preg_quote($rgx));
      //escapeRgx($rgx);
    } catch(Exception $e){
      logu("Error: ".$e->getMessage);
      return false;
    }
  } 
  return $rgx;
}

function checkSambaConflict(){
  /*
   * due to https://jira.kace.com/browse/K1-16295
   */
  exec("cat /usr/local/etc/smb.conf | grep '\[clientdrop\]' | wc -l",$clientdrop);

  if($clientdrop[0] == "0"){
    logu("Client shares are not enabled properly.  Please enable writeable client shares and reapply this patch");
  }
  
  exec("/usr/bin/sed -E -n 's/.*workgroup[ ]*=[ ]*(.*)$/\\1/Ip' /usr/local/etc/smb.conf", $workgroup,$code2);
  exec("/usr/bin/sed -E -n 's/.*netbios name[ ]*=[ ]*(.*)$/\\1/Ip' /usr/local/etc/smb.conf", $netbios,$code1);

  if( $workgroup[0] == $netbios[0]){
    logu("Samba warning: Until you change your hostname (NETBIOS name) the samba shares will not function correctly",true);
    logu("NETBIOS / Host name is " . $netbios[0]);
    logu("Workgroup name is " . $workgroup[0]);
  }
  return ;

}  // checkSambaConflict

function createHttpSed(){
  /* 
   * by default the httpd.2.sed.conf is a blank file that does nothing. 
   * if JKUERY version checks out then this will create a new replacement file for http.conf and its template
   */
  //get regex from TOKENS
   $rgx = getOriginsRgx();
   if(!(bool)$rgx){
     logu("Allowing no origins");
     return NULL;
   } else {
     logu("Adding Origin $rgx to apache config for jkuery service from database");
   }
   $conf = <<<EOT
/RewriteOptions inherit/{
N
N
N
N
N
N
N
N
N
N
N
N
N
N
N
N
N
N
N
N
N
N
N
N
N
N
N
s/\\(RewriteOptions inherit.*L,R.\\).*\\(<Directory \\/>.*\\)\\(RewriteEngine on\\)\\(.*\\)/\\1\x5c
\x5c
SetEnvIf Origin "$rgx" ORIGIN_SUB_DOMAIN\\=\\$1\x5c
\x5c
<Directory \\~ "\\/kbox\\/kboxwww\\/common\\/jkuery.php">\x5c
    Header set Access-Control-Allow-Origin "%\\{ORIGIN_SUB_DOMAIN\\}e" env\\=ORIGIN_SUB_DOMAIN\x5c
<\\/Directory>\x5c
\x5c
\\2\x5c
    \\3\x5c
\x5c
    \\#Support REST style URLs for jkuery.php\x5c
    RewriteRule \\^kbox\\/kboxwww\\/jkuery\\/\\(\\(\\?\\!\\(\\?\\:www\\|include\\)\\/\\)\\[\\^\\/\\]\\+\\)\\(\\?\\:\\/\\(\\[\\^\\?\\]\\*\\)\\)\\?\\$ kbox\\/kboxwww\\/common\\/jkuery\\.php\\?id\\=\\$1\\&p\\=\\$2\\&query_type\\=lookup \\[QSA,L\\]\x5c
    RewriteRule \\^kbox\\/kboxwww\\/rule\\/\\(\\(\\?\\!\\(\\?\\:www\\|include\\)\\/\\)\\[\\^\\/\\]\\+\\)\\(\\?\\:\\/\\(\\[\\^\\?\\]\\*\\)\\)\\?\\$ kbox\\/kboxwww\\/common\\/jkuery\\.php\\?id\\=\\$1\\&p\\=\\$2\\&query_type\\=rule \\[QSA,L\\]\x5c
    RewriteRule \\^kbox\\/kboxwww\\/report\\/\\(\\(\\?\\!\\(\\?\\:www\\|include\\)\\/\\)\\[\\^\\/\\]\\+\\)\\(\\?\\:\\/\\(\\[\\^\\?\\]\\*\\)\\)\\?\\$ kbox\\/kboxwww\\/common\\/jkuery\\.php\\?id\\=\\$1\\&p\\=\\$2\\&query_type\\=report \\[QSA,L\\]\x5c
    \\#give 404 on any documents starting in markers or hidden share subfolders.\x5c
    RewriteRule \\^kbox\\/kboxwww\\/jkuery\\/www\\/\\(markers\\|hidden\\)\\/\\.\\*\\$ \\[R\\=404,L\\]\x5c
\x5c
    \\#non-jkuery rewrite rules\x5c
\\4\x5c
/g
}
EOT;

   exec("echo '".$conf."' > ./httpd.2.sed.conf");
} // end createHttpSed ; 
?>