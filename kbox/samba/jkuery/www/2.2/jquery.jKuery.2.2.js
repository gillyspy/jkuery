/*jslint plusplus:true, todo:true, devel: true, browser: true */

/* global jQuery:true, jKuery:true, jKuery */

/* this is a list of helper functions that are specifically designed for use of jQuery and jKuery
 with the K-series appliances */

/* TODO: jKuery is an object.  It depends upon jQuery
 * if proper version of jQuery is not available it will load it (RequireJS?)
 */

/* usage: 
 * jKuery.getKVersion();  // returns the version of the kbox
 * jKuery.aboutjKuery(); // implements the jKuery "about k1000" dialogue;
 *
 * data api usage: 
 * var K = jKuery( request, [parms, [, method  [,  runflag]]])
 ** requestname   type: string or integer.  Name or ID of JKUERY.JSON row
 ** parms       type: Array of strings.
 ** method      type : string of the request method / CRUD operation
 ** source      is always looked up so don't specify it
 ** querytype   is always looked up so don't specify it
 ** runflag     type : boolean
 * returns the servicename has or the ajax promise depending on it you run it. 
 *
 * var K = new jKuery( url [, boolean])
 ** url   type : string of full request URL
 *
 * jKuery( requestname, parms )
 * obsolete:
 * jKuery.newJkuery(requestname,parms)
 * jKuery.newRule( ruleID , parms)
 * jKuery.newReport( reportID, parms) 
 *
 * there is no support for name references for rules and reports BUT well this would break control over which ones run since a user with 
 *  access to rules/reports might not have JKUERY.JSON access.  They might change a rule/report name just to run that one instead.
 * so "name" is always an ID for these
 */

