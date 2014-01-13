Created by Gerald Gillespie 2013
jkuery v2.2
readme.md

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
1. Only tested on 5.3 L10N release and 5.5.  Should work on every version of the kbox to date that takes the 
kbin format of patches. (i.e. 5.2+)
2. The browsers that you are running should support the javascript that you are writing. Of course
that is up to you and not really a pre-requisite of the patch

Applying the patch
======================
If you are reading this on \\k1000\jkuery\www\hidden then you have already attempted to install this patch.  
However, you will often re-install this patch so please read all these instructions
1. Backup your database and take a copy offline
2. Your samba server will be restarted so make sure that no provisionings are taking place as they use that share
3. enable the samba share and set the password in your organization's settings. 
If you have a multi-org box, you must do this step in ORG1. 
4. Go to Settings->Server maintenance and apply the patch as an update. However, The kbox version will not change
5. The server will redirect you back to the update log.  Scan the recent entries in that log for any 
fatal errors. The kbox will not reboot like it would for a full server update, but the webserver will restart 
so you may lose web access for a moment.

How to use the patch once applied
==================================
There is no userinterface for this patch. You must know the secret sauce given here.  There is no
permanent evidence in the web interface that it is enabled apart from the update log
1. Browse to \\k1000\jkuery directory and login with your ORG1 samba share credentials. If you do
not know these are set in the General settings of each orgs (Settings->General)
2. You should see at least 5 directories:  \adminui, \systemui, \userui, \other, \markers, \hidden
3. In the release version directory (e.g. \2.1) there are some *.js and *.css files
4. You can use these files but you should not edit them. 
If you are getting some background 404 errors (you would  see these in firebug or kbox access_log
but not in the UI) that means that you modified the contents of the directories and do not have 
a file that is being referenced. Maybe you changed the name or moved it? 
Re-applying the patch will remedy this or creating the needed *.js and *.css files.
5. In the "\markers" directory you will find several *.rename files. You should not delete these files.  
These are overrides for any scripts you have.  If you leave them in tact and 
create no files in this directory then none of your scripts will be loaded.  
This is useful if/when you are troubleshooting a kbox problem and need to 
turn off all jkuery enhancements globally. see section "Activating Scripts By Example"
6. The "\other" directory is where you can put your own scripts and know for certain they will not be 
activated.  Also anything in "hidden" cannot be found by the webserver.
7. in "\hidden" there is an "_examples" directory.  You can put these files in the appropriate place
and follow the instructions provided in the matching readmes.  If you delete examples you can 
restore it by re-applying the patch
8. If the order of your scripts loading matters then make sure you list them in that order
listing.  
9. Most customers will:
* put all their images in one spot -- you pick
* put all their css in one spot
* have separate js either in specific portals (allowing for more complexity if they want it)
    OR  have js just in the root (good for specific, simpler sripts but less flexible).
* then load images and css via JS (e.g. jQuery.load('')  or insert HTML into DOM)
10. There is a data access component.  see separate section on that

Database Access:
================
Database access to the JKUERY dbspace is provided with 
username: jkuery
password: <same as the "admin" user's ORG1 password at the time you last applied the kbin>
port:3306
dbspace: JKUERY

ata Access component (Data API):
================================
You can pull data out of the kbox into JSON format.  The data can be a stored JSON object (static 
string) or a query that builds a JSON object, with optional query parameters.  Queries can be pulled
from the custom JKUERY.JSON table, ticket rules and reports

When you have a stored query you can return the result as JSON by issuing a web request.  This stored
query is a service that you are creating.  Services are ORG specific

Let's say you wanted to get USER data for USER_NAME=Gerald. Your URL would be something like:
this is a USER report limited to USER_NAME=Gerald)
The JSON that might come back might look like this:
{   
    "message":"",
    "version":"2.0",
    "purpose":"this is from smarty!",
    "status":"success",
    "json":
    {	
    	"1":
	{
                "ID":"35",
		"USER_NAME":"Gerald",
		"PASSWORD":"*",
		"EMAIL":"gerald@kace.com",
		"BUDGET_CODE":"",
		"DOMAIN":"",
		"FULL_NAME":"Gerald Gillespie",
		"MODIFIED":"2013-11-06 10:31:22"
		...
	}				
    }				
}

