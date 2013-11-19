<?php

require 'JkueryData.class.php';
require 'JkueryUser.class.php';

session_write_close();

$_query = array();
$_nop = array();
$_p = array();

function setParms($PARAMS, $OBJ){
  foreach ($PARAMS as $param) {
    global $$param;
    global $_query;
    global $_nop;
    global $_p;
    if(isset($OBJ[$param])) {
      $$param = (isset($OBJ[$param]) ? $OBJ[$param] : null);
      $_query[$param] = (isset($OBJ[$param]) ? $OBJ[$param] : null);
      //  KBLog('parsing parameters...');
      //  KBLog(substr($param,1));
      //        KBLog($OBJ[$param]);

      // generate param list for prepared statement ; 
      if("p" == substr($param, 0, 1) && (int)substr($param,1)>0){ 
	array_push( $_nop,esc_sql($OBJ[$param]));
	// do not sql_escape prepared variables ;
	array_push( $_p, $OBJ[$param]); 
      }
    } else { 
      KBLog("not set $param : ".$OBJ[$param]);
    }
  }
}
// end setParms;

$debug=false; //debug ; 
//$debug ? KBLog(print_r($_SESSION,true)) : false ;
//KBLog(print_r($_REQUEST,true));
//KBLog(print_r($_GET,true));

$PARAMS = array('id','org_id','query_type','rule_id','p1','p2','p3','p4','p5','p6','p7','p8','p9','p0','jautoformat','loaded','token','username','debug');
/*
 * rule_id is deprecated.  now just use id and query_type = rule
 * is  the row in JKUERY.JSON that you want to work with
 * query_type and org_id is now sourced from the prepared statement definition
 * query_type is how you want to work with that row or perhaps where the row comes from
                        "json" means you want to get the cached json data
                        "sqlp" mean you want to use the prepared statement
                        "sql" mean you want to execute a canned statement with variables
		        "rule" means  you want to re-write the select query from an existing ticket rule as a prepared statement
			"report" means you wan to run the statement stored in a report.  Note: this might be a prepared statement! 
			while that would fail in reporting it is still allowed to be created
                        "jautoformat" is the type of JSON output they want. manual (0 : you build the string) or auto (1 : derived from an assoc array)
			"debug" 1 means that you will get extra debug info returned. 0 is off (default)
 * P* are the variables for a prepared statement. these are deprecated
 * p is an array of variables parsed from the REST-style URL
 */

//put all parms for the prepared statement into variable;
//this set the $_p from the GET/POST;
setParms($PARAMS, $_GET);
setParms($PARAMS, $_POST);

$debug = ($debug =="true" || $debug == "1" || $debug == "on" ) ? true : false;

//this sets the $_p from the URL so it could overwrite $_p from above but apps should not use both techniques
if(isset($_GET['p']) && (string)$_GET['p'] !=''){
  $_p = explode( "/", $_GET['p']);
}
//KBLog(print_r($_p,true));

$id = (int)$id;
// $rule_id = (int)$rule_id;
$org_id=(int)$org_id;
$jautoformat = isset($jautoformat) ? (int)$jautoformat : 1; // default is 1:auto ;

//CHECK LOGIN / AUTHENTICATE;
if(isset($_SESSION[KB_ORG])){
  $org = setCurrentOrgForName($_SESSION[KB_ORG]);
  $org_id = $org[ID];
} else {
  $org = setCurrentOrgForID(1);
  $org_id = 1;
}

$valid_session = isset($_SESSION[KB_USER_ID]) && isset($_SESSION[KB_ORG_CURRENT][DB]);
$referrer = $_SERVER[HTTP_ORIGIN];

$needToken  = false;
if(!$valid_session){
  // try a token auth;
    if($token){
      $valid_session = JkueryUser::LoginUserWithJkuery($token,$referrer);
      $org = setCurrentOrgForName($_SESSION[KB_ORG]);
      $org_id = $org[ID];
      $needToken = true;
  }
}
KBLog('************************');
KBLog(print_r($_SESSION,true) );

KBlog("debug: ".$debug);

if($valid_session){
  // instantiate the object; 
  $obj = new JkueryData($id,$org_id,$query_type,$debug); // instantiate the class;

  // token user allowed to see this object? ; 
  if($obj->userlabelAllowedJSON($_SESSION[KB_USER_ID]) || !$needToken){
    
    // does the definition exist? ;
    if($obj->validID()){
      $obj->sourceType($_p,$jautoformat);
      //    exit();
    } else { // 404;
      header('HTTP/1.0 404 Not Found');
      //    include("404.php");
      $obj->fail("Not Found");
    }

  } else { // 403;
    header('HTTP/1.0 403 Forbidden');
    $obj->fail("Forbidden");
  }

} else {   //  401;
  header('HTTP/1.0 401 Unauthorized');
  include("401.php");
}

exit();

?>
