/*jslint plusplus:true, todo:true, devel: true, browser: true */

/* global jQuery:true, jKuery:true, jKuery */

/* Gerald Gillespie 2012-2013 */
/* This script will change the about box to load inline some information about jKuery
 * The about box has no head of it's own to leverage so that is why we load it in an iframe on the current page 
 */

if( window.$ && window.jQuery == window.$){ // if $ exists and it is equivalent to jQuery then we have a global conflict with Prototype
  jQuery.noConflict(); // this is so we play nice with our existing kbox javascript.  By default jquery wants to be called "$" which kbox does not like ;
} else {
  // no conflict so nothing to do; 
  // TODO: need test for 6.0 where jQuery is already on the appliance
}

(function($,K) {
  var 
  _cfg = 
    { //system globals;
      "_n": "aboutjKuery"
    },
  m = 
    {  
      cfg: 
      { // defaults;
	"t" : function()
	{
	  K.getJKVersion()
	    .setRun(true)
	    .runAjax()
	    .always( function(a,b,c){
	      var v = K.getJKVersion().getData().version;
	      $('#abouthidden')
		.contents()
		.find('#jkuerypatched')
		.html(  '   with jKuery: '+ ( v || 'n/a') +' using jQuery: '+$.fn.jquery);
	    }); // end getJKVersion
	  return '   with jKuery: ... using jQuery: ...';
	},  // change the text;
	"style" : {}   // you can pass a style in object notation for the jkuery patched words;
      },
      init: function(cfg) 
      {
	cfg=$.extend({}, m.cfg, cfg);
	return this.each(
	  function()
	  {
	    var
            $this = $(this),
	    iPrepared=false,
	    $jkuerypatched=$('<span id="jkuerypatched">'+cfg.t()+'</span>'),
	    $abouthidden=$('<iframe src="/common/about.php" id="abouthidden" height="745px"\
                           width="348px" style="overflow:hidden;position: fixed; left: 10px; bottom:\
                               30px;z-index: 10000;"></iframe>');
	    $this.find('a').after('<a href="#">About K1000</a>').remove().end()
	      .on('click.'+_cfg._n,'a',
		  function(e) 
		  {
		    var $a=$(this);
		    if($a.text()=='About K1000') {
		      if(iPrepared)  // if loaded once just cache it in case they click on it again
		      {
			$abouthidden.show();
		      } else // not loaded
		      {
			$abouthidden.load(
			  function() 
			  {
			    var $closethis=$('<a id="closethis" href="#">close this window</a>');
			    $closethis.on('click.'+_cfg._n,
					  function(e)
					  {
					    $a.trigger('click.'+_cfg._n);
					    e.preventDefault();
					  }); // end click
			    $abouthidden
			      .contents()
			      .find('#versionText').find('br:eq(0)').after('<br/>')
			      .after($jkuerypatched.css(cfg.style));
			    $abouthidden
			      .contents().find('body').css('overflow','hidden')
			      .find('div:last').append('&nbsp;&nbsp;&nbsp;').append($closethis);								
			    iPrepared=true;
			    cfg.t();
			  }); // end load
			$('body:first').append($abouthidden);
		      }		// end if prepared
		      $a.text('Close About');
		    } else // currently loaded
		    {
		      $abouthidden.hide();
		      $a.text('About K1000' );
		    } // end if
		    e.preventDefault();
		  });// end on click
	  }); // end each 
      } // end init
    }; // end all methods
  
  $.fn.aboutjKuery = function(method) {
    if (m[method]) {
      return m[method].apply(this, Array.prototype.slice.call(arguments, 1));
    } else if (typeof method === 'object' || !method) {
      return m.init.apply(this, arguments);
    } else {
      $.error('Method ' + method + ' does not exist on jQuery.'+_cfg._n);
    }
  };

})(jQuery,jKuery);


(function($,K){
/*
 * TODO: research if module loading using an AMD like RequireJS is necessary for jkuery projects
 */

  $(document).ready(  function(){
      $('#aboutLink')
	  .aboutjKuery(
            {
              "style":
              {
                "font-style": "bold",
                "color":"red",
                "font-size":"1.2em"
              }
            }
          ); 
  }); // end document loaded
})(jQuery,jKuery);
