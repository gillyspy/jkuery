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


$debugit = true; // Use true to get additional script debug information, and prevent file deletion use false to turn it off.

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

function createJSD()
{
	$db = _u_dbConnect('KBSYS');
	$sql = "select * from JKUERY.JSON";
	try{
		if($debugit === true){
			logu($sql,true);
		}
		$db->Execute($sql);
		logu("able to query from database object",true);

		return false;
	} catch (Exception $e) {
		// table does not exist so create it
		if($debugit === true){
			logu("not able to query from database object",true);
			logu($sql,true);
		}
		exec("/bin/cat /kbackup/upgrade/jkuery.sql | /usr/local/bin/mysql -uroot -pkbox19 KBSYS >>".KB_LOG_DIR."update_log");
		return true;
	}
}

function createBNames()
{
	$db = _u_dbConnect('KBSYS');
	$ret=true;
	$BNames = getBNames();
	foreach($BNames as $u) {
		try{
			$db->Execute("GRANT SELECT, INSERT, UPDATE, DELETE ON `JKUERY`.`JSON` TO '$u'@'%'");
		}catch (Exception $e){
			return false;
		}
	}
		$RNames = getRNames();
	foreach($RNames as $u) {
		try{
			$db->Execute("GRANT SELECT ON `JKUERY`.`JSON` TO '$u'@'%'");
		}catch (Exception $e){
			return false;
		}
	}
		return $ret;
}


function checkDBfilesExists()
{

	$filename1 = '/kbox/mysql/var/JKUERY';
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

function exitCleanup($jKueryDone=false){

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
	} else {
	  logu("jKuery not successfully installed.  Please see errors and contact services",true);
	}

	exit();
}


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


// Step 2) Unpack and run script
logu("Unpacking Files, Initializing Headers, Sourcing your code, configuring Samba",true);
exec("/kbackup/upgrade/jkuery_install.sh >>".KB_LOG_DIR."update_log");

// Step 3) Create Db object
logu("Creating Database Objects",true);

if(checkDBfilesExists()){
	logu("Database object already exists. Exiting object creation.");
	exitCleanup(true);
} else {	
	if(createJSD()){
	  if(checkDBfilesExists()){ // check again
	  	logu("Database was created successfully");
	  } else {
	  	logu("Database not created Successfully");
	  	exitCleanup(true);
	  }
	} else {
		logu("Creation of database objects failed. jKuery partially installed",true);
		exitCleanup(false);
	}
}



//	Step 4) Give permissions
logu("Assigning permissions to JKUERY table",true);
if(getBNames()){
	logu("Permissions assigned for JKUERY.JSON",true);
} else {
	logu("Failed to assign permissions",true);
	logu("jKuery partially installed",true);
	exitCleanup(false);
}


logu("jKuery install completed with no errors.  Please view readme for next steps",true);



// Step 5) Cleanup
exitCleanup(true);

?>
