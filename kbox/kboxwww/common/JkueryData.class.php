<?php

require_once 'DBUtils.inc';
require_once 'common.inc';
require_once 'JSON.php';

class JkueryData{

  //variables ;
  private $message;
  private $status;
  private $json;
  private $id;
  private $query_type;
  private $version;
  private $org;
  private $purpose;
  private $format;
  private $p; //parms; 
  private $debug;
  private $statusCode;
  private $header;
  private $httpMsg;

  public function __construct($id,$org_id,$query_type,$debug=false){
    $this->query_type = $query_type;
    $this->version = $this->getVersion(); 
    $this->org = (int)$org_id; //TODO get ORG from id for now; 
    $this->message = "";
    $this->format = 1;
    $this->purpose = "";
    $this->status = "success";
    $this->json = ""; //TODO?? make this call a function to set it to an empty JSON object {} ;
    $this->debug = array('status' => $debug);
    $this->Log("constructed");

    if( $id != (string)(int)$id ){
      // then force a string;
      // lookup the integer value from the table ;
      $this->id = $this->getIDforName($id);
    } else {
      $this->id = (int)$id;
    }

    $this->setHeader(200,'Success'); // default header

    if(!$this->validID()){
      $this->Log("invalid ID");
      $this->message = "invalid ID";
      $this->status = "fail";
    }

    if($debug){
      $this->Log($this->message);
      $this->Log($this->id);
      $this->Log($this->query_type);
      $this->Log($this->version);
      $this->Log($this->org);
      $this->Log($this->format);
      $this->Log($this->purpose);
      $this->Log($this->status);
      $this->Log($this->json);
    }

  } // end construct ; 

  private function getIDforName($s)
  {
    try{
      $db = dbConnect();
      $s = esc_sql(urldecode($s));  //TODO: test this ;
      $this->Log($s);
      return $db->GetOne("select ID from JKUERY.JSON where NAME = $s union all select 0 ID");
    } catch(Exception $e){
      $this->message = "Not logged in to any ORG". $e->GetMessage();
      $this->Log("error: $e->GetMessage()");
      return 0;
    }
  }

  private function setDebugSQL($sql){
    if($this->debug['status']){
      $this->debug['query'] = $sql;
    } else {
      $this->debug['query'] = '';
    }
  }

  private function setDebugParms($p){
    if($this->debug['status']){
      $this->debug['parms'] = $p;
    } else {
      $this->debug['parms'] = array();
    }
  }

  private function setDebugData(){
    if($this->debug['status']){
      //      $this->debug['query'] = "";
      //      $this->debug['parms'] = array();
      $this->debug['type'] = $this->query_type;
      $this->debug['id'] = $this->id;
      $this->debug['statuscode']= $this->statusCode;
      $this->debug['http message']=$this->httpMsg;
    }
  } // end setDebugData ;

  private function Log($msg){
    if($this->debug['status']){
      KBLog($msg);
    }
  } 

  public function validID(){
    if($this->query_type == "rule"){
      $table = "HD_TICKET_RULE";
    } elseif($this->query_type == "report") {
      $table = "SMARTY_REPORT";
    } else {
      $table = "JKUERY.JSON";
    }
    $sql = "select 1 ID from $table  where ID = $this->id UNION all select 0 ID";
    try{
      $db = dbConnect();
      return (bool)$db->GetOne($sql);
    } catch (Exception $e) {
      $db = dbConnectSys();
      if(preg_match('/^(rule|report)$/',$this->query_type) == 1 ){
	$this->message = "Not logged in to any ORG". $e->GetMessage();
	return false;
      } else {
	$db = dbConnectSys();
	return (bool)$db->GetOne($sql);
      }
    }
  }

  public function isUserAllowedJSON($userid){
    /* both a token and a user session end up getting mapped (via a user id) to a label or a role */

    /* for a rule or report we need an entry in the JKUERY.JSON table to match to the TOKEN 
     * so check type and see if a match can be found
     */ 
    
    $dbSys = dbConnectSys();
    switch($this->query_type){
    case 'rule':
      $sql = <<<EOT
	select 1
	from JKUERY.JSON J
	join JKUERY.JSON_LABEL_JT JL on JL.JSON_ID = J.ID
	join ORG$this->org.USER_LABEL_JT UL on UL.LABEL_ID = JL.LABEL_ID 
	join ORG$this->org.HD_TICKET_RULE R on R.ID = J.HD_TICKET_RULE_ID
	where 
	$this->id = R.ID
	and UL.USER_ID = $userid
	and JL.ORG_ID = $this->org
	union all
	select 1 
	from JKUERY.JSON J 
	join JKUERY.JSON_ROLE_JT JR on JR.JSON_ID = J.ID
	join ORG$this->org.USER U on U.ROLE_ID = JR.ROLE_ID 
	join ORG$this->org.HD_TICKET_RULE R on R.ID = J.HD_TICKET_RULE_ID
	where 
	$this->id = R.ID
	and U.ID = $userid
	and JR.ORG_ID = $this->org
	union all select 0
EOT;
      break;
    case 'report':
      $sql = <<<EOT
	select 1 
	from JKUERY.JSON J 
	join JKUERY.JSON_LABEL_JT JL on JL.JSON_ID = J.ID
	join ORG$this->org.USER_LABEL_JT UL on UL.LABEL_ID = JL.LABEL_ID 
	join ORG$this->org.SMARTY_REPORT R on R.ID = J.HD_TICKET_RULE_ID 
	where 
	$this->id = R.ID
	and UL.USER_ID = $userid
	and JL.ORG_ID = $this->org	
	union all
	select 1 
	from JKUERY.JSON J 
	join JKUERY.JSON_ROLE_JT JR on JR.JSON_ID = J.ID
	join ORG$this->org.USER U on U.ROLE_ID = JR.ROLE_ID 
	join ORG$this->org.SMARTY_REPORT R on R.ID = J.HD_TICKET_RULE_ID
	where 
	$this->id = R.ID
	and U.ID = $userid
	and JR.ORG_ID = $this->org
	union all select 0
EOT;
      break;
    case 'sqlp':
    default:
      $sql = <<<EOT
	select 1 
	from JKUERY.JSON_LABEL_JT JL
        join ORG$this->org.LABEL L on JL.LABEL_ID = L.ID and JL.ORG_ID = $this->org
	join ORG$this->org.USER_LABEL_JT UL on UL.LABEL_ID = L.ID
	join ORG$this->org.USER U on U.ID = UL.USER_ID 
	where 
	JL.JSON_ID = $this->id 
	and U.ID = $userid
	and JL.ORG_ID = $this->org
	union all
	select 1 
	from JKUERY.JSON J 
	join JKUERY.JSON_ROLE_JT JR on JR.JSON_ID = J.ID
	join ORG$this->org.USER U on U.ROLE_ID = JR.ROLE_ID 
	where 
	J.ID = $this->id 
	and U.ID = $userid
	and JR.ORG_ID = $this->org
	union all select 0
EOT;
      break;
    }
    return (bool)($dbSys->GetOne($sql));
} // end isUserAllowedJSON ; 

  public function succeed($sc=200, $msg=false){
    $this->Log("succeeding");
    $this->status  = $msg ? $msg : "success";
    $this->setHeader($sc,'1.1',$this->status);
    $this->printJSON();
  } // end succeed;
  
  public function fail($sc=400,$msg=false){
    $this->Log("failing");
    $this->status = "fail";
    $this->format = 0;
    $this->message =  !$this->message ? $msg : $this->message; //You do not have a valid session. Please authenticate and try again ;

    $this->json = "{}";
    $this->setHeader($sc,'1.0', $this->message);
    $this->printJSON();
  } // end fail; 

  public function validatedSqlObj($obj, $objtype='field'){
    // if you are passing in a query string then we need to validate it since it wasn't prepared;
    // TODO: compare it against a list of objects that they are allowed to use;
    if($objtype == 'value'){
      return esc_sql($obj);  // TODO: look at using mysqli OO method for this;
    } else if (strpos($obj, ';') === false){
      
      return $obj;
    } else {
      return str_replace(';','',$obj);
      //return '';
    }
  } 
  // end validatedSQLObj;

  public function getJSONBuilder($id,$db,$type="SQLstr",$where=false){
    if(!$where){
      $where = " WHERE ID = $id";
    }
    $str  = $db->GetOne("select $type from JKUERY.JSON $where  UNION ALL select 'fail' $type" );
    return $str;
  } 
  // end getJSONBuilder;
       
  public function getJkueryStmt(){
    $id = esc_sql($this->id);
    $sql = "select ORG, SQLstr, PURPOSE, QUERY_TYPE from JKUERY.JSON where ID = $id";
    $db = dbConnect();
    $p_sql = $db->GetRow($sql);
    $this->purpose = $p_sql['PURPOSE'];
    $this->org = $p_sql['ORG'];
    $this->getStmtFromType( $p_sql['SQLstr'], $p_sql['QUERY_TYPE'] );
    return true;
  }       // end getJkueryStmt;

