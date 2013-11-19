#!/usr/local/bin/php
<?php // -*- php -*-
// The above line activates php mode in emacs

// Updated 2012-02-23

// Installs the jKuery plugin for enabling custom javascript, css, images, etc

// customer could also re-apply this patch every time they add a new .js file to the mix. 
// customer could also adjust by calling scripts from other scripts. 
// they cannot access the .inc files cuz then they could put php in them. 

// files specifically for adminui are in jkuery/adminui
// similarly there is jkuery/userui and jkuery/systemui
// files for all are in /jkuery
// no matter where files are located the markers for its respective headers still needs to be set

// I suspect that css and images are more likely to be global
// 
// TODO you can tell jKuery is working because when you click on "about K1000" it will give a custom jax driven popup instead of about.php and that popup will have jquery listed

// webdata is backed up becuase it's a symbolic web link to a samba share

// Gerald Gillespie - Dell KACE
// created Feb 23rd, 2012

// Steps:
// 1) Check version requirements
//
// 2) Create the jKuery file directory
//  unpackage all the defaults (markers, includes, demos, readme,etc
// extract template files into jKuery directory
// update existing kbox headers.  Headers are restored from backup and updated each time the patch is run. 
// create the samba settings
// restart the samba server
//
// 3) create the optional JKUERY.JSON database object

include_once('globals.inc');
include_once('DBUtils.inc');
include_once('common.inc');

// Use true to get additional script debug information, and prevent file deletion use false to turn it off.
$debugit = true; 
$version = "2.1b";

function _u_dbConnect($dbname)
{
    try {
        $db = ADONewConnection('mysql');
        $db->NConnect('localhost', 'root', 'kbox19', $dbname);
        $ADODB_FETCH_MODE = ADODB_FETCH_ASSOC;
    } catch (Exception $e) {
        return NULL;
    }
    return $db;
}


function logu($str, $console=false)
{
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
    $db = _u_dbConnect('KBSYS');
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
    $db = _u_dbConnect('KBSYS');
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
    $db = _u_dbConnect('KBSYS');
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
	$db = _u_dbConnect('KBSYS');
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
    $db = _u_dbConnect('KBSYS');
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
  $ret	= true;  
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
  $sql = "replace into KBSYS.SETTINGS(NAME,VALUE) values ('JKUERY_VERSION',$ver)";
  try{
    $db = _u_dbConnect('KBSYS');
    $db->Execute($sql);
  } catch(Exception $e){
    return false;
  }
  return true; 
} // end setJkueryVersion

function getJkueryVersion(){
  // get jkuery version.  default is 1.2
  if( checkDBfilesExists("JKUERY") ){
    $sql = "select VALUE from KBSYS.SETTINGS where NAME = 'JKUERY_VERSION' UNION ALL select '1.2' VALUE";
    try{
      $db = _u_dbConnect('KBSYS');
      $ver = $db->GetOne($sql);
    } catch(Exception $e){
      $ver = false;
    }
  } else {
    $ver = "0";
  }
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
  $rgx = false;
  if($chk >= 0){
    $sql = "select concat( '^(',group_concat(ORIGIN separator '|'), ')$' ) RGX from JKUERY.TOKENS UNION ALL select '^$' RGX";
    try{
      $db = _u_dbConnect('KBSYS');
      $rgx = escapeRgx($db->GetOne($sql) );
    } catch(Exception $e){
      return false;
    }
  } 
  return $rgx;
}