(function($){
  // depend upon jQuery ; 
  // do not allow two jKuery ; 
  if(!$.fn.jquery || window.jKuery){
    return false;
  }

  var verJQueryCompatible,
      fn = {},  // global hidden functions;
      LastJSON = {}, // global cache of jKuery objects ;
      JSONlist = {}, // simplified list of the LastJSON cache;
      jKuery,
      version = "2.2",
      m; // global hidden methods 
      
  
  
  // TODO: proper check to see if $ (i.e. jQuery) is proper version and defined;
  verJQueryCompatible = ['1.10'];
  //TODO: we will feedback compatibility with a specific version but also allow in-between versions with a warning;
  //TODO: use AMD like RequireJS for loading jQuery? other k-box specific libs? ;
  /* IDEA:
   * maybe some kind of loop on  where we look for versions (with dashes instead of dots) on disk and if we can't find that 
   * we then look for apis on web (e.g. google code)
   */
  fn = {
    dotDotDot : function(e)
    { // an animated "..." that can be used while waiting for a response ; 
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
    } // end inquireJQuery;
    ,
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
    } // end GetLib;
    ,
    addSource : function(){
      console.log('todo');
      //TODO  a way to add on to this.sources;
    }  // end AddSource;
    ,
    listJSON : function(){
      JSONlist = {}; // use a external variable for memory purposes;
      for(var key in LastJSON){
        JSONlist[key] = {
          name : LastJSON[key].getName(),
          parms : LastJSON[key].getParms(),
          source : LastJSON[key].getSource(),
          query_type : LastJSON[key].getQtype(),
          method : LastJSON[key].getMethod()
        };
      }; 
      return JSONlist;
    }  // end listJSON ;
    ,
    getJSONSkeleton : function(n){
      var source,qtype;
      switch(n){
      case 1: // rule direct;
        source = qtype = 'rule';
        break;
      case 2: // report direct;
        source = qtype = 'report';
        break;
      case 3: // rule via JKUERY.JSON ; 
        source = 'jkuery';
        qtype = 'rule';
        break;
      case 4: // report via JKUERY.JSON ; 
        source = 'jkuery';
        qtype = 'report';
        break;
      case 6:
        source = 'jkuery';
        qtype = 'runrule';
        break;
      case 5:
      default: // jkuery direct;
        source = 'jkuery';
        qtype = qtype || 'lookup' ;
        break;
      } // end switch;

      return function(a,b,e,f,g){
        // if no service name is given then return list of cached services
        if(a == undefined){
          return fn.listJSON();
        }

        // if given a hash as the name then return the cached service ;
        if( !!LastJSON[a] ){ 
          return LastJSON[a];
        } else if( !!LastJSON[a[0]] ){
          return LastJSON[a[0]];
        }
        
        var name,parms,doRun,method,
            i = 0,
            hash,
            url,
            patt,
            emethod = function(m){
	      switch(m){
	      case 'GET':
	      case 'PUT':
	      case 'POST':
	      case 'OPTIONS':
              case 'DELETE':
	      case 'HEAD':
	        method = m;
                break;
              case 'CREATE':
                method = 'POST';
                break;
              case 'READ':
                method = 'GET';
                break;
              case 'UPDATE':
                method = 'PUT';
                break;
              case 'DELETE':
                method = 'DELETE';
                break;
              default:
                method = method || 'GET';
                break;
              }
            }; // end emethod ;
        // end vars;

        /* examples: 
         * when method and execution flag are missing then default is "GET" for method
         * and false for immediate execution;
         * jKuery('GetUser',['John Doe']);
         * jKuery('GetUserByFirstLast',['John','Doe'],true);
         * jKuery(59,['13345']);  // rule 
         * jKuery(100,['Bob-XP'],true); // run report #100 against variable Bob-XP and process it now
         * jKuery('myjkueryaliasforrule',[12345]);

         * execution flag and request method can be in any order:
         * jKuery('User',['John Doe'],'DELETE');
         * jKuery('User',['John Doe'],'GET',true);
         * jKuery('User',['John Doe'],true,'PUT');
         */

        patt = /^.*[^\/]\/+[^\/].*$/;
        if ( patt.test(a) ) 
        {	// it's an url ; 
	  patt = /^((http.?:)?\/\/[^\/]+|..)\/(jkuery|rule|runrule|report)\/([^\/]+)(?:\/|((?:\/[^\/?]+)+))(?:[?](.*))?$/;
	  url = a.match(patt);
	  source = url[2]; // e.g. "rule" ; 
	  name = url[3];
	  parms = url[4].split('/').slice(1); // parms array ; 
	  qtype = url[5].match(/query_type=[^=]+/); // query string ; 
	  //doRun = parms || true;  // meaning? ;
          // method can be either the 2nd or 3rd argument ;
          emethod(b);
          emethod(e);
          //doRun will be the 2nd or 3rd argument ;
          if(method == b){
            doRun = !!e;
          } else {
            doRun = !!b;
          }
          // no 4th nor 5th argument used in this case ; 
        } else {
          name = a;
          switch(arguments.length){
          case 0:
            // throw exception;
            throw new Error('not enough arguments');
            break;
	  case 1:
          case 2:  // 2nd arg is run flag or parms or method ;
	  case 3:
	  case 4:
	  default:
            for(i = 1; i < arguments.length; i++){
	      if(i == 4){
	        break;
	      }
	      switch(typeof arguments[i]){
	      case 'string': // method;
	        emethod(arguments[i]);
	        break;
	      case 'boolean': // runflag;
	        doRun = arguments[i];
	        break;
	      case 'object': // parms
	        parms = arguments[i];
	        break;
	      default:
	        //throw exception ;
	        throw new Error('wrong datatype in arguments');
	        break;
	      } // end switch args;
            } // end for ;
            // defaults for those that did not get set
	    method = method || 'GET';
	    parms = parms || [];
            doRun = doRun == undefined ? false : !!doRun;
	    //doRun will set itself a default
	    break;
          } // end switch
        } // end if patt ; 
        hash = fn.hash(name, parms, source, qtype, method);

        if(LastJSON[hash]){
          if(doRun)
            LastJSON[hash].setRun(doRun).runAjax();
          return LastJSON[hash];
        }
        LastJSON[hash] = {};
        LastJSON[hash] = new fn.JSON(name, parms, source, qtype, doRun, method); 
	return LastJSON[hash];
      }; // end return anon ;
    }  // end fn.getJSONSkeleton ;
  }; // end fn ; 

  jKuery = fn.getJSONSkeleton(5);
  window.jKuery = jKuery;
  jKuery.fn = jKuery.prototype = {
    version : version,
    constructor : jKuery
  };  // end jKuery.fn ;

  jKuery.fn.init = fn.getJSONSkeleton(5); 
  
  m = 
    { // basic set methods ;
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
	var $e = $(e); // make sure jQuery attached to it ; 
	$e.html(this.getData());
	return this;
      }
    }
  ; // end m;

  fn.setget = function(action,oVar) 
  {  // this is used as a setter for the basic variables in jKuery object ; 
    var i,
	method;
    if(typeof oVar == "string"){
      method = action + oVar.slice(0,1).toUpperCase() + oVar.slice(1);
      if(m[method]){ // call setX method ; 
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
  }; // end setget ; 

  fn.set = function(oVar){ // setter stub ; 
    return fn.setget.call(this,'set',oVar);
  };
  fn.get = function(oVar){ // getter stub ; 
    return fn.setget.call(this,'get',oVar);
  };

  fn.JSON = function(name,parms,source,qtype,run,method)
  {
    //TODO add a timer for JSON so that it can update itself on an interval. ; 
    // LastJSON[hash] is a reference to each instance ; 
    var state='new',
	data = {},
	hash,
	timer,
	interval,
	ajaxSettings = {},
	callback = [function(){}];
    source = source || 'jkuery';
    run = !!run;
    method = method || 'GET'; // CREATE ; 
    //TODO: basic test to see if K1 services are accessible otherwise give error; 
    //TODO: allow this to be called with an object of settings instead ; 
    qtype = qtype || 'sqlp';
    hash = fn.hash(name,parms,source,qtype,method);

    if(!LastJSON || !LastJSON[hash]) {
      $.error("You must instantiate this via a jKuery call");
      return false;
    }

    fn.set.call(this,['format','host','timeout']);
    // no "set" functions for readonly variable: name, parms, source, qtype, method ; 
    this.getParms = function(){
      return parms;
    };
    this.getQtype = function(){
      return qtype;
    };
    this.getMethod = function(){
      return method;
    };
    this.getSource = function(){
      return source;
    };
    this.getState = function(){
      return state;
    };
    this.getData = function()
    {
      return data;//jKuery.LastJSON[hash].getData() || data || {};
      /* TODO: somehow make the function attached to a deferred
       * so that it will wait for results of the setData()
       */
    };

    this.getName = function(){
      return name;
    };

    this.setState = function(s){ 
      state = s; 
      return this;
    };
    this.setState(undefined);

    this.setRun = function(bool){
      run = !!bool;
      return this;
    };
    this.setRun(run);
    
    this.runAjax = function(callback){
      // returns the ajax & promise ; 
      this.setAjax(callback);
      return $.ajax(ajaxSettings);
    };
    
    this.setData = function(callback)
    {
      // similar to runAjax except returns the jKuery object for chaining;
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
      t = (t > 1000 || t == 0) ? t : undefined;   
      /* min 1 second; use 0 to clear only;
       // an undefined time will yeield a 15 min timer
       // any new value between 0 and 1000 will keep the exising timer
       // 0 to end the timer
       // > 1000 to set it again
       */ 
      interval = t !=undefined ? t : ( interval || (15*60*1000)); //15 mins;
      setTimer.call(this,callback);
      return this;
    };

    this.setAjax =  function(callback) 
    {  //  a helper function to run the ajax call that will get data from kbox into the object ; 
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
	  type : this.getMethod(),
	  timeout : this.timeout,
	  beforeSend: function(){ this.setState('refreshing');},
          complete : callbackArr,
	  success : [function(d)
	             {
		       data = d;
	             }],
	  error :[ function(a,b,c)
	           {
		     data = {};
		     // set responseJSON even in an error condition for convenience ; 
		     $.extend(data,jQuery.parseJSON(a.responseText) ); 
	           }]
	}
      ); // end extend;
      
      // TODO: move this to a callback adder function;
      if(callback !== undefined && callback instanceof Array){
	ajaxSettings.complete = ajaxSettings.complete.concat(callback);
      } else if (typeof callback == "function"){
	ajaxSettings.complete.push(callback);
      }
      return ajaxSettings;
    }; // end setAjax;

    if(run)
      this.runAjax(); // optionally make the call for the data ; 

    return $.extend([hash],this);
  }; // end fn.JSON constructor for jKuery ;
  
  $.extend(  // object merge ; 
    true, //deep copy ; 
    fn.JSON.prototype, //target object ; 
    m, // specific closure methods ; 
    {   // additional prototype functions ; 
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

      //TODO: obsolete? ; 
      analyzeConfig : function(){
	var i, reqd;
	// minimum required parameters listed here ; 
	reqd = ['Name','parms'];
	for(i = 0; i< reqd.length; i++){
	  if(this[reqd[i]] === undefined){
	    throw new Error("missing " + reqd[i]);
	  }
	}
      },

      hasData : function()
      {
	// helper to see if a JSON call function returned data or not ; 
	if (this.data.count && this.data.count > 0){
	  return true;
	} 

	return false;
      } // end HasData;
    } // end fn.JSON prototype;
  ); // end extend;

  /******************************************************/

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
      hash = hash & hash; // Convert to 32bit integer ; 
    }
    return 'H'+hash.toString();
  }; // end hash;

  fn.runRuleForP = function(n,p,f)
  {
    //    return jKuery.newJkuery(n,p,true);
    f = f == undefined ? true : f;
    return jKuery(n,p,f);
  }; // end fn.runRuleForP ; 


  jKuery.getJKVersion = function()
  {
    var VersionTest = fn.runRuleForP('jKuery Version',[''],false); // even failed requests return the version;
    VersionTest.setTimeout(1000);
    return VersionTest;
    //TODO ; 
    /*
     * alls calls return the version but there may not be any accessible services so 
     * a simple call to http://host/jkuery/0 will return the version albeit with a "failed" status code.  
     * TODO: unlike a failed ajax though this helper should always return a  Promise to help keep a dependency chain
     * probaby should use a special request in jkuery.php to facilitate this
     */
  };
    
  jKuery.getSessionValue = function(p){
    var sessionvars = [
      'org_id',
      'user_id',
      'user_email',
      'user_name',
      'role_id',
      'platform',
      'org_name'
    ];
    if( $.inArray(p, sessionvars) != -1 ){
      return fn.runRuleForP('Session Value',[':'+p]);
    } else {
      $.error("usage: getSessionValue('parmname')\n\nparmname: ("+sessionvars.join("|")+")");
    }
  };
        
  jKuery.runRuleForChange = function(jkueryRowName)
  {
    var parms = [
      jKuery.getTicketId(),
      jKuery.getLastTicketChangeId()
    ];
    return fn.runRuleForP(jkueryRowName,parms);
  }; // end jKuery.runRuleThisTicket ;

  jKuery.runRuleForTicket = function(jkueryRowName)
  {
    return fn.runRuleForP(jkueryRowName,[jKuery.getTicketId]);
  }; // end jKuery.runRuleThisTicket ;

  jKuery.runRuleForId = function(jkueryRowName,id)
  {
    return fn.runRuleForP(jkueryRowName,[id]);
  }; // end jKuery.runRuleThisId ; 

  jKuery.getPageVersion = function(){
    // this should always work but putting an if just in case ; 
      if( $('script[src*="BUILD"]').eq(0).length > 0 ) 
      return $('script[src*="BUILD"]').eq(0).attr('src').match(/BUILD=([0-9]+)/)[1];

      return 'unknown';
  }; // getKboxVersion ;

    
  jKuery.getKVersion = function()
  {
    //	var VersionTest = jKuery.newJkuery('K1000 Version',[''],false);
    var VersionTest = fn.runRuleForP('K1000 Version',[]); 
    VersionTest.setTimeout(1000);
    return VersionTest;
  }; // end jKuery.getKVersion ;

  jKuery.getLastTicketChangeId = function()
  {
    //TODO : add version diffs e.g. 6.0 ; 
    var v;
    $('#ticket_history_tbody')
      .find('input[name^="fields\\[existing_change_owners_only\\]"')
      .eq(0)
      .each( 
	function(){
	  var n = $(this).attr('name');
	  v = n.substring('fields[existing_change_owners_only]['.length,n.length-1);
	}
      );
    if( parseInt(v) > 0 ){
      return parseInt(v);
    }
    return undefined;
  }; // end jKuery.getLastTicketChange ; 

  jKuery.getQueueId = function()
  {
    var $qid = $('#ticket_form').find('input[name="fields\\[queue_id\\]"]');
    if( $qid.length > 0) {
      if( parseInt( $qid.val() ) > 0 ){
	return parseInt($qid.val());
      }
    }
    return undefined;
  }; // end jKuery.getQueueId ;

  jKuery.getTicketId = function()
  {
    var tick;
    //TODO: add version differences; 
    // this technique returns the actual ID.  e.g. 4 not 0004;
    if( $('#ticket_form').find('input[name="attr\\[ID\\]"]').length > 0 ) {
      tick = $('#ticket_form').find('input[name="attr\\[ID\\]"]').val();
      if( parseInt(tick) > 0 ){
        return parseInt(tick);
      }
    }
    $.error('Current Page is not a ticket');
  }; // end getTicketId ; 

  // detect page ;
  jKuery.getPageURL = function(){
    if( window.location.href.match(/([^/]*.php)/g)[0])
      return window.location.href.match(/([^/]*.php)/g)[0];

    return 'unknown';
  };  // getPageURL ; 

  jKuery.getLocalizedPageName = function()
  {
    if($('#pageName > h2').length > 0){
      return $('#pageName > h2').text();
    } else {
      return undefined;
    }
  }; // end getLocalizedPageName ;

  jKuery.runRuleForID = function(n)
  {
    var t = undefined, //ticket number  //TODO arg[1];
	q = jKuery.getQueueId(), // queue number
	c = undefined; //change nuber to use //TODO arg[2];
    /*
     * n is the rule to run
     * if n is an array then run all those rules
     * if n is string then that is the name of the rule to run
     * if n is integer then that is the ID of the rule to run
     * if arg[1] is missing then lookup the current ticket number
     * if arg[2] is missing then use latest change number
     * if 
     */ 
    // TODO: ; 
  }; // end runRuleForID ;

  jKuery.getLastJSON = function(){
    return LastJSON;
  }; // end getLastJSON ;
  
  $.extend(
    true, 
    jKuery, 
    { // make global ; 
      Lib :  function()
      {
	//TODO make sure that it's being implemented as a constructor only ; 
	this.sources = {
	  'aboutjKuery' : {
	    method : 'aboutjKuery',
	    source: 'jkuery/www/other/js/jquery.aboutjKuery.js',
	    element : '#aboutLink',
	    parms : {"style":{"font-style": "bold","color":"red","font-size":"1.2em"}}
	  } 
	};
      } // end jKuery.Lib constructor
/*      ,
      newJkuery : fn.getJSONSkeleton(5),
      newRule : fn.getJSONSkeleton(1),
      newReport : fn.getJSONSkeleton(2),
      newJkueryRule : fn.getJSONSkeleton(3),
      newJkueryReport : fn.getJSONSkeleton(4),
      newRunRule : fn.getJSONSkeleton(6) */
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
      } // end Init;

    } // end prototype
  );

})(window.jQuery); // end "immediate" ;
