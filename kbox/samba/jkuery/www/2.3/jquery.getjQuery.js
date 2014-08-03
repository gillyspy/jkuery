/* this function will restore the jQuery version that was called as well as be all to return the other versions 
*/

/* run this plugin AFTER all jQuery libs have been loaded */

( function($){
//    $ will always be the version that called this first;
    // use "this" to get the version that is currently calling it;
    var n = 'getjQuery',
    $tack = {},
    $current,
    $last,
    usage  = '\n Usage: jQuery.'+n+'(jQuery,"x.y.z", [ global] )'
	+ '\n global is either ( true | false | null)',
    m =
	{
	    init : function( $, target, restore )
	    {
		/* restore values are:
		'global' => means to make the version requested global
		true => equivalent to global (default)
		false => means to keep the global the same version it was
		null => means to remove jQuery global altogether. 
		if restore is null then the user should be assigning the result of this to another variable. e.g.  var myjQuery = jQuery.getjQuery('1.7.1');
		or
		(function($){
              		// $ is an instance of jQuery here
		})( jQuery.getjQuery('1.7.1', null ) )

		*/

		var msg = [];
		if( restore === undefined ){
		    restore = true;
		}

		// stack is shared;
		m.fn.$tack = $tack; 

		/*go through the entire internal jQuery stack. Along the way
		  make sure that each jQuery has the current stack and this plugin defined on it
		  */
		$last = $;
		$current = this;
		//always rebuild the stack in case a new version of jQuery was added;
		while( $last ){
		    // current jQuery needs the plugin ($tack is attached to plugin)
		    $last[n] = m.fn;
		    msg.push( $last.fn.jquery );
		    // the stack is not complete so we'll add to the stack
		    $tack[ jQuery.fn.jquery ] = $last;
		    $tack[ 'root' ] = $last;
		    $last.noConflict(true);
		    $last = jQuery;
		    
		}
		//restore jQuery to the version that was requested or the calling version;
		if( restore ){
		    jQuery = $tack[ target ] || this;
		} else if( restore === null ){
		    // do nothing
		} else if( !restore ){
		    jQuery = this;
		}
		

		// all versions should be in the $tack now so return it.
		// return root version otherwise;
		if( !$tack[ target ] ){
		    $
		    console.log('Cannot find the requested version of jQuery.  '
				+'The following versions are available: ' + msg.join(',')
				+ '.  Returning ' + (jQuery || $current || $).fn.jquery
				+ usage );

		    return (jQuery || $current || $);
		}
		return $tack[ target ];
	    }, // init ;
	    fn : function(method)
	    {
		if (m[method]) {
		    return m[method].apply(this, Array.prototype.slice.call(arguments, 1));
		} else if ( arguments.length <= 2) {
		    //add current jQuery to beginning of arguments and then call init
		    Array.prototype.unshift.call(arguments, $);
		    return m.init.apply(this, arguments);
		} else if (arguments.length = 0) {
		    // return the versiont that called it
		    return this;
		} else {
		    $.error('Method ' + method + ' does not exist on jQuery.'+ n + usage);
		}
	    } // fn ;
	} // m

    // declare as jQuery plugin ;
    $[n] = m.fn;
})(
    jQuery
);