function createHttpSed(){
  /* 
   * by default the httpd.2.sed.conf is a blank file that does nothing. 
   * if JKUERY version checks out then this will create a new replacement file for http.conf and its template
   */
  //get regex from TOKENS
   $rgx = getOriginsRgx();
   if($rgx){
     $conf = <<<EOT
/<Directory \\/>/{
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
s/\\(<Directory \\/>.*\\)\\(RewriteEngine on\\)/SetEnvIf Origin "$rgx" ORIGIN_SUB_DOMAIN\\=\\$1\x5c
\x5c
<Directory \\~ "\\/kbox\\/kboxwww\\/common\\/jkuery.php">\x5c
    Header set Access-Control-Allow-Origin "%\\{ORIGIN_SUB_DOMAIN\\}e" env\\=ORIGIN_SUB_DOMAIN\x5c
<\\/Directory>\x5c
\x5c
\\1\x5c
    \\2\x5c
\x5c
    \\#Support REST style URLs for jkuery.php\x5c
    RewriteRule \\^kbox\\/kboxwww\\/jkuery\\/\\(\\[0-9\\]\\*\\)\\(\\?\\:\\/\\(\\[\\^\\?\\]\\*\\)\\)\\?\\$ kbox\\/kboxwww\\/common\\/jkuery\\.php\\?id\\=\\$1\\&p\\=\\$2\\&query_type\\=lookup \\[QSA,L\\]\x5c
    RewriteRule \\^kbox\\/kboxwww\\/rule\\/\\(\\[0-9\\]\\*\\)\\(\\?\\:\\/\\(\\[\\^\\?\\]\\*\\)\\)\\?\\$ kbox\\/kboxwww\\/common\\/jkuery\\.php\\?id\\=\\$1\\&p\\=\\$2\\&query_type\\=rule \\[QSA,L\\]\x5c
    RewriteRule \\^kbox\\/kboxwww\\/report\\/\\(\\[0-9\\]\\*\\)\\(\\?\\:\\/\\(\\[\\^\\?\\]\\*\\)\\)\\?\\$ kbox\\/kboxwww\\/common\\/jkuery\\.php\\?id\\=\\$1\\&p\\=\\$2\\&query_type\\=report \\[QSA,L\\]\x5c
    \\#give 404 on any documents starting with underscore from the jKuery samba share \\"other\\" directory.\x5c
    RewriteRule \\^kbox\\/kboxwww\\/jkuery\\/www\\/other\\/_\\.\\*\\$ \\[R\\=404,L\\]\x5c
\x5c
    \\#non-jkuery rewrite rules\x5c
/g
}
EOT;
   
      exec("echo '".$conf."' > ./httpd.2.sed.conf");
   }
} // end createHttpSed

//  #####################################################


$debugit = true; 

logu("Begin installing jKuery extension", true);

// Step 1) 
// Check version of K1000 software

$curVersion = getCurrentVersion();

if($debugit===true) {
	logu("Current version is: $curVersion", true );
}



// 5.1.31237 GA Release
$minVersion = 31237;

if($curVersion < $minVersion) {
    logu("K1000 jKuery $version FAILED - requires a minimum build level of ($minVersion), you are currently at ($curVersion).", true);
    exitCleanup(false);
}

// Step 1b: set version
setJkueryVersion("2.0");

 // Step 2: Unpack and run script
logu("Unpacking Files, Initializing Headers, Sourcing your code, configuring Samba",true);
// create support files if necessary
createHttpSed();
exec("/kbackup/upgrade/jkuery_install.sh >>".KB_LOG_DIR."update_log");

// Step 3: Create Db object
logu("Creating Database Objects",true);
if( createJSD('jkuery.sql') )
{
	logu("Database object already exists. Exiting object creation.",true );
} else {	
    logu("Database not created Successfully");
    logu("Creation of database objects failed. jKuery partially installed",true);
}

//	Step 4) Give permissions
logu("Assigning permissions to JKUERY tables",true);
if(dbGrants()){
	logu("Permissions assigned for JKUERY.*",true);
} else {
	logu("Failed to assign permissions",true);
	logu("jKuery partially installed",true);
	exitCleanup(false);
}


logu("jKuery install completed with no errors.  Please view readme for next steps",true);



// Step 5) Cleanup
exitCleanup(true);

?>
