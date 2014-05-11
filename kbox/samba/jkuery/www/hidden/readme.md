Created by Gerald Gillespie 2014
jkuery v2.3
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
that is up to you and not really a pre-requisite of the patch, but the optional javascript we have included is
tested on most of the latest browsers at time of the kbin release.

Applying the patch
======================
If you are reading this on \\k1000\jkuery\www\hidden then you have already attempted to install this patch.  
However, you may need to re-install this patch so please read this entire section

1. Backup your database and take a copy offline
2. Your samba server will be restarted so make sure that no provisionings are taking place as they use that share
3. enable the samba share and set the password in your organization's settings. 
NOTE: make sure that your hostname is not "KBOX" as this will cause a samba conflict.
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
2. You should see at least 4 directories:  \2.x, \customer, \markers, \hidden
3. In the release version directory (e.g. \2.x) there are some *.js and *.css source files
4. You can use these any of these files and directories but you should not edit the OEM files
If you are getting some background 404 errors (you would see these in firebug or kbox access_log
but not in the UI) that probably means that you modified the contents (or filenames) of the files or
directories and do not have a file that is being referenced. Maybe you changed the name or moved it? 
Re-applying the patch will remedy this or creating the needed *.js and *.css files.
5. In the "\markers" directory you will find several *.rename files. You should not delete these files.  
These are overrides for any scripts you have.  If you leave them in tact and 
create no files in this directory then none of your scripts will be loaded.  
This is useful if/when you are troubleshooting a kbox problem and need to 
turn off all jkuery enhancements globally. see section "Activating Scripts By Example"
6. The "\customer" directory is where you can put your own scripts and know for certain they will not be 
activated.  Also anything in "hidden" cannot be found by the webserver but is accessible to you.
7. in "\hidden" there is an "_examples" directory.  You can put these files in the appropriate place
and follow the instructions provided in the matching readmes.  If you delete examples or other
OEM files you can restore them by re-applying the patch
8. If the order of your scripts loading matters then make sure you list them in that order where appropriate
9. Most customers will:

* put all their images in one spot -- you pick
* put all their css in one spot
* have separate js either in specific portals (allowing for more complexity if they want it)
    OR  have js just in the root (good for specific, simpler sripts but less flexible).
* then load images and css via JS (e.g. jQuery.load('')  or insert HTML into DOM)
10. There is a data access component.  see separate section on that

Database Access:
================
Database access to the JKUERY dbspace is provided.  You must set the password first and then initialize it. 
You can set the password in the ini file at \\k1000\jkuery\hidden\jkuery.ini.  The format of the ini file must be:
[jkuery]
password=whatever

Password must be compatible with mysql.  Some special characters may not be recognized. See mysql documentation. 

After it is set you can connect with:
username: jkuery
password: <set in ini file>
port:3306
dbspace: JKUERY

Data Access component (Data API):
================================
You can pull data out of the kbox into JSON format.  The data can be a stored in the database
as a JSON object (static string) or a query that builds a JSON object -- with optional query parameters.
Queries can be pulled from the custom JKUERY.JSON table, ticket rules and reports

Queries can be INSERTs, UPDATEs, DELETEs or, most commonly, SELECTs.  You must store these in the
appropriate JKUERY.JSON columns (e.g. INSERTs in JKUERY.JSON.INSERTstr)

When you have a stored query you can return the result as JSON by issuing a web request.  This stored
query is a service that you are creating.  Services are ORG specific. You should name your services.

Stored Queries can be in the form of prepared statements.  If you are using parameters (?) in your
statements you can provide dynamic data in your web request. 

Let's say you wanted to get USER data for USER_NAME=Gerald. Your URL would be something like:

http://k1000/jkuery/myuserquery/gerald

(this is a USER report via a service we called "myuserreport" and provided the parameter 'gerald')

The JSON that might come back might look like this:

```
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
```

