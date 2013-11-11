Created by Gerald Gillespie 2012
jkuery v2.0
readme.txt

Welcome to jKuery!
If you installed this then you are interested in using canned or developing your own 
UI enhancements or data-integrations in the K1000. Some of the things you can do:

Features:
==========
1. Implement Process-driven (client-driven) granular security
2. Form validation (e.g. assets, tickets)
3. UI manipulation
4. Modify request/ response model in some areas --> performance improvements
5. Get custom data from one area of kbox (e.g. database) onto any other page
6. You create it!

Pre-requisites:
=================
1. Only tested on 5.3 L10N release.  Should work on every version of the kbox to date that takes the 
kbin format of patches. (i.e. 5.2+)
2. The browsers that you are running should support the javascript that you are writing. Of course
that is up to you and not really a pre-requisite of the patch

Applying the patch
======================
If you are reading this on \\k1000\jkuery then you have already attempted to install this patch.  
However, you will often re-install this patch so please read all these instructions
1. Backup your database and take a copy offline
2. Your samba server will be restarted so make sure that no provisionings are taking place
3. enable the samba share and set the password in your organization's settings. 
If you have a mult-org box, you must do this step in ORG1. 
4. Go to Settings->Server maintenance and apply the patch as an update. 
The kbox version will not change
5. The server will redirect you back to the update log.  Scan the recent entries in that log for any 
fatal errors. The kbox will not reboot like it would for a full server update


How to use the patch once applied
==================================
There is no userinterface for this patch. You must know the secret sauce given here.  There is no
permanent evidence in the webinterface that it is enabled apart from the update log
1. Browse to \\k1000\jkuery directory and login with your ORG1 samba share credentials. If you do
not know these are set in the General settings of each orgs (Settings->General)
2. You should see 4 directories:  \adminui, \systemui, \userui, \other, \markers
3. In the root and in the *ui directories there are two files: default.js and default.css
4. You can edit and use these files. The only recommendation is that you have at least one *.js and
one *.css in each of the directories mentioned in step 3 
If you are getting some background 404 errors (you would  see these in firebug or kbox access_log
but not in the UI) that means that you modified the contents of the directories and no longer have 
at least one *.js nor *.css file in each of the mentioned locations in step 3. 
Re-applying the patch will remedy this or creating the needed *.js and *.css files.
5. In the "\markers" directory you will find several *.rename files.  These are overrides for any 
scripts you have.  If you leave them in tact and create no files in this directory then none of your
scripts will be loaded.  This is useful if/when you are troubleshooting a kbox problem and need to 
turn off all jkuery enhancements globally. see section "Activating Scripts By Example"
6. The "\other" directory is where you can put scripts and know for certain they will not be 
activated
7. in "\other" there is an "_examples" directory.  You can put these files in the appropriate place
and follow the instructions provided in the matching readmes.  If you delete examples you can 
restore it by re-applying the patch
8. If the order of your scripts loading matters then name the files according to an alphabetical
listing.  e.g. if you want jquery.js to load first then call your other file:  zkuery.myscript.js or 
rename jquery.js to _jquery.js and re-apply the patch.  The code in your scripts should never be 
affected by the names of *.js nor *.css files UNLESS you are specifically calling them by filename
in a script --> In that case you should put your callee in the "other" directory and not have
worry about when we will load it. 
9. Most customers will:
* put all their images in one spot -- you pick
* put all their css in one spot
* have separate js either in specific portals (allowing for more complexity if they want it)
    OR  have js just in the root (good for specific, simpler sripts but less flexible).
* then load images and css via JS (e.g. jQuery.load('')  or insert HTML into DOM)
10. There is a data access component.  

How to disable jkuery:
=======================
Option#1: Move all *.css and *.js files to the "other directory".  you could even copy your entire
tree (except for "other") into "other" and then re-apply the patch
Option#2: make the contents of markers directory look like this (and nothing extra) (see 
"Activating Script" section for details) and re-apply the patch. 
\markers\
			KAdminPageHeader.rename
			KPageHeader.rename
			KPrintablePageHeader.rename
			KSysPageHeader.rename
			KUserPageHeader.rename
			KWelcomePageHeader.rename
			KWelcomePageHeaderSys.rename



Activating Scripts (by Example)
===============================
This is what \markers looks like when you want to disable
jkuery:
markers\
			KAdminPageHeader.rename
			KPageHeader.rename
			KPrintablePageHeader.rename
			KSysPageHeader.rename
			KUserPageHeader.rename
			KWelcomePageHeader.rename
			KWelcomePageHeaderSys.rename
in order to activate scripts that you provide you will need to remove the ".rename" marker or 
create a file in the markers directory without that extension. e.g. "KAdminPageHeader"
Afer that, if you have any scripts in the \adminui dir then you can reapply the patch and your 
scripts will be linked (active).  Here is a mapping to which files work on which dir:
KPrintablePageHeader :  \not specific to any portal
KPageHeader					:		\not relevant at this time
KAdminPageHeader   	:		\adminui
KWelcomePageHeader 	:		\adminui
KSysPageHeader			:		\systemui
KWelcomePageHeaderSys:	\systemui
KUserPageHeader			:		\userui

