How to install jquery.aboutjKuery.js
====================================
This plugin is installed by default with jKuery.  It uses jQuery 1.7+ which is also installed. 
However the plugin, as with any javascript in jkuery, needs to be activated. See the jkuery
readme for more details on enabling this and any other resources (js, css, etc) that you have.

Specifically to activate the "aboutjKuery" partial install please:
1.  rename (or copy and rename)
 \\k1000\jkuery\markers\KGlobalPageHeader.rename
to 
 \\k1000\jkuery\markers\KGlobalPageHeader
2. reload whatever K1000 webpage your are on

To uninstall it remove the "<script>" tag that is referencing "jquery.aboutjKuery.js" in any of your header files. To keep it uninstalled whenever you reapply the patch and even if you don't plan on using a global list of files (via KGlobalPageHeader) , then simply leave a zero byte file of the name KGlobalPageHeader in the markers directory.

What it does
======================================
The aboutjKuery.js script is, in web 2.0 terms, a jQuery "plugin", or to avoid confusion with the 
way we are using plugin, to describe jKuery, a "library"
This library is just javascript. So any javascript you have will operate similarly. This particular
library depends upon jQuery and jKuery beign deployed as well though. 

aboutjKuery will invoke iteself on any page that has the "about k1000" link (bottom left of most K1 pages).  
It removes that control and creates a new one that loads in an iframe.  
When install properly it will list the version of jKuery and, if detected, 
jQuery that are installed on your system.   

Tested with jquery 1.7.1
1. Copy the jquery.aboutjKuery.js file to any of the web accessbile jkuery directories 
(i.e. \\k1000\jkuery but not \\k1000\jkuery\hidden)
2. If needed put a copy of jQuery (1.7+) in there as well. e.g.  jquery.min.js
3. copy and rename the appropriate marker file for where you loaded it. e.g
KAdminPageHeader.rename -> KAdminPageHeader
4. make sure both jQuery lib and jquery.aboutjKuery.js files are listed in your marker file
5. reload your webpage that corresponds to the portal for that marker

