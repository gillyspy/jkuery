/*jslint plusplus:true, todo:true, devel: true, browser: true */

/* global jQuery:true, jKuery:true, jKuery */

/* this is a list of helper functions that are specifically designed for use of jQuery and jKuery
 with the K-series appliances */

/* TODO: jKuery is an object.  It depends upon jQuery
 * if proper version of jQuery is not available it will load it (RequireJS?)
 */

/* usage: 
 *  var K = new jKuery.Lib();
 * K.getVersion();  // returns the version; 
 * K.aboutjKuery(); // implements the jKuery "about k1000" dialogue;
 *
 * data api usage: 
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
 */
(function($){

  
 // depend upon jQuery
  // do not allow two jKuery
  if(!$.fn.jquery || window.jKuery){
    return false;
  }

  // TODO: proper check to see if $ (i.e. jQuery) is proper version and defined;
  var verJQueryCompatible = ['1.10'];
  //TODO: we will feedback compatibility with a specific version but also allow in-between versions with a warning;
  //TODO: use AMD like RequireJS for loading jQuery? other k-box specific libs? ;
  /* IDEA:
   * maybe some kind of loop on  where we look for versions (with dashes instead of dots) on disk and if we can't find that 
   * we then look for apis on web (e.g. google code)
   */

  var fn = {
    dotDotDot : function(e)
    { // an animated "..." that can be used while waiting for a response
      setInterval( 
	function() {
	  var elTxt = $(e).text();
	  $(e).text(  elTxt.length > 3 ? elTxt : elTxt +'.' );
	}, 100
      );
      return true;
    } // end dotDotDot;
    ,
    inquireJQuery: function()
    {
      //TODO:;
      // ask the library what version of jquery it needs;
      // check to see if library has that ability and if not then just use current version;
      return $.fn.jquery; // return current closure version for now;
    }, // end inquireJQuery;

    getLib : function(){
      console.log('todo');
      //TODO:;
      // helper to go and get one of the jKuery canned JS libs;
      /* getting a lib means
       ** we have a list of libs
       ** for each lib do the following (getLib)
       ** using ajax to load it  
       ** determining which versions of jquery it is compatible (tested) with
       ** loading the proper version of jQuery if not already loaded (e.g. 6.0 loads 1.10)
       ** invoking it
       
       RequireJS to do this? 
       */
    }, // end GetLib;

    addSource : function(){
      console.log('todo');
      //TODO  a way to add on to this.sources;
    }  // end AddSource;
  }; // end fn

  window.jKuery = { }; // global on window;
  var jKuery = window.jKuery;
  jKuery.JSON = function(){
    console.log('nothing');
    //stub for existence;
  }; 

  var m = 
	{ // basic set methods
	  setFormat : function(format)
	  {
	    this.format = format || (this.format || 1);
	    return this;
	  },

	  setTimeout : function(timeout)
	  {
	    this.timeout = timeout || (this.timeout || 10000);
	    return this;
	  },

	  setDebug : function(debug)
	  {
	    this.debug = !!debug && /^(on|true|1)$/.test(debug) ? 'true' : 'false';
	    return this;
	  },

	  // TODO: make it possible to map the returned column names into DOM data elements (e.g. AngularJS-style);
	  //TODO would need a way to bind the jKuery.JSON to a DOM object (via JQuery ref);
	  setObj$ : function($el)
	  {
	    this.obj$ = $($el);
	    return this;
	  },
	  
	  setHost : function(host){
	    this.host = host || (this.host || window.location.origin);
	    // TODO even bother looking at KBSYS.SETTINGS ?  any way that this could ever be superior to window.location.origin?;
	    return this;
	  }, // end setHost;

	  clearInterval : function()
	  {
	    clearInterval(this.timer);
	    return true;
	  },

	  updateObj$ : function(e)
	  {
	    var $e = $(e); // make sure jQuery attached to it
	    $e.html(this.getData());
	    return this;
	  }
	}
  ; // end var

  fn.setget = function(action,oVar) 
  {  // this is used as a setter for the basic variables in jKuery.JSON object
    var i,
	method;
    if(typeof oVar == "string"){
      method = action + oVar.slice(0,1).toUpperCase() + oVar.slice(1);
      if(m[method]){ // call setX method
	return m[method].apply(this, Array.prototype.slice.call(arguments,2) );
      } 
    }else if(oVar instanceof Array){
      for(i = 0; i < oVar.length; i++){
	fn.setget.call(this,action,oVar[i]);	
      }
    } else {
      $.error('Neither ' + oVar.toString() + ' nor ' + method + ' are avaialble');
    }
    return false;
  }; // end setget

  fn.set = function(oVar){ // setter stub
    return fn.setget.call(this,'set',oVar);
  };
  fn.get = function(oVar){ // getter stub
    return fn.setget.call(this,'get',oVar);
  };

//TODO obsolete? 
  fn.Req = function(hash,my) 
  { // utility to lookup cached JSON requests references by hash
//    if(!isNaN(parseFloat(hash)) && isFinite(hash))
  //    hash = hash.toString();
    if( jKuery.LastJSON && jKuery.LastJSON[hash] && jKuery.LastJSON[hash] instanceof jKuery.JSON){
      return jKuery.LastJSON[hash];
    }

    $.error('Cached request (' + my.toString() + ') not found');
    return false;
  };
      
  $.extend(
    true, 
    window.jKuery,
    {
      JSON : function(name,parms,source,qtype,run)
      {
	//TODO add a timer for JSON so that it can update itself on an interval.
	// jKuery.LastJSON[hash] is a reference to each instance
	var state='new',
	    data = {},
	    hash,
	    timer,
	  interval,
	    ajaxSettings = {},
	    callback = [function(){}];
	source = source || 'jkuery';
	  run = !!run;
	//TODO: basic test to see if API is accessible otherwise give error; 
	//TODO: allow this to be called with an object of settings instead
	qtype = qtype || 'sqlp';
	hash = fn.hash(name,parms,source,qtype);

	if(!jKuery.LastJSON || !jKuery.LastJSON[hash]) {
	  $.error("You must instantiate this via jKuery.newJkuery method");
//	  this = jKuery.getJKVersion(); // make it the same as a simple object if instantiated in the wrong way
	  return false;
	}

	fn.set.call(this,['format','host','timeout']);

	this.getParms = function(){
	  return parms;
	};
	this.getQtype = function(){
	  return qtype;
	};
	this.getSource = function(){
	  return source;
	};
	this.getState = function(){
	  return state;
	};
	this.setState = function(s){ 
	  state = s; 
	  return this;
	};
	this.setState(undefined);

	this.getData = function()
	{
	  return data;//jKuery.LastJSON[hash].getData() || data || {};
	};

	this.getName = function(){
	  return name;
	};

	  this.setRun = function(bool){
	      run = !!bool;
	      return this;
	  }; 

	  this.runAjax = function(callback){
            // returns the ajax & promise ; 
	      this.setAjax(callback);
	      return $.ajax(ajaxSettings);
	  };
	  
	this.setData = function(callback)
	  {
	    // similar to runAjax except returns the object for chaining;
	      this.runAjax(callback);
	      return this;
	};

	var setTimer = function(callback)
	{
	  var self = this;
          self.setState('complete');
	  if(interval > 1000){
            self.setState('idle');
	    timer = setTimeout( 
	      function(){
		  if(run){
		      self.runAjax.call( self,[callback,function(){setTimer.call(self,callback)}] );
		  } else {
                    setTimer.call(self,callback);
                  }
	      }
	      , interval // instance private variable;
	    ); // end setTimeout;
	  }
	};
	
	// use the timer function to keep data set up to date.  Your callback might be to repopulate the item with data;
	this.setInterval = function(t,callback)
        {
          t = (t > 1000 || t == 0) ? t : undefined;  // min 1 second; use 0 to clear only;
          // an undefined time will yeield a 15 min timer
          // any new value between 0 and 1000 will keep the exising timer
          // 0 to end the timer
          // > 1000 to set it again
          interval = t !=undefined ? t : ( interval || (15*60*1000)); //15 mins;
          setTimer.call(this,callback);
          return this;
        };

	this.setAjax =  function(callback) 
	{  //  a helper function to run the ajax call that will get data from kbox into the object
	  if(!(this instanceof jKuery.JSON)){
	    throw 'jKuery JSON object not instantiated';
	  }
          
          var callbackArr = [
            function(){ this.setState('complete');}
          ];

	  //this.analyzeConfig();
	  $.extend(
	    ajaxSettings, 
	    {
	      context : this,
	      url : this.buildAjaxURL(),
	      data : 
	      {
		debug :  this.debug,
		jautoformat : this.format,
		query_type :  this.getQtype()
	      },
	      dataType : 'json',
	      type : 'POST',
	      timeout : this.timeout,
	      beforeSend: function(){ this.setState('refreshing');},
	      success : function(d)
	      {
		data = d;
	      },
	      error : function(a,b,c)
	      {
		data = {};
		  // set responseJSON even in an error condition for convenience
		$.extend(data,a.responseJSON); 
		data.message = b+': '+c;
	      }
	    }
	  ); // end extend;
	  
	    // TODO: move this to a callback adder function;
	  if(callback !== undefined && callback instanceof Array){
	    ajaxSettings.complete = callbackArr.concat(callback);
	  } else if (callback){
	    ajaxSettings.complete = callbackArr.push(callback);
	  }

	  return ajaxSettings;
	}; // end setData

	if(run){
	  this.runAjax(); // optionally make the call for the data
	}
      } // end jKuery.JSON constructor;
    }
  ); // end extend

  $.extend(  // object merge
    true, //deep copy
    jKuery.JSON.prototype, //target object
    m, // specific closure methods
    {   // additional prototype functions
      buildAjaxURL : function()
      {
	var p,i,l,encode;
	p = !this.getParms() instanceof Array ? this.getParms().split() : this.getParms();
	encode = [ this.getName() ].concat(p);
	for(i = 0, l = encode.length; i < l; i++){
	  encode[i] = encodeURI(encode[i]);
	}
	return this.host 
	  + '/' + this.getSource() 
	  + '/' + encode[0] 
	  + '/' + encode.slice(1, l).join('/');
      }, // end buildAjaxURL;

      //TODO: obsolete?
      analyzeConfig : function(){
	var i, reqd;
	// minimum required parameters listed here
	reqd = ['Name','parms'];
	for(i = 0; i< reqd.length; i++){
	  if(this[reqd[i]] === undefined){
	    throw new Error("missing " + reqd[i]);
	  }
	}
      },

      hasData : function()
      {
	// helper to see if a JSON call function returned data or not
	if (this.data.count && this.data.count > 0){
	  return true;
	} 

	return false;
      } // end HasData;
    } // end jKuery.JSON prototype;
  ); // end extend;

  /******************************************************/

  fn.getJSONSkeleton = function(n){
    var source,qtype;
    switch(n){
      case 1: // rule direct;
      source = qtype = 'rule';
      break;
      case 2: // report direct;
      source = qtype = 'report';
      break;
      case 3: // rule via JKUERY.JSON
      source = 'jkuery';
      qtype = 'rule';
      break;
      case 4: // report via JKUERY.JSON
      source = 'jkuery';
      qtype = 'report';
      break;
      default: // jkuery direct;
      source = 'jkuery';
      qtype = qtype || 'lookup' ;
      break;
    } // end switch;

    return function(a,b,e,f){ 
      var name,parms,doRun;

      /* examples: 
       * jKuery.newJkuery('GetUser','John Doe');
       * jKuery.newRule(59,'13345');  // rule
       * jKuery.newReport(1,'Bob-XP',true); // run report #100 against variable Bob-XP and process it now
       */
      var patt = /^.*[^\/]\/+[^\/].*$/;
      if ( patt.test(a) ) 
      {	// it's an url
	patt = /^(http.?:\/\/[^\/]+|..)\/(jkuery|rule|report)\/([^\/]+)(?:\/|((?:\/[^\/?]+)+))(?:[?](.*))?$/;
	var url = a.match(patt);
	source = url[2]; // e.g. "rule"
	name = url[3];
	parms = url[4].split('/').slice(1); // parms array
	qtype = url[5].match(/query_type=[^=]+/); // query string
	doRun = parms || true; 
      } else {
	name = a;
	parms = b;
	doRun = e || false;
	if(f !== undefined){
	  // when f is defined then f is the flag
	  qtype = f;
	  doRun = f;
	}
      }
      if(!jKuery.LastJSON){ // only create this when needed
	jKuery.LastJSON = {};
      }
      var hash = fn.hash(name, parms, source, qtype);

      if(jKuery.LastJSON[hash]){
	return jKuery.LastJSON[hash];
      }

      jKuery.LastJSON[hash] = {};
      jKuery.LastJSON[hash] = new jKuery.JSON(name, parms, source, qtype,doRun);
	return jKuery.LastJSON[hash];
    };
  };

  fn.hash = function(){
    var s='',
	hash = 0,
	strlen,
	i,
	l,
	c;

    for(i=0,l=arguments.length; i < l; i++){
      s += arguments[i].toString();
    }
    strlen = s.length;
    if ( strlen === 0 ){
      return hash;
    }

    for ( i = 0; i < strlen; i++ ) {
      c = s.charCodeAt( i );
      hash = ((hash << 5) - hash) + c;
      hash = hash & hash; // Convert to 32bit integer
    }
    return 'H'+hash.toString();
  }; // end hash;

  jKuery.getJKVersion = function()
  {
    var VersionTest = jKuery.newJkuery('jKuery Version','',false); // even failed requests return the version;
    VersionTest.setTimeout(1000);
    return VersionTest;
    //TODO
    /*
     * alls calls return the version but there may not be any accessible services so 
     * a simple call to http://host/jkuery/0 will return the version albeit with a "failed" status code.  
     * TODO: unlike a failed ajax though this helper should always return a  Promise to help keep a dependency chain
     * probaby should use a special request in jkuery.php to facilitate this
     */
  };

    jKuery.getKVersion = function()
    {
	var VersionTest = jKuery.newJkuery('K1000 Version','',false);
	VersionTest.setTimeout(1000);
	return VersionTest;
    }

  $.extend(
    true, 
    jKuery, 
    { // make global
      Lib :  function()
      {
	//TODO make sure that it's being implemented as a constructor only
	this.sources = {
	  'aboutjKuery' : {
	    method : 'aboutjKuery',
	    source: 'jkuery/www/other/js/jquery.aboutjKuery.js',
	    element : '#aboutLink',
	    parms : {"style":{"font-style": "bold","color":"red","font-size":"1.2em"}}
	  } 
	};
      } // end jKuery.Lib constructor
      ,
      newJkuery : fn.getJSONSkeleton(5),
      newRule : fn.getJSONSkeleton(1),
      newReport : fn.getJSONSkeleton(2),
      newJkueryRule : fn.getJSONSkeleton(3),
      newJkueryReport : fn.getJSONSkeleton(4)
    } // end jKuery
  ); // end extend

  $.extend( 
    jKuery.Lib.prototype,
    { 
      Init : function()
      {
	console.log('todo');
	//TODO;
	// should this be in the constructor ? ;
      }, // end Init;

      getKVersion : function()
      {
	//TODO return the kbox version;
	// requires data api
	return 'todo';
      } // end getVersion
    } // end prototype
  );

})(window.jQuery); // end "immediate" 

/* 
 * This will read the kbox version from the database using the webservices api instad of inferring from DOM
 *
 */

/* the build number is available in the DOM in the script tags but that's more volatile 
 * this is more resource intensive but it is also instructive as a tutorial of sorts for more complex ops
 */



