if( window.$ && window.jQuery == window.$){ // if $ exists and it is equivalent to jQuery then we have a global conflict with Prototype
  jQuery.noConflict(); // this is so we play nice with our existing kbox javascript.  By default jquery wants to be called "$" which kbox does not like;
} else {
  // no conflict so nothing to do; 
  // TODO: need test for 6.0 where jQuery is already on the appliance
}

(function($,K){
 /* put all your code in a closure like this
  * in the closure scope the $ refers to jQuery 
  * and K refers to jKuery
  */

  $(document).ready( function(){
      // all your code that requires the page to be loaded goes in one (or many) of these handlers

      /* example call to load aboutjKuery plugin -- commented out here intentionally */
      /* $('#aboutLink')
	  .aboutjKuery({"style":{"font-style": "bold","color":"red","font-size":"1.2em"}}); 
      */
  }); // end document loaded

    // put your code here

})(jQuery,jKuery);