  public function validateJSON($json){
    if( json_decode($json)  === null) {
      // $ob is null because the json cannot be decoded ; 
      $this->message = "the static JSON could not be decoded. Make sure it is well-formed";
      return false;
    }
    return true;
  }

  public function getStmtFromType($sql,$type){
    $db = dbConnect();
    $this->setDebugSQL($sql);
    $this->setDebugParms($this->p);
    $this->query_type = $type;
    //TODO  debug['p'] ?     
    switch($type){
    case 'json': // use when you want straight well-formed JSON from the JKUERY.SQLstr;
      // $sql is actually a JSON string here;
      $this->format = 0;
      if($this->validateJSON($sql) ){
	$this->status  =  "success";
	$this->json = $sql;
	$this->succeed(200,'success');
      } else {
	$this->status = "error";
	$this->fail(400,'bad request');
      }
      break;
    case 'sqlpi': // similar to sqlp except when updating / inserting data;
      $stmt = $db->Prepare($sql);
      $this->format = 2; // special format here;
      if( $this->getData( $stmt, $this->p ) ) {
	$this->format = 1;
	$this->succeed(200,'success');
      }  else {
	$this->status = "fail";
	$this->fail(400,'bad request');
      }
	
    break;
  case 'sqlpJSON': // use for a special case to build where clause stored in a different ID ; 
    // iterate over the json items in the where variable;
    // example where ;
    /*
     * where: {"whereclause0":{"conjunction":"","field":"HD_TICKET.CREATED","operator":" > date_sub(now(), interval 24 hour) "}} 
     */
    $where = isset($_POST['where']) ? $_POST['where'] : '{}';
    $this->Log('where: ' .$where);
    $wherejson = json_decode($where, true);
    $extrawhere ='';
    foreach ($wherejson as $_wherejson) {
      if( $_wherejson['refreshlist']=='yes' ){ // if refresh;
      $extrawhere =  ' 1=1 ) '
        .' '. $this->validatedSqlObj($_wherejson['conjunction'])  // ) or ( ;
	  .' '. $this->validatedSqlObj($_wherejson['field'])  // HD_TICKET ;
	    .'  '. $this->validatedSqlObj($_wherejson['operator'])  // in (blah) ;
	      .')) and ((('. $extrawhere ;
	      break; 
      }  // end refreshlist   ;
      else { // else just plain  ;
      $extrawhere .= " ".$this->validatedSqlObj( $_wherejson['conjunction'] ) ;
      if ( (int)$_wherejson['subq'] > 0 ){ // if subquery in play ;
        // look up the subquery ;
	  $subval = isset($_wherejson['value']) ? ",".$this->validatedSqlObj($this->validatedSqlObj( $_wherejson['value'] ,'value'), 'value') : '';
	    $sub_sql = $db->GetOne("select replace(SQLstr,':JSON',"
	     ."concat( ". $this->validatedSqlObj( $_wherejson['subfield'],'value')
	      .",' ',". $this->validatedSqlObj($_wherejson['operator'],'value')." ".$subval." ) )"
	       ." from JKUERY.JSON"
	        ." where ID= ".$_wherejson['subq']); // e.g. in (select COLX from TABLE where (:JSON) ) ; 
		  $extrawhere .= " ". $this->validatedSqlObj( $_wherejson['field'] ) ." ". $sub_sql ;
		  } else {
		    $extrawhere .=" ".$this->validatedSqlObj( $_wherejson['field'] )
		        ." ". $this->validatedSqlObj( $_wherejson['operator'] );
			  if(isset($_wherejson['value'])){
			      $extrawhere .= " ".$this->validatedSqlObj($_wherejson['value'],'value' );
			        }
				} // end if subquery ;
      } // end else just plain ;
    } // end where clause for loop ;

    $where = " where ID= $this->id";
    $p_sql = $db->GetOne("select REPLACE(SQLstr,':JSON',".esc_sql($extrawhere).") from JKUERY.JSON ". $where);
    $stmt = $db->Prepare($p_sql);
    if( $this->getData($stmt , $this->p) ){
      $this->status = "success";
      $this->succeed(200,'success');
    } else {
      $this->status = "fail";
      $this->fail(400,'bad request');
    }
break;
    case 'sql': // similar to sqlp except using replacements ;
      $i = 1;
      foreach($_p as $__p){
      $replacesql = " REPLACE($sql,':p$i',$__p)";
      $i++;
      }
      $stmt = $db->GetOne("select $replacesql");
      if( $this->getData( $stmt, false ) ) {
      $this->succeed(200,'success');
      } else {
	$this->status = "fail";
	$this->fail(400,'bad request');
      }
      break;
    case 'report': // similar to rule but from SMARTY_REPORT table;
      $stmt = $this->getReportStmt(false);
      if( $this->getData($stmt) ) { 
	$this->succeed(200,'success');
      } else {
	$this->status = "fail";
	$this->fail(400,'bad request');
      }
      break;
    case 'rule': // use this when you want the rule referenced from JKUERY table ; 
      // for example if you want a rule from another ORG ; 
      $stmt = $this->getRuleStmt(false);
      if( $this->getData($stmt, $this->p) ){
      $this->succeed(200,'success');
      } else {
	$this->status = "fail";
	$this->fail(400,'bad request');
      }
      break; 
    case 'sqlp': // most common case
      $stmt = $db->Prepare($sql);
      if( $this->getData( $stmt, $this->p) ){
	$this->Log("success");
	$this->status = "success";
	$this->succeed(200,'success');
      } else {
	$this->status = "fail";
	$this->fail(400,'bad request');
      }
      break;
    case 'loaded': //TODO;
    default: 
      $this->status = "fail";
      $this->fail(400,"invalid query type");
      break;
    } // end switch ;
  } // end getStmtFromType;

