This is partially installed by default with jKuery.  
To complete the partial install please:
1)  rename
 \\k1000\jkuery\markers\KWelcomePageHeader.rename 
to 
 \\k1000\jkuery\markers\KWelcomePageHeader
2. re-apply the patch via server maintenance

To uninstall it and keep it uninstalled whoever you reapply the patch simply leave a zero byte file of the same name  (jquery.aboutjKuery.js) in the root directory.


If you have never had it thenÉ.
How to install jquery.aboutjKuery.js
======================================
This plugin has the ability to run on any page with an "about k1000" link.  It removes that control
and creates a new one that loads in an iframe.  When install properly it will list "jkuery
installed" in the list of options

tested with jquery 1.7.1
1. Copy the jquery.aboutjKuery.js file to any of the working directories
(\jkuery or \jkuery\adminui, etc)
2. If needed put a copy of jquery in there as well. e.g.  _jquery.min.js
3. copy and rename the appropriate marker file for where you loaded it. e.g
KAdminPageHeader.rename -> KAdminPageHeader
4. re-install the patch to link these files. 


Alternate install:
1. open the default.js in any folder.  Copy the contents of jquery.aboutjKuery.js file into that file
in the appropriate place
2. in the document.ready function make a call to it something like this:
    $j('#aboutLink')
    	.aboutjKuery({"style":{"font-style": "bold","color":"red","font-size":"1.2em"}});

