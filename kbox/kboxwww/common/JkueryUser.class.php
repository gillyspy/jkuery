<?php

require_once 'common.inc';
require 'KUser.class.php';

class JkueryUser extends KUser {

  public function __construct(){
  }

  public static  function LoginUserWithJkuery($token="everyone",$referrer="everyone"){
    $authenticated = false;
    $dbSys = dbConnectSys();
    $token = esc_sql($token);
    $referrer = esc_sql((string)$referrer);
    $sql = <<<EOT
	select 1 SUCCESS, JT.ORG_ID, JT.USER_ID
            from
	    JKUERY.TOKENS
	    join
	    JKUERY.JSON_TOKENS_JT JT ON JT.TOKENS_ID = TOKENS.ID
	    where
	    USER_ID > 0 
	    and TOKEN = $token
	    and $referrer rlike ORIGIN
	    union all select 0 SUCCESS, 1 ORG_ID, 0 USER_ID
EOT;

    $res = $dbSys->GetRow($sql);
    $success = (bool)$res['SUCCESS'];
    $uid = (int)$res['USER_ID'];
    $org_id = (int)$res['ORG_ID'];
    if($success){
      if(($uid > 0 ) && ($org_id > 0)) {
	// here is where we set the login organization ;
	$org = setCurrentOrgForId($org_id);
	if(!empty($org) ) {
	  $user = $dbSys->GetRow("select * from $org[DB].USER where ID = $uid");
	}
      }
      // calling setusersession here either sets or clears out the current session ; 
      self::SetUserSession($user);
      if(!empty($user)) {
	$authenticated = true;
      }
    } // end if success ;
    return $authenticated; 
   } // end LoginUserWithJkuery ;

}
?>