Some other example URLs to access this same service are: 

*  using prepared query 105 passing parm "Gerald" and "kace.com"
 http://k1000/common/jkuery.php?id=105&query_type=sqlp&p1=Gerald&p2=kace.com
or 
 http://k1000/jkuery/105/Gerald/kace.com
or (preferred)
 http://k1000/jkuery/my+user+query+test/Gerald/kace.com

 in the db this is stored as (some columns hidden):

```
+-----+-------------------------------------------------------------------+--------------------+------------+
| ID  | SQLStr                                                            | NAME               | QUERY_TYPE |
+-----+-------------------------------------------------------------------+--------------------+------------+
| 105 | select * from USER where USER.NAME=? and EMAIL like concat('%',?) | my user query test | sqlp       |
+-----+-------------------------------------------------------------------+--------------------+------------+
```

--------------------------------------------------------------------------------------------------------

* using select query from rule #43 in current org.  passing  ticket_change#2 as parameter for <CHANGE_ID>  
 Allowing the result to be auto-converted into json
 http://k1000/common/jkuery.php?rule_id=my+service+for+rule+43&query_type=rule&p1=2
or (preferred)
 http://k1000/rule/my+service+for+rule+43/2
or 
 http://k1000/jkuery/101/2
 
in the JKUERY.JSON table this is stored as (some columns hidden):

```
+-----+-------------------+--------+------------------------+------------+
| ID  | HD_TICKET_RULE_ID | SQLStr | NAME                   | QUERY_TYPE |
+-----+-------------------+--------+------------------------+------------+
| 101 |                43 |   NULL | my service for rule 43 | rule       |
+-----+-------------------+--------+------------------------+------------+
```

--------------------------------------------------------------------------------------------------------

* using select query from REPORT ID 25 (does not work with tiered reports, only works with one-level OR
custom SQL reports) I reference the item in the JKUERY table which will point me to the correct Report.
Note that HD_TICKET_RULE_ID is a legacy name for this column, but it is a report ID.
 http://k1000/report/102

```
+-----+-------------------+--------+-------------+------------+
| ID  | HD_TICKET_RULE_ID | SQLStr | NAME        | QUERY_TYPE |
+-----+-------------------+--------+-------------+------------+
| 102 |                25 |   NULL | some report | report     |
+-----+-------------------+--------+-------------+------------+
```

Note: when use the `GET/SELECT` access to the API you typically want your query to return at least two rows.  If you only intend to obtain one row then do something like this (this example is actually an included example for the service call version):
```
select 'version' as VERSION, VALUE from KBSYS.SETTINGS where NAME = 'JKUERY_VERSION'
```

