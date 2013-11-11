<?php

require 'JkueryData.class.php';
require 'JkueryUser.class.php';
/* 
 * this service queries a custom JSON table to retreive a query or string that will generate JSON formatted result
 *
 * some example URLs to access this service are: 
 *  using prepared query 105 passing parm "Gerald" and "kace.com"
 http://k1000/common/jkuery.php?id=105&query_type=sqlp&p1=Gerald&p2=kace.com
 http://k1000/jkuery/105/Gerald/kace.com
 *
 * using select query from rule #43 in org1.  passing  ticket_change#2 as parameter for <CHANGE_ID>  Allowing the result to be auto-converted into json
 http://k1000/common/jkuery.php?rule_id=43&query_type=rule&p1=2
 *
 * using select query from rule #50 in org2. Forcing the formatted result to be provided by the rule'squery.  passing no parameter
 http://k1000/common/jkuery.php?rule_id=50&query_type=rule&p1=false&org_id=2&jautoformat=0
 *
 * using select query from whatever ticket rule is tied to JKWUERY rule#1000. passing change #10
 http://k1000/common/jkuery.php?id=1000&query_type=rule&p1=10
 http://k1000/jkuery/1000/10?query_type=rule
*/
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

$debug=true;
//$debug ? KBLog(print_r($_SESSION,true)) : false ;
//KBLog(print_r($_REQUEST,true));
//KBLog(print_r($_GET,true));

$PARAMS = array('id','org_id','query_type','rule_id','p1','p2','p3','p4','p5','p6','p7','p8','p9','p0','jautoformat','loaded','token','username');
/*
 * rule_id is deprecated.  now just use id and query_type = rule
 * is  the row in JKUERY.JSON that you want to work with
 * query_type and org_id is now sourced from the prepared statement definition
 * query_type is how you want to work with that row or perhaps where the row comes from
                        "json" means you want to get the cached json data
                        "sqlp" mean you want to use the prepared statement
                        "sql" mean you want to execute a canned statement with variables
                        "rule" means  you want to re-write the select query from an existing ticket rule as a prepared statement
                        "jautoformat" is the type of JSON output they want. manual (0 : you build the string) or auto (1 : derived from an assoc array)
 * P* are the variables for a prepared statement. these are deprecated
 * p is an array of variables parsed from the REST-style URL
 */

//put all parms for the prepared statement into variable;
//this set the $_p from the GET/POST;
setParms($PARAMS, $_GET);
setParms($PARAMS, $_POST);

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
}

$valid_session = isset($_SESSION[KB_USER_ID]) && isset($_SESSION[KB_ORG_CURRENT][DB]);
KBLog('user: '.$_SESSION[KB_USER_ID]);
$referrer = $_SERVER[HTTP_ORIGIN];
KBLog(print_r($_SESSION,true));
$org_id = $org_id===0 ? 1 : $org_id;

//KBLog(isset($_SESSION[KB_USER_ID]));
if(!$valid_session){
  // try a token auth;
    if($token){
    $valid_session = JkueryUser::LoginUserWithJkuery($username,$org_id,$token,$referrer);
    //    KBLog('Origin: '.$_SERVER[HTTP_ORIGIN] );
    //    KBLog(print_r($_SERVER,true));
  }
}

if($valid_session){
  $obj = new JkueryData($id, $query_type); // instantiate the class;
  $db = dbConnect();

  // if a rule is provided then determine if that rule is providing JSON (auto) or if we need to build the JSON;
  //determine high-level type to figure out how to build the query or JSON;
  if($obj->validID($obj->id)){
    $obj->sourceType($_p,$jautoformat);
  } else {
    $obj->fail("Invalid request ID: $obj->id");
  }
}else {
  KBLog('no session: failing');
  $obj = new JkueryData(0, 'none'); //instantiate the class;
  $obj->fail("You do not have a valid session. Please authenticate and try again");
}
// end if valid_session;
?>