  public function getVersion(){
    try{
      $db = dbConnectSys();
      $ver = $db->GetOne("select VALUE from KBSYS.SETTINGS where NAME = 'JKUERY_VERSION' UNION ALL select '1.2' VALUE");
    }catch(Exception $e){
      $ver = false;
    }
    $this->Log('ver: '.$ver);
    return $ver;
  }
  // end getVersion;

  public function getRuleStmt($nativeID){
    $db = dbConnect();
    if($this->query_type == "rule" && $nativeID){
      $where = " R.ID = ".$this->id;
    } else {
      $where = " J.ID = ".$this->id;
    }
    $_p_sql = <<<EOT
	select 
	replace(replace(R.SELECT_QUERY, '<CHANGE_ID>','?'),'<TICKET_ID>',' and HD_TICKET.ID = ?') Q ,
	LEFT(NOTES,255) PURPOSE
      	from HD_TICKET_RULE R 
      	left join /*ORG implied */ JKUERY.JSON J on J.HD_TICKET_RULE_ID=R.ID 
    	WHERE $where
EOT;

    $p_sql = $db-> GetRow($_p_sql);
    $this->setDebugSQL($p_sql['Q']);
    $this->purpose = $p_sql['PURPOSE'];
    return $stmt = $db->Prepare($p_sql['Q']);
  } // end getRuleStmt;
 

  public function getReportStmt($nativeID){
    $db = dbConnect();
    if($this->query_type == "report" && $nativeID){
      $where = " R.ID = ".$this->id;
    } else {
      $where = " J.ID = ".$this->id;
    }

    $limit = '';
    $upper = (int)$this->p[1];
    $lower = (int)$this->p[0];
    if($lower >0){
      $limit = " LIMIT $lower";
      if($upper > 0){
	$limit = $limit .", $upper";
      }
    }

    $_p_sql = <<<EOT
	select QUERY Q, left(DESCRIPTION,255) PURPOSE 
      	from SMARTY_REPORT R 
      	left join /*ORG implied */ JKUERY.JSON J on J.HD_TICKET_RULE_ID = R.ID 
      	WHERE $where
EOT;

    $p_sql = $db-> GetRow($_p_sql);
    $this->setDebugSQL($p_sql['Q']);
    $this->purpose = $p_sql['PURPOSE'];

    $sql = $db->Prepare($p_sql['Q']) . $limit;
    return $sql;
  } // end getReportStmt; 

  function changeORG(){
    return true; 
  } // end changeORG;

  private function formatJSON(){
    $this->Log("formatting...");
    $this->setDebugData();
    /* need the following set and then printJSON() can be called instead
     * version 
     * jdata
     * purpose
     * message
     * format
     * status
     */
    $r = array();
    $r['message'] = isset($this->message)? $this->message : '';
    $r['version'] = isset($this->version) ? $this->version : '';
    $r['purpose'] = isset($this->purpose) ? $this->purpose : '';
    $r['status'] = isset($this->status) ? $this->status : 'error';
    $r['count'] = $this->format == 0 ? count(json_decode($this->json,true)) : count($this->json);
    if($this->debug['status']){
      $r['debug'] = $this->debug;
    }
    $r['json'] = $this->format == 0 ? json_decode($this->json,true) : $this->json;
    return json_encode($r,  JSON_FORCE_OBJECT);
  } // end formatJSON;

