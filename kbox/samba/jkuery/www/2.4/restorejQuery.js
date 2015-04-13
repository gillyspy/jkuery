/* this file will restore the global jQuery to the first version of jQuery that was loaded
i.e. if this is a 5.x box then there is likely no conflict and it will be the version of jQuery that comes with the jKuery plugin. 
if it is a 6.x box then there is likely a conflict so it will be the OEM version of jQuery that ships with kbox 

Note: this will do nothing if there is no conflict. 
*/
jQuery.getjQuery('root',true);
