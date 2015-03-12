<?php
/* this is the service that will handle the request
 * it will instantiate a jKuery request object and exit the response
 */

/*
 * requests always lookup raw JSON or prepared statements that drive the creation of JSON.  
 * note: rule_id is deprecated.  now just use id and query_type = rule
 * is  the row in JKUERY.JSON that you want to work with
 * query_type and org_id is now sourced from the prepared statement definition
 * query_type dictates how the request is going to create JSON
 ** "json" means you want to get the cached (static) json data from the table
 ** "sqlp" mean you want to use the prepared statement
 ** "sql" mean you want to execute a canned statement with variables
 ** "rule" means  you want to re-write the select query from an existing ticket rule as a prepared statement
 ** "runrule" means you want to do "rule" type but also run all the actions associated with that rule in the system (email, updates, etc)
 ** "runallrules" means you want to run the SQLstr query but then all rules that are batch-type, scehduled rules (not on ticket save rules)
 ** "report" means you wan to run the statement stored in a report.  Note: this might be a prepared statement! 
 **  while that would fail in reporting it is still allowed to be created
 ** "jautoformat" is the type of JSON output they want. manual (0 : you build the string) or auto (1 : derived from an assoc array)
 ** "debug" 1 means that you will get extra debug info returned. 0 is off (default).  this will
    also log extra data in the kbox log files
 * P* are the variables for a prepared statement. these are deprecated
 * p is an array of variables parsed from the REST-style URL
 */

require 'JkueryData.class.php';
require 'JkueryUser.class.php';

/* parse ini file for password every time */

$inifile = '/kbox/samba/jkuery/www/hidden/jkuery.ini';
if( file_exists($inifile) ) {
  $ini = parse_ini_file (  $inifile , true ) ;
  $pwd = $ini['jkuery']['password'] ;
} 
if( $pwd != '' ) {
  $db = dbConnectSys()->Execute("set password for 'jkuery'@'%' = password(". esc_sql($pwd) . ")");
}

session_write_close();

$_query = array();
$_nop = array();
$_p = array();

function setParms($PARAMS, $OBJ){
  //  KBLog('PARAMS: '.print_r($PARAMS,true));

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
      // TODO: properly loop through a parms array. but this is also needed for legacy formatted requests;
      //check if the parm is an array of values;
      if("p" == substr($param, 0, 1) && (int)substr($param,1)>0){ 
        //test if value is an array
        if( is_array( $OBJ[$param] ) ){
	  $_nop = array_merge( $_nop, $OBJ[$param] );
	  $_p = array_merge( $_p,   $OBJ[$param] );
	  //KBLog('$_p: '. print_r($_p,true));
        } else {
	  array_push( $_nop,esc_sql($OBJ[$param]));
	  // do not sql_escape prepared variables ;
	  array_push( $_p, urldecode( $OBJ[$param] ) );
        }
      }
    } else { 
      //KBLog("not set $param : ".$OBJ[$param]);
    }
  }
}
// end setParms;

// some defaults ;
$valid_session = false; 
$referrer = $_SERVER[HTTP_ORIGIN];
$needToken  = false;

function getMethod(){
  switch(strtoupper($_SERVER['REQUEST_METHOD'])){
  case 'GET':
    return $_GET;
  case 'POST':
    return $_POST;
  case 'PUT':
  case 'DELETE':
    $arr = [];
    foreach(explode('&', file_get_contents('php://input') ) as $parms){
      $parms = explode('=',$parms);
      //handle potential arrays in the values since PUT and DELETE do not do this automatically;
      $left = explode('%5B%5D' , $parms[0] )[0];
      // updating existing value;
      if( array_key_exists( $left, $arr ) ){
        // add to the array
	if( is_array( $arr[ $left ] ) ){
	  $arr[ $left][]= urldecode($parms[1]);
	} else {
	  //convert the value to an array and add it;
	  $arr[ $left ] = [ urldecode($arr[ $left ]), urldecode($parms[1]) ];
	}
      } else {
	$arr[ $left] = $parms[1];
      }
    }
    return  array_merge($_GET, $arr);
  default:
    return false;
  }
} // end getMethod; 

$PARAMS = array('id','query_type','rule_id','p1','p2','p3','p4','p5','p6','p7','p8','p9','p0','jautoformat','loaded','token','username','debug');

/* note to get more p values each p value can be an array of values. e.g. p1[]=foo&p1[]=bar */


//put all parms for the prepared statement into variable;
//this set the $_p from a GET or POST, PUT, DELETE
setParms($PARAMS, getMethod() );

if ( $_query['debug'] == "true" || $_query['debug'] == "1" || $_query['debug'] == "on" ) {
  $dbg=true;
} else {
  $dbg=false;
}

//this sets the $_p from the URL so it could overwrite $_p from above but apps should not use both techniques
if(isset($_GET['p']) && (string)$_GET['p'] !=''){
  $_p = explode( "/", $_GET['p']);
}
/*
 * because of URL re-write using GET parms take the parms given in the rewrite and re-use them
 * Again, this could overwrite parms used in the PUT/POST/DELETE but that's fine
 */
$fromGet = ['id','query_type'];
foreach ($fromGet as $get) {
  if(isset($_GET[$get]) && (string)$_GET[$get] != ''){
    global $$get;
    $$get = $_GET[$get];
  } else {
    break;
  }
} // end for each ; 
//KBLog('$_GET: '.print_r($_GET,true));

/* id can be an integer or a string.  
 * if it is a string then it will lookup the ID from the JKUERY.JSON table
 */

//$id = (int)$id; // obsolete ; 
$jautoformat = isset($jautoformat) ? (int)$jautoformat : 1; // default is 1:auto ;

if(!$valid_session){  // try a token auth first.  this will allow requests from another ORG that have a session to switch theirs;
    if($token){
      $valid_session = JkueryUser::LoginUserWithJkuery($token,$referrer);
      $org = setCurrentOrgForName($_SESSION[KB_ORG]);
      $org_id = $org[ID];
      $needToken = true;
    } else {
      // check login ;
      if(isset($_SESSION[KB_ORG])){
	$org = setCurrentOrgForName($_SESSION[KB_ORG]);
	$org_id = $org[ID];
      } else {
	$org = setCurrentOrgForID(1);
	$org_id = 1;
      }
      $valid_session = isset($_SESSION[KB_USER_ID]) && isset($_SESSION[KB_ORG_CURRENT][DB]);
    }
} // end if; 

/*
KBLog($id);
KBLog($org_id);
KBLog($query_type);
KBLog(var_export($dbg));
KBLog(print_r($_p,true));
KBLog($valid_session);
KBLog('method: '.$_SERVER['REQUEST_METHOD']);
*/
// instantiate the object; 
$obj = new JkueryData($id,$org_id,$_SERVER['REQUEST_METHOD'],$query_type,$dbg); // instantiate the class;
// KBLog('after JkueryData instantiated');
if($valid_session){

  // token user allowed to see this object? ; 
  //  if($obj->isUserAllowedJSON($_SESSION[KB_USER_ID]) || !$needToken){
    if($obj->isUserAllowedJSON($_SESSION[KB_USER_ID]) ){
    
    // does the definition exist? ;
    if($obj->validID()){
      //TODO: run the proper type of request ; 
      $obj->sourceType($_p,$jautoformat);
      //    exit();
    } else { // 404;
      $obj->fail(404,"Not Found");
    }

  } else { // 403;
    $obj->fail(403,"Forbidden");
  }

} else {   //  401;
  $obj->fail(401,"Unauthorized");
  //  include("401.php");
}
exit();

?>
