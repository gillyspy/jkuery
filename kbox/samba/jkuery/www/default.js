if( window.$ && window.jQuery == window.$){ // if $ exists and it is equivalent to jQuery then we have a global conflict with Prototype
  jQuery.noConflict(); // this is so we play nice with our existing kbox javascript.  By default jquery wants to be called "$" which kbox does not like;
} else {
  // no conflict so nothing to do; 
  // TODO: need test for 6.0 where jQuery is already on the appliance
}


  $(document).ready(  // all you code goes in one (or many) of these handlers
    function($)
    { 
    $('#aboutLink')
      .aboutjKuery({"style":{"font-style": "bold","color":"red","font-size":"1.2em"}}); 
    }
  ); // end document loaded