some other example URLs to access this service are: 

*  using prepared query 105 passing parm "Gerald" and "kace.com"
 http://k1000/common/jkuery.php?id=105&query_type=sqlp&p1=Gerald&p2=kace.com
 http://k1000/jkuery/105/Gerald/kace.com

* using select query from rule #43 in current org.  passing  ticket_change#2 as parameter for <CHANGE_ID>  
 Allowing the result to be auto-converted into json
 http://k1000/common/jkuery.php?rule_id=43&query_type=rule&p1=2
 http://k1000/rule/43/2

* using select query from rule #50. Forcing the formatted result to be provided by the rule'squery.  passing no parameter
 http://k1000/common/jkuery.php?rule_id=50&query_type=rule&p1=false&org_id=2&jautoformat=0
 http://k1000/jkuery/X?query_type=lookup&jautoformat=0
 (note X would be a JKUERY.JSON reference to 50)

* using select query from whatever ticket rule is tied to JKUERY rule#1000. passing change #10
 http://k1000/common/jkuery.php?id=1000&query_type=rule&p1=10
 http://k1000/jkuery/1000/10?query_type=lookup

* using select query from REPORT ID 25 (does not work with tiered reports)
 http://k1000/report/25

Secure Access to the data API:
========================
You must define permissions to the services you created.  You can do this by user label or by role. 
This relationship is defined in JKUERY.JSON_LABEL_JT and / or JKUERY.JSON_ROLE_JT

the service is applicable to the ORGs listed in these same tables

You can access the data API remotely by using a token authentication scheme.  Origins of remote locations
and takens and mapped user id must be listed as a pair in the JKUERY.TOKENS table.  Origins can be a regex.

Using the jKuery javascript object with the data API:
====================================================
This is not required but exists for your convenience. 

If you plan to use javascript to access the data API then you should use the jKuery object that is
included in jquery.jKuery.min.js file.  Some sample calls are:
 * var K = new jKuery.JSON( request, parms [, source [, querytype [,  boolean]]])
 ** requestname   type: string or integer.  Name or ID of JKUERY.JSON row
 ** parms       type: string or Array of strings.  
 ** source      type: string
 ** querytype   type: string
 ** boolean     type : boolean
 *
 * var K = new jKuery.JSON( url [, boolean])
 ** url   type : string of full request URL
 *
 * jKuery.newJkuery( requestname, parms )
 * jKuery.newRule( ruleID , parms)
 * jKuery.newReport( reportID, parms) 
 *
 * there is no support for name references for rules and reports BUT well this would break control over which ones run since a user with 
 *  access to rules/reports might not have JKUERY.JSON access.  They might change a rule/report name just to run that one instead.
 * so "name" is always an ID for these

if you call "new jKuery.JSON(blah) with the same request/ parms combination as a previous request on this page
then you will be given a reference to the cached instance not a new instance.  All cached instances are stored
in jKuery.LastJSON as a hash of their reqest/parms combo.   Cached instances have a way to re-run (runAjax method)
and to update on an interval (setInterval)

How to disable jkuery:
======================
Option#1: Move all *.css and *.js files to the "hidden" directory.  you could even copy your entire
tree (except for "other") into "hidden". Clear your browser cache
Option#2: make the contents of markers directory look like this (and nothing extra) (see 
"Activating Script" section for details) and reload the page
\markers\
			KGlobalPageHeader.rename
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
			KGlobalPageHeader.rename
			KAdminPageHeader.rename
			KPageHeader.rename
			KPrintablePageHeader.rename
			KSysPageHeader.rename
			KUserPageHeader.rename
			KWelcomePageHeader.rename
			KWelcomePageHeaderSys.rename
