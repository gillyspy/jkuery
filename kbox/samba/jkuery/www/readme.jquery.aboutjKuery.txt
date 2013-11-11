How to install jquery.aboutjKuery.js
====================================
This plugin is installed by default with jKuery.  It uses jQuery 1.7+ which is also installed. 
However the plugin, as with any javascript in jkuery, needs to be activated. See the jkuery
readme for more details on enabling this and any other resources (js, css, etc) that you have.

Specifically to activate the "aboutjKuery" partial install please:
1.  rename (or copy and rename)
 \\k1000\jkuery\markers\KWelcomePageHeader.rename 
to 
 \\k1000\jkuery\markers\KWelcomePageHeader
1.1 Optionally do the same for KAdminPageHeader
2. re-apply the jKuery patch (the kbin) via server maintenance

To uninstall it, and keep it uninstalled whenever you reapply the patch, simply leave a zero byte file of the same name  (jquery.aboutjKuery.js) in the root directory.


What it does
======================================
The aboutjKuery.js script is, in web 2.0 terms, a jQuery "plugin", or to avoid confusion with the 
way we are using plugin to describe jKuery, a "library"
This library is just javascript. So any javascript you have will operate similarly. This particular
library depends upon jQuery beign deployed as well though. 

aboutjKuery will invoke iteself on any page that has the "about k1000" link (bottom left of most K1 pages).  
It removes that control and creates a new one that loads in an iframe.  
When install properly it will list the version of jKuery and, if detected, 
jQuery that are installed on your system.   

Tested with jquery 1.7.1
1. Copy the jquery.aboutjKuery.js file to any of the working directories
(\jkuery or \jkuery\adminui, etc)
2. If needed put a copy of jQuery (1.7+) in there as well. e.g.  _jquery.min.js
3. copy and rename the appropriate marker file for where you loaded it. e.g
KAdminPageHeader.rename -> KAdminPageHeader
4. re-install the patch to link these files. 


Alternate install:
1. open the default.js in any folder.  Copy the contents of jquery.aboutjKuery.js file into that file
in the appropriate place
2. in the document.ready function make a call to it something like this:
    jQuery('#aboutLink')
    	.aboutjKuery({"style":{"font-style": "bold","color":"red","font-size":"1.2em"}});

