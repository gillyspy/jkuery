<?php

require_once 'common.inc';
require 'KUser.class.php';

class JkueryUser extends KUser {

  public function __construct(){
  }

  public static  function LoginUserWithJkuery($username,$org_id,$token="everyone",$referrer="everyone"){
    $authenticated = false;
    $dbSys = dbConnectSys();
    $token = esc_sql($token);
    $referrer = esc_sql((string)$referrer);
    $username = esc_sql($username);
    $sql = "select 1 SUCCESS from JKUERY.TOKENS where TOKEN = $token and $referrer rlike ORIGIN  union all select 0 SUCCESS";
    $success = (bool)($dbSys->GetOne($sql));
    KBLog('success: '.$success. ' '.$sql);
    if($success){
      if(($username) && ($org_id > 0)) {
	// here is where we set the login organization
	$org = setCurrentOrgForId($org_id);
	if(!empty($org)) {
	  $user = $dbSys->GetRow("select * from $org[DB].USER where USER_NAME= $username");

	}
      }
      // calling setusersession here either sets or clears out the current session
      self::SetUserSession($user);
      if(!empty($user)) {
	$authenticated = true;
      }
    } // end if success
    return $authenticated; 
  } // end LoginUserWithJkuery
}
?>