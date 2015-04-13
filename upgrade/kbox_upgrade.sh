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

include_once('./install_utils.inc');

// Use true to get additional script debug information, and prevent file deletion use false to turn it off.
$debugit = true; 
$version = "2.4";
$verMatch = false;
$tryVersion = array("6.0.101863",
		    "6.0.101864",
		    "6.0.101865",
		    "6.2.109329",
		    "6.2.109330",
		    "6.3.112740",
		    "6.3.113397"
		    );
$Kversion = get_version_number();


//  #####################################################

$debugit = true; 

logu("Begin installing jKuery extension", true);

// Step 1) 
// Check version of K1000 software

//$curVersion = getCurrentVersion();

if($debugit===true) {
  logu("Current version is: $Kversion", true );
}

foreach($tryVersion as $serverVersion){
  logu("- looking for KBOX compatible version $serverVersion ...");
  if(0 == versionCompare($Kversion, $serverVersion, false)) {
    $verMatch = true;
    logu("- found compatible version");

    // Step 1b: set version
    setJkueryVersion($version);

    // Step 3: Create Db object
    logu("Creating Database Objects",true);
    if( createJSD('jkuery.sql') ){
      logu("Database JKUERY.* objects exists. Exiting object creation.",true );
      // Step 2: Unpack and run script
      logu("Unpacking Files, Initializing Headers, Sourcing your code, configuring Samba",true);
      // create support files if necessary
      createHttpSed();
      
      checkSambaConflict();
      logu( "Note: if you had previous jkuery files they will be moved to \\host\jkuery\customer",true);

      exec("/kbackup/upgrade/jkuery_install.sh >>".KB_LOG_DIR."update_log");

      //	Step 4) Give permissions
      logu("Assigning permissions to JKUERY tables",true);
      if(dbGrants()){
	logu("Permissions assigned for JKUERY.*.  To set the password for jkuery db access please see the readme file.",true);
	$complete = true;
      } else {
	logu("Failed to assign permissions",true);
	logu("jKuery partially installed",true);
	$complete = false; 
      }
    } else {	
      logu("Database not created Successfully");
      logu("Creation of database objects failed. jKuery partially installed",true);
      $complete = false;
    }

    // Step 4.5 clear Smarty Templates
    logu("Deleting cached templates in order to rebuild with jkuery headers",true);
    clearSmartyCache();
    
    // Step 5) Cleanup
    if($complete) {
      logu("jKuery install completed with no errors.  Please view readme for next steps",true);
      if( file_exists('/kbox/samba/jkuery/www/hidden/readme.md') ){
	logu('Readme file is at \\host\jkuery\hidden\readme.md');
      }
      exitCleanup(true);
    } else {
      exitCleanup(false);
    }
  }
}
?>