Notice how we put in a static string as the first column. This becomes the key for the result.  The output for this would be:
```
{
 ...
 "json" : {  "version" : "5.5.90548" }
}

Secure Access to the data API:
==============================

Authentication is session based.  When you login you do not need to login again for JKuery requests to work. 
But you must define permissions to the services you created.  You can do this by user label or by role. 
This relationship is defined in JKUERY.JSON_LABEL_JT and / or JKUERY.JSON_ROLE_JT

the service is applicable to the ORGs listed in these same tables

E.g. these entries in the JSON_LABEL_JT table:

```
+---------+--------+----------+
| JSON_ID | ORG_ID | LABEL_ID |
+---------+--------+----------+
|     101 |      1 |        2 |
|     101 |      1 |        1 |
|     102 |      1 |        1 |
+---------+--------+----------+
```

are interpreted as:

* JKUERY.JSON service at ID=101 is accessible to all USERs in ORG1 that are in Labels 1 and 2
* JKUERY.JSON service at ID=102 is accessible to all USERs in ORG1 that are in Labels 1 only

JSON_ROLE_JT is similar.  Any overlapping permissions for ROLE / LABEL are of course permitted.
Any intersection of permissions for ROLE / LABEL is inclusive.  

If you want a wildcard for testing simply use 0 for that item.  The following entry will give all USERS (USER_ID=0)
access to all JKUERY.JSON entries (JSON_ID=0) for all ORGs (ORG_ID = 0)

```
+---------+--------+----------+
| JSON_ID | ORG_ID | LABEL_ID |
+---------+--------+----------+
|       0 |      0 |        0 |
+---------+--------+----------+
```

Even though it is session based, you can access the data API remotely by using a token authentication scheme.  Origins of remote locations
and takens and mapped user id must be listed as a pair in the JKUERY.TOKENS table.  Origins can be a regex, but do not use the beginning (^) and ending ($) regex symbols since all ORIGINs are combined into a regex like this:   ^(ORIGIN1|ORIGIN2|etc)$

NOTE: remember that ORIGINS include ports

Tokens are stored in JKUERY.TOKENS. JSON_TOKENS_JT.  A token is a key that must be paired with the valid ORIGIN
definition provided.  By Origin I'm referring to the Origin of the http request.  

Here is an example token definition:

```
+----+------------------------------------------+---------------------------+
| ID | TOKEN                                    | ORIGIN                    |
+----+------------------------------------------+---------------------------+
|  1 | nothing                                  | https?://nowhere.comfooey |
|  2 | c22b5f9178342609428d6f51b2c5af4c0bde6a42 | https?://.*[.]kace[.]com  |
+----+------------------------------------------+---------------------------+
```

#1 is meaningless really because there is no comfooey domain but for #2 other resources in the kace.com domain can access this
via http or https if they provide the token 'c22b5f9178342609428d6f51b2c5af4c0bde6a42'.  

A token is mapped to a local user via the JKUERY.JSON_TOKENS_JT table.  So anyone using that tokens is,
as far as jkuery requests go, operating as that user by proxy.  Of course the permissions described
above would need to be setup for that user.  You might want to create a dummy, proxy user if you use the token scheme

Remember, when you are defining a token you are giving external sites (Origins) access to the JKuery data on this K1. 

```
+---------+--------+-----------+---------+
| JSON_ID | ORG_ID | TOKENS_ID | USER_ID |
+---------+--------+-----------+---------+
|       0 |      1 |         2 |      10 |
+---------+--------+-----------+---------+
```

Based on the TOKENS then any web request from kace.com origins will act as USER_ID in ORG1.  NOTE: JSON_ID is not used at this time
so you can set it to 0.  

There are no wildcards for tokens, but you can setup a flexible ORIGIN pretty easily.  You should get any
request working locally first (TIP: login to the web ui to establish a session and use the browsers debugging console)
and then, if needed, get it working remotely later

A token request looks like this:
`http://k1000/jkuery/102/?token=c22b5f9178342609428d6f51b2c5af4c0bde6a42`

e.g. with jQuery:

    jQuery.getJSON('http://dwsuf2013/jkuery/K1000%20Version/?token=hash')