Example of activating a script only on the main Admin interface but not on the admin welcome page:
\adminui\myscript.js
\markers\KAdminPageHeader
\markers\KAdminPageHeader.rename (existence trumped by file above so this is irrelevant now)
\markers\KWelcomePageHeader.rename (no other KWelcomePageHeader file so welcome is deactivated)
\markers\KPageHeader.rename
\markers\KPrintablePageHeader.rename
\markers\KSysPageHeader.rename
\markers\KUserPageHeader.rename
\markers\KWelcomePageHeaderSys.rename

Example of the exact same scenario is another way:
\myscript.js
\markers\KAdminPageHeader
\markers\KAdminPageHeader.rename (existence trumped by file above so this is irrelevant now)
\markers\KWelcomePageHeader.rename (no other KWelcomePageHeader file so welcome is deactivated)
\markers\KPageHeader.rename
\markers\KPrintablePageHeader.rename
\markers\KSysPageHeader.rename
\markers\KUserPageHeader.rename
\markers\KWelcomePageHeaderSys.rename

Example of a script that works on all pages that have a header EXCEPT the welcome pages
\myscript.js
\markers\KAdminPageHeader
\markers\KSysPageHeader
\markers\KPageHeader
\markers\KUserPageHeader
\markers\KPrintablePageHeader
\markers\KAdminPageHeader.rename
\markers\KWelcomePageHeader.rename 
\markers\KPageHeader.rename
\markers\KPrintablePageHeader.rename
\markers\KSysPageHeader.rename
\markers\KUserPageHeader.rename
\markers\KWelcomePageHeaderSys.rename

Special Notes about re-applying the patch
===========================================
1. read all previous instructions
2. Your files and database data will remain untouched.  If you have added content to default.js or
default.css then those will be untouched.  If you have renamed them they will be recreated.
3. This will recreate any other missing files e.g. "default.js" and "default.css"  \other\examples
files in, etc in \\k1000\jkuery  and \\k1000\jkuery\adminui, etc.    
If you have been writing javascript in those files the do not worry as they will not be overwritten
4. All existing and new files will be re-linked. The database portion will only initialized if it
does not exist.
5. If you changed any of the marker files by naming them or otherwise then do not worry. Your 
relevant changes will trump them
6. After re-applying if you find that any access to your \\k1000\client* shares is different 
then what you expect this is due to the patch restoring a previous configuration. To fix this 
simply open up the webui and click "edit" then "save".  No change is necessary.  
It will redo your settings and be reconfigured without a reboot
7. this will recreate any core libraries such as jkquery.min.js 

Special Note about kbox upgrades
=================================
While your javascrpt may need to change, that is irrelevant here. Obviously the product is not 
going to cater to potential customizations you have made without disclosure. This is about things 
that are common to all customers
1. You must re-apply the patch after an kbox upgrade as an upgrade will turn them all off. 
This will re-link your scripts against the updated kbox files
2. your scripts may not work the same on the newer kbox version because:
* the DOM has changed (even slightly can affect your scripts) 
* or you were using names for your variables or functions in the global namespace and the kbox
OEM javascript is now using that name.  TIP: use unique name and encapsulate as much of your work
as you can
* if you have made manual changes to config files (e.g. apache, samba) that include jkuery info 
then that means when you reapply jkuery they will be undone because the backup that jkuery made 
last time  will not have your customizations.  However, if you changed config files by 
replacing them (e.g. a kbox upgrade or kbox patch) then those will be not have any jkuery 
data in them and therefore will not be restored from backup and thus these config files will 
only be augmented by jkuery (after being backed up first)

Backing up your data
=====================
Your kbox runs a nightly maintenance routine every day at 2am. Of course you already parse that 
email automatically in your helpdesk creating a ticket when any errors arise don't you?  

Well you should, but I digress.  Your jkuery data is backed up automatically. The files will be in 
the *file.tgz archive and the data (which you might not be using) portion will be in the database

However,there is nothing stopping you from grabbing the files yourself from the \\k1000\jkuery share

What can I do with scripts
============================
This is out of scope for this doc:See the \\k1000\jkuery\other\_examples directory, faqs, etc.  

Revision History
================

1.0
===
* GA version
* support and auto-linking for customer web files at /jkuery/www
* RW access to www files via \\k1000\jkuery share
* loading of all web resources to customer-designated, specific portals (user, admin, system) or globally

1.1
===
* added installer in kbin form

1.2
===
* added JKUERY database object and webservices via local, authenticated common/jkuery.php
  resource for professional services use

2.0
===
* using GIT depot
* increase support for larger ID values in JKUERY.JSON table
* added TOKENS database object for "authenticated"  remote access to jkuery.php 
  (also will make necessary require policy updates to apache)
* added REST style access to jkuery.php e.g.   https://k1000/jkuery/ID/parm1/parm2?extraparms=value
* adds status codes, jkuery version, purpose and error messages to JSON output
* adds ORG restrictions to JKUERY.JSON prepared statements
* grants read access to KBSYS.NETWORK_SETTINGS to jkuery.php
* installer upgrades previous version to 2.0 
* adds R/W customer access to JKUERY dbspace data via "jkuery" user
   using admin's web password (re-install jkuery kbin to update a changed password)
* database setting (KBSYS.SETTINGS) for version and enabled or not
* hidden files in samba share that www cannot access (good for readmes, tc)

(future)
========
* support for K1000 6.0
* support for K2000 ?.?
* support for K3000 ?.?