in order to activate scripts that you provide you will need to make a copy of the file without the ".rename" 
extension for that web portal. e.g. for the Admin portal you would create "KAdminPageHeader" and list
the files you want to load inside of that file.
Having scripts in the \adminui dir is irrelevant. This is just there for legacy reasons but could help with
your own bookkeeping of the files.
scripts will be linked (active).  Here is a mapping to which files work on which dir:
KGlobalPageHeader      : apply to all web portals and login screens
KPrintablePageHeader   : \not specific to any portal
KPageHeader	       : \not relevant 
KAdminPageHeader       : admin portal page
KWelcomePageHeader     : admin portal login page
KSysPageHeader	       : system portal pages
KWelcomePageHeaderSys  : system portal login page
KUserPageHeader	       : User portal pages

Example of activating a script only on the main Admin interface but not on the admin welcome page (contents of file below):
\markers\KAdminPageHeader
  contents:<script type="text/javascript" src="/jkuery/www/myscript.js"></script>
\markers\KAdminPageHeader.rename (existence trumped by file above so this is irrelevant now)
\markers\KWelcomePageHeader.rename (no other KWelcomePageHeader file so welcome is deactivated)
\markers\KPageHeader.rename
\markers\KPrintablePageHeader.rename
\markers\KSysPageHeader.rename
\markers\KUserPageHeader.rename
\markers\KWelcomePageHeaderSys.rename

Example of a script that works on all pages that have a header EXCEPT the welcome pages
\markers\KAdminPageHeader
  contents:<script type="text/javascript" src="/jkuery/www/myscript.js"></script>
\markers\KSysPageHeader
  contents:<script type="text/javascript" src="/jkuery/www/myscript.js"></script>
\markers\KPageHeader
  contents:<script type="text/javascript" src="/jkuery/www/myscript.js"></script>
\markers\KUserPageHeader
  contents:<script type="text/javascript" src="/jkuery/www/myscript.js"></script>
\markers\KPrintablePageHeader
  contents:<script type="text/javascript" src="/jkuery/www/myscript.js"></script>
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
2. file and database entries you created will remain untouched.  
Original Files in the \\k1000\jkuery\2.1 be overwritten
3. This will recreate any other missing files e.g. marker files you deleted
4. All existing and new files that you are specifying in markers will be re-linked. 
The database portion will only initialized if it does not exist.
5. If you changed any of the marker files by naming them or otherwise then do not worry. Your 
relevant changes will trump them. Only the rename files will be replaced. 
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
the *file.tgz archive and the data (which you might not be using) portion will be in the database. 
Exception: due to a bug in 5.5 the database is not backed up. Please contact support to make sure
this is backed up

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
* hidden files in samba share that www cannot access (good for readmes, etc)

2.1
===
* get JSON data out of Kbox reports.  can specify a limiter for # of records
  e.g. records 10 to 30 of computers stored in report 5 is requested as:
  http://k1000/report/5/10/20
* support for "names" of services isntead of numbers
* support for some canned variables (:user_name, :user_id, :user_email, :org_id, :role_id, :platform)
* canned services for jkuery version, kbox version
* javascript object for convenient use of data api
* minified OEM js libs
* more parms in debug output
* dynamic definition of js/css inclusions without restart or reapplying patch
* readonly OEM files in \\k1000\jkuery
* unit testing in QUnit
* build script for kbin

2.2
===
* support CRUD operations in RESTful way (GET,POST,PUT,DELETE,OPTIONS methods)
** (legacy -- can still do INSERTs, etc via GET/POST if using sqlpi query type)
* support invoking full ticket rules (update included) on a given ID
* more jKuery convenience functions for things like ticket #, change #, pagename, etc
* support for K1 6.0

(future)
========
* support for K1000 6.1
* support for K2000 ?.?
* support for K3000 ?.?
* invoke a ticket rule -- not just capture the query
* convenience functions for referencing current page name, ticket #, tabname, etc