  public function printJSON(){
    $this->Log("printing....");
    header($this->header);
    header("Cache-Control: no-cache, must-revalidate");
    header("Expires: 0");
    header("Content-type: text/javascript");
    print( $this->formatJSON() );
  } // end printJSON; 

  public function sourceType($p,$jautoformat){
    $this->format = $jautoformat;
    $p = $this->mapSessionVar($p);
    $this->setDebugParms($p);
    $this->p = $p;
    switch($this->query_type){
    case 'rule':
      /*
       * use this when your source is a ticket rule -- you might not even have anything stored in JKUERY table ;
       *  this does not cover the scenario when you want to reference  rule from JKUERY table;
       */
      $stmt = $this->getRuleStmt(true);
      if($this->getData($stmt,$p)){
      $this->succeed(200,'success');
      } else {
	$this->status = "fail";
	$this->fail(400,'bad request');
      }

      break;
    case 'report':
      /*
       * use this when your source is a smarty report  -- you might not even have anything stored in JKUERY table ;
       *  this does not cover the scenario when you want to reference  rule from JKUERY table;
       */
      $stmt = $this->getReportStmt(true);
      if($this->getData($stmt)){
      $this->succeed(200,'success');
      } else {
	$this->status = "fail";
	$this->fail(400,'bad request');
      }
      break;
    case 'lookup':
    default:
      // use this when you want to lookup the prepared object via JKUERY tables;
      $stmt = $this->getJkueryStmt();
      break;
    } // end switch ; 
  } // end sourceType;

private function setHeader($statusCode, $protocolVer='1.0',$msg=false)
{
  $protos = array('1.1','1.0');
  $protocolVer = in_array( $protocolVer, $protos) ? $protocolVer : '1.0';

  $statusCode = (int)$statusCode;
  $codes = array(400,401,403,404,500,200);
  $statusCode = in_array( $statusCode, $codes) ? $statusCode : 400;

  $this->statusCode = $statusCode;
  $msgs = array(
		400 => 'Bad Request',
		401 => 'Unauthorized',
		403 => 'Forbidden',
		404 => 'Not Found',
		500 => 'Internal Error',
		200 => 'Success'
		);

  $this->message = $msg ? $msg : $msgs[$statusCode];
  $this->httpMsg = in_array( $statusCode, $codes) ? $msgs[$statusCode] : $msgs[500];
  $this->header = 'HTTP/'.$protocolVer.' '.$statusCode.' '.$this->httpMsg;
  return $this->header;
} // end setHeader;

private function mapSessionVar($names)
{
  foreach($names as &$name){
    // take a variable name and return the session variable equivalent
    // e.g.  :user_id means sub in the user id for current session user
    if( substr($name, 0, 1) == ":"){
      $name = substr($name, 1);
      switch( strtoupper($name) ){
      case 'ORG_ID':
	$name = $_SESSION['KB_ORG_CURRENT']['ID'];
	break;
      case 'USER_ID': 
	$name = $_SESSION['KB_USER_ID'];
	break;
      case 'USER_EMAIL':
	$name = $_SESSION['KB_USER_EMAIL'];
	break;
      case 'USER_NAME':
	$name = $_SESSION['KB_USER'];
	break;
      case 'ROLE_ID':
	$name = $_SESSION['KB_USER_ROLE_ID'];
	break;
      case 'PLATFORM':
	$name = $_SESSION['KB_PLATFORM'];
	break;
      default:
	// if we fall through then
	$name = ':'.$name ;
      }
    } else {
      $name = $name;
    }
  }
  return $names;
}  // end mapSessionVar;

  function getData($stmt,$p=false){
    try{
      $db=dbConnect();
      switch((int)$this->format){
      case 0:
	$this->json = $p ? $db->GetOne($stmt,$p) : $db->GetOne($stmt);
	break;
      case 2:
	if(!$p){
	  throw new Exception('no parameters for update/insert.');
	}
	$db->Execute($stmt,$p);
	$this->json = $db->GetOne('select 1');
	break;
      case 1:
	$this->json = isset($p[0]) ? $db->GetAssoc($stmt,$p) : $db->GetAssoc($stmt);
	break;
      } // end switch ; 
      $this->status="success";
    } catch (Exception $e) {
      $this->Log("error : ".$e->GetMessage());
      $this->status = "error";
      $this->message = "Error: ".$e->GetMessage();
      return false;
    }
    return true;
  } // end getData;
} // end class ;
?>