When using tokens all you have to do is provide a hash/origin combination that points to a valid user.  Even if that user does not have permission on any webui tabs, they may still be able to run Jkuery requests.  The ability to run jquery requests is determined by a query similar to this (note the variables you'll need to replace).  

```
        select
		1 
	from
		JKUERY.JSON_LABEL_JT JL
		left join ORG1.USER_LABEL_JT UL on UL.LABEL_ID = JL.LABEL_ID
			and UL.USER_ID = $userid

	where 
	      JL.JSON_ID in ($this->id,0)
	      and JL.ORG_ID in ($this->org,0)
	      and (UL.USER_ID is not null or JL.LABEL_ID = 0)
	union all
	select 
	       1 
	from
		JKUERY.JSON J 
		join JKUERY.JSON_ROLE_JT JR on JR.JSON_ID in (J.ID,0)
		left join ORG$this->org.USER U on
			U.ROLE_ID = JR.ROLE_ID and U.ID = $userid
	where 
		J.ID = $this->id
		and JR.ORG_ID in ($this->org,0)
		and (U.ID is not null OR JR.ROLE_ID = 0)
	union all select 0
	limit 1
```

More Debugging tips:
====================
* login to web ui to establish an authenticated session and use the browser's deubbing console. 
* setup JKUERY_ROLE_JT entries for a special role you create and put your test users in
* test locally before going remote
* tokens can be very simple or not.
* Add debug=true in your requests (e.g. http://k1000/jkuery/102/?debug=true) to get more data returned in the JSON
and more feedback shown in the K1000 server log
* make sure you re-run your request you are hitting the server if desired and not using a cached request
By default the jKuery javascript object will cache requests using a hash.  
e.g.

    jKuery('my user query test',['Gerald','kace.com'],'GET',true);`

the `true` flag above will cause it to run right away and then you can access the data by running it again and requesting the data via `getData()`.  The reason you cannot use `getData()` in the first call is that we are working with ajax so the request probably has not completed yet.  jQuery does have the ability to "force" a wait BUT that feature is deprecated so we do not use it here.  

    jKuery('my user query test',['Gerald','kace.com'],'GET',true).getData();

Note this was equivalent to a request to: 
`http://k1000/jkuery/my+user+query+test/Gerald/kace.com`

Note a `GET` is also called a `SELECT`. in jKuery you can use either interchangeably for your convenience.  

But anyway, if you do this now you are neither re-running the request NOR getting new data -- you are getting cached data:

    jKuery('my user query test',['Gerald','kace.com'],'GET',true);
    
or this:

    jKuery('my user query test',['Gerald','kace.com'],'GET',true).getData();

The benefit of the cache is that you will not trigger unnecessary AJAX requests.  If you want to re-run the request against the source you can do that too....if you do either of these then you WILL re-run the request against the source. 

```
    jKuery('my user query test',['Gerald','kace.com'],'GET',true).setData(optionalcallback) // returns "this" i.e. the jKuery instance
```    
or

```
    jKuery('my user query test',['Gerald','kace.com'],'GET',true).runAjax(optionalcallback) // returns Promise
```

The difference in the above is that `setData()` will return the jKuery object.  The `runAjax()` method will return a jQuery promise.  In *most* cases you want to return a jQuery promise here so that you can access the result in a more convenient way like this: 

```
    jKuery('my user query test',['Gerald','kace.com'],'GET',true)
       .runAjax()  // returns Promise / Deferred
       .success(
           function(r){
	       // write the value into the webpage somewhere. r represents the response
	       */
	       $('#mydiv').text('r.json['somekeyvalue'])
	   }
          )
	.done(
	   // identical to the success callback above.  can chain as many of these as you want;
	   function(r){
	       // do something with r.json
	   }
	); // end
```
See the jQuery api for more on the [success callback](https://api.jquery.com/jQuery.ajax/) and  also see the apis docs on [Deferred.done()](https://api.jquery.com/deferred.done/) because an AJAX request is a Deferred object as well

The "true" flag above means run the request immediately.  Set to false if you want to set debug or a callback first, etc

When debugging the cache can be inspected by running `jKuery.getLastJSON()`.  This will return an internal hash for each cached instance.  E.g.
```
Object {H-1086503724: Object, H-766807184: Object}
```

Even more useful is running `jKuery()` without any parameters which will give you a list of the cache and the parameters that are unique to a cache (e.g. request method,name, parms,query type, source) . 

```
jKuery();
```

You can access the data from a specific item from the cache directly with:
```
jKuery('H-1086503724').getData();
```

In production code you would never use this direct method. You would simply recall jKuery the same way you originally did and it would automatically grab the data from the cache (unless you use a method that forces it to re-do the AJAX request against the server).  However, seeing how your parameters were "translated" into cache parms can be useful -- for exammple seeing "SELECT" being converted to "GET".

Note: The cache index value is not random. Given the same parameters the cache index value will be the same.

Reloading the webpage obviously destroys everything including the cache.

Using the jKuery javascript object with the data API:
====================================================
This is not required but exists for your convenience. 

If you plan to use javascript to access the data API then you should use the jKuery object that is
included in jquery.jKuery.X.X.min.js file.  Some sample calls are:

* var K = jKuery( request, [parms [, method , [,  runnowflag ]]])
    * requestname type: string or integer.  Name or ID of JKUERY.JSON row
    *  parms       type: Array of strings. e.g. ['Gerald','1']
    * runnowflag  type : boolean
    * method      type : string (GET, POST, PUT, etc)
* var K = jKuery( url [, runnowflag])
    * url   type : string of full request URL
    * runnowflag  type : boolean

* jKuery( requestname, parms )
* jKuery( ruleID , parms)
* jKuery( reportID, parms) 

There is no support for direct name references for rules and reports because this would break control over which ones run since a user with
access to rules/reports might not have JKUERY.JSON access, but they probably have access o the rule / repor definition
and might change a rule/report name just to run that one instead. Rule and reports names are also not unique.
so "name" is always a reference to the JKUERY row.  But the query that gets run for them comes FROM the rule's or report's definition

if you call `jKuery('servicefoo')` with the same request/ parms combination as a previous request on this page
then you will be given a reference to the cached instance not a new instance.  All cached instances are stored
in an internal object as a hash of their reqest/parms combo.   Cached instances have a way to re-run (runAjax method)
and to update on an interval (setInterval)

AJAX requests are asynchronous (obvious) so a great way to call them in development is:

```
    var myvar,
    callback = function(){
			myvar = this.getData();  // or this.getData().json
		};
    jKuery('Session Value',[':user_id']).setDebug(true).setData(  callback  );
```

The reason this works is that the context for jKuery AJAX requests are always the instance of the jKuery object.
When the request returns `myvar` will be set to the JSON data returned, even if an error is returned. 

Another great way is what was talked about in the debugging section above with the use of the `runAjax()` method and the fact that it returns a Promise/Deferred Object.  Read that section for more info.

Using a Timer to keep a value up to date:
=========================================
jKuery has a built-in timer mechanism which can be used to keep a value up to date without re-running the request manually. 

E.g.
```
    jKuery(1002,['test'],'GET',true).setInterval(1000,function(){
        alert(this.getData());
    });
```

In the example above every 1000 milliseconds (1 second) an alert would pop up with the value and the current time. Of course in this example the data doesn't change but you might have a request that does. 

Note that a value of 0 will stop the timer.  Otherwise a value from 1-999 will default to 15 minutes (cuz that's just too fast otherwise).  Values >1000 will be honored as entered. 

There is also an example in the "about" demo of using a timer.  There the about information is actually loaded by Ajax.  This is triggered when the about link is clicked.  The demo also attaches itself to the click event of the same link.  When the about link is clicked a timer starts. Essentially it keeps checking until the result of the Ajax is loaded and when it is it injects the jkuery information and then turns off the timer.  Something like this:

```
    /* detect if the link is there */
    if( $('.k-modal[href*="about.php"]').length > 0 ){
              var $about = $('.k-modal[href*="about.php"]'),
	      $jkuerypatched = $('<span id="jkuerypatched">').css(cfg.style);
	      /* attach a click handler to the link */
	      $about.on('click', function(){
	        /* run the convenience function to get the jKuery version.  This returns a jKuery object which we can
		* chain with other jKuery methods.  In this case we chain setInterval with a callback that will keep
		* looking for the loaded data every 1000 milliseconds.  
		*/
                K.getJKVersion()
                  .setInterval(1000, function(){
		    if($('p.k-about-version').length > 0){
                      $jkuerypatched
                        .text('jKuery Version: '
			      + this.getData().json.version
			      + ' with jQuery ' + jQuery.fn.jquery );
	 	      /* when it exists prepend the strings to it */
                      $('p.k-about-version').prepend('<br/>').prepend($jkuerypatched);
		    /* turn the timer off */
		    this.setInterval(0,function(){});
		    }
	          }); // setInterval ;
              }); // on click ;
	    }
```	    

Canned Variables:
=================
In version 2.1+ there are some canned variables that you can use. These are session variables and so are specific to the user that is logged in. 

They are: 

```
:user_name
:user_id
:user_email
:org_id
:role_id
:platform
```

They should all be obvious except for possible `:platform` which is the OS platform as detected via the User agent.  

How to disable jkuery:
======================
Option#1: Move all *.css and *.js files to the "hidden" directory.  you could even copy your entire
tree (except for "other") into "hidden". Clear your browser cache.  This will cause some 404s but users's
won't see them

Option#2: make the contents of markers directory look like this (and nothing extra) (see 
"Activating Script" section for details) and reload the page. Meaning delete the ones that don't end
in ".rename":

```
\markers\
			KGlobalPageHeader.rename
			KAdminPageHeader.rename
			KPageHeader.rename
			KPrintablePageHeader.rename
			KSysPageHeader.rename
			KUserPageHeader.rename
			KWelcomePageHeader.rename
			KWelcomePageHeaderSys.rename
```			

Option#3: Preferred
Modify the contents of the corresponding file (e.g. KGlobalPageHeader) so that it does not reference
undesirable, or all, scripts, etc

Sample contents of KGlobalPageHeader (that you would have to create or modify for other purposes):

```
+------------------------------------------------------------------------------------------+
|<script type="text/javascript" src="/jkuery/www/2.2/jquery.min.js"></script>              |
|<script type="text/javascript" src="/jkuery/www/2.2/jquery.jKuery.2.2.min.js"></script>   |
|<script type="text/javascript" src="/jkuery/www/2.2/jquery.aboutjKuery.min.js"></script>  |
|<script type="text/javascript" src="/jkuery/www/2.2/default.js"></script>                 |
|<script type="text/javascript" src="/jkuery/www/customer/my.js"></script>                 |
|<link rel="stylesheet" href="/jkuery/www/adminui/2.2/default.css" />                      |
+------------------------------------------------------------------------------------------+
```

Activating Scripts (by Example)
===============================
This is what \markers looks like when you want to disable
jkuery:

```
markers\
			KGlobalPageHeader.rename
			KAdminPageHeader.rename
			KPageHeader.rename
			KPrintablePageHeader.rename
			KSysPageHeader.rename
			KUserPageHeader.rename
			KWelcomePageHeader.rename
			KWelcomePageHeaderSys.rename
```

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
  contents:<script type="text/javascript" src="/jkuery/www/customer/myscript.js"></script>
\markers\KAdminPageHeader.rename (existence trumped by file above so this is irrelevant now)
\markers\KWelcomePageHeader.rename (no other KWelcomePageHeader file so welcome is deactivated)
\markers\KPageHeader.rename
\markers\KPrintablePageHeader.rename
\markers\KSysPageHeader.rename
\markers\KUserPageHeader.rename
\markers\KWelcomePageHeaderSys.rename

Example of a script that works on all pages that have a header EXCEPT the welcome pages
\markers\KAdminPageHeader
  contents:<script type="text/javascript" src="/jkuery/www/customer/myscript.js"></script>
\markers\KSysPageHeader
  contents:<script type="text/javascript" src="/jkuery/www/customer/myscript.js"></script>
\markers\KPageHeader
  contents:<script type="text/javascript" src="/jkuery/www/customer/myscript.js"></script>
\markers\KUserPageHeader
  contents:<script type="text/javascript" src="/jkuery/www/customer/myscript.js"></script>
\markers\KPrintablePageHeader
  contents:<script type="text/javascript" src="/jkuery/www/customer/myscript.js"></script>
\markers\KAdminPageHeader.rename
\markers\KWelcomePageHeader.rename 
\markers\KPageHeader.rename
\markers\KPrintablePageHeader.rename
\markers\KSysPageHeader.rename
\markers\KUserPageHeader.rename
\markers\KWelcomePageHeaderSys.rename

Special Notes about re-applying the patch
=========================================
1. read all previous instructions
2. file and database entries you created will (should) remain untouched.  
OEM Files in the \\k1000\jkuery\x.x share will be overwritten
3. This will recreate any other missing files e.g. marker files you deleted
4. All existing and new files that you are specifying in custom markers files will be re-linked. 
The database portion will only be updated / initialized if it does not exist or is not to spec
Existing db entries will remain but may be updated
5. If you changed any of the marker files by naming them or otherwise then do not worry. Your 
relevant changes will trump them. Only the rename files will be replaced. 
6. After re-applying if you find that any access to your \\k1000\client* shares is different 
then what you expect this is due to the patch restoring a previous configuration. To fix this 
simply open up the webui and click "edit" then "save".  No change is necessary.  
It will redo your settings and be reconfigured without a reboot
7. this will recreate any core libraries such as jkquery.min.js
8. The password to the share will be the admin (ORG1) share password. This is always true,
but because of the reboot you might be forced to remap or relogin.

Special Note about kbox upgrades
=================================
While your javascrpt may need to change, that is irrelevant here. Obviously the product is not 
going to cater to potential customizations you have made without disclosure. This is about things 
that are common to all customers

0. You should test an upgrade on an offline VM first
1. You must apply (or reapply) the matching jkuery patch after an kbox upgrade as an OEM upgrade will turn them all off. 
Assuming the new kbox version is supported with the jkuery kbin,
this will re-link your scripts against the updated kbox files
2. your scripts may not work the same on the newer kbox version because:
    * the DOM has changed (even slightly can affect your scripts)
    * or you were using names for your variables or functions in the global namespace and the kbox
OEM javascript is now using that name.  TIP: use unique name and encapsulate as much of your work
as you can. i.e. There is no reason this can't be easily avoided.
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
EXCEPTION: due to a bug in 5.5 the database is not backed up. Please contact support to make sure
this is backed up or take steps to backup this up yourself.

There is nothing stopping you from grabbing the files yourself from the `\\k1000\jkuery` share
and making queries to the database to grab that data.

What can I do with scripts
==========================
This is out of scope for this doc:See the `\\k1000\jkuery\other\_examples` directory, faqs, etc.  

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
* canned services for jkuery version, kbox version (rows in JKUERY.JSON) as examples
* javascript object for convenient use of data api (jKuery)
* minified OEM js libs
* more parms in debug output
* dynamic definition of js/css inclusions without restart or reapplying patch
* readonly OEM files in \\k1000\jkuery
* unit testing in QUnit
* build script for kbin
* support 5.5

2.2
===
* support CRUD operations in RESTful way (HEAD,GET,POST,PUT,DELETE,OPTIONS methods)
    * (legacy -- can still do INSERTs, etc via GET/POST if using sqlpi query type)
* support for invoking full, on-ticket-save, ticket rules (update included) on a given ID
* support invoking all rules (batch type rules)
* more jKuery js object convenience functions for things like ticket #, change #, pagename, etc
* wildcards for local permissions

2.3
===
* support for K1 6.0.101863
* if jQuery already exists on the kbox then jKuery will load and uses the jQuery library that ships with kbox by default (kbox 6.0 => jQuery 1.10)
* fixed bugs in IE with ajax requests
* you can now set the database password for the jkuery user.  See readme section on database.
* there is a timer function called setInterval that can be used to keep a value up to date.   see readme section on "Timer"


(future)
========
* support for K1000 6.1
* support for K2000 ?.?
* support for K3000 ?.?
