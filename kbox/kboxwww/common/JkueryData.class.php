<?php

require_once 'DBUtils.inc';
require_once 'common.inc';
require_once 'JSON.php';

class JkueryData{

  //variables ;
  public $message;
  public $status;
  public $json;
  public $id;
  public $query_type;
  public $version;
  public $org;
  public $purpose;
  public $format;
  public $p; //parms; 
  public $debug;

  public function __construct($id,$query_type){
    $this->id = $id;
    $this->query_type = $query_type;
    $this->version = $this->getVersion(); 
    $this->org = ""; //TODO get ORG from id for now; 
    $this->message = "";
    $this->format = 1;
    $this->purpose = "";
    $this->status = "success";
    $this->json = ""; //TODO make this call a function to set it to an emtpy JSON object {} ;
    $this->debug = "true";
    $this->Log("constructed");
    if(!$this->validID()){
      $this->Log("invalid ID");
    }
  } // end construct ; 

  private function Log($msg){
    if($this->debug){
      KBLog($msg);
    }
  } 

  public function validID(){
    if($this->query_type = "rule"){
      $table = "HD_TICKET_RULE";
    } else {
      $table = "JKUERY.JSON";
    }
    $sql = "select 1 ID from $table  where ID = $this->id UNION all select 0 ID";
    try{
      $db = dbConnect();
      return (bool)$db->GetOne($sql);
    } catch (Exception $e) {
      $db = dbConnectSys();
      if($this->query_type == "rule"){
	$this->message = "Not logged in to any ORG". $e->GetMessage();
	return false;
      } else {
	$db = dbConnectSys();
	return (bool)$db->GetOne($sql);
      }
    }
  }

  public function fail($msg){
    $this->Log("failing");
    $this->status = "fail";
    $this->format = 0;
    $this->message =  $msg ? $msg : $this->message; //"You do not have a valid session. Please authenticate and try again";
    $this->json = "{}";
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
    switch($type){
    case 'json': // use when you want straight well-formed JSON from the JKUERY.SQLstr;
      // $sql is actually a JSON string here;
      $this->format = 0;
      if($this->validateJSON($sql) ){
      $this->status  =  "success";
      $this->json = $sql;
      $this->printJSON();
      } else {
      $this->status = "error";
      }
      break;
    case 'sqlpi': // similar to sqlp except when updating / inserting data;
      $stmt = $db->Prepare($sql);
      $this->format = 2; // special format here;
      if( $this->getData( $stmt, $this->p ) ) {
      $this->format = 1;
      $this->printJSON();
    }
    break;
  case 'sqlpJSON': // use for a special case to build where clause stored in a different ID ; 
    // iterate over the json items in the where variable;
    // example where
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
    $this->Log($p_sql);
    $this->Log(print_r($this->p,true));
    $stmt = $db->Prepare($p_sql);
    if( $this->getData($stmt , $this->p) ){
      $this->status = "success";
      $this->printJSON();
    } else {
      $this->status = "fail";
      $this->fail(false);
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
      $this->printJSON();
      }
      break;
    case 'rule': // use this when you want the rule referenced from JKUERY table ; 
      // for example if you want a rule from another ORG ; 
      $stmt = $this->getRuleStmt($this->p);
      if( $this->getData($stmt, $this->p) ){
      $this->printJSON();
      }
      break; 
    case 'loaded':
      //TODO;
      break;
    case 'sqlp': // most common case
      $this->Log('*****************');
      $stmt = $db->Prepare($sql);
      $this->Log(print_r($stmt,true));
      if( $this->getData( $stmt, $this->p) ){
      $this->status = "success";
      $this->printJSON();
      } else {
      $this->status = "fail";
      $this->fail(false);
      }
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

  public function getRuleStmt(){
    $db = dbConnect();
    if($this->query_type == "rule"){
      $where = " R.ID = ".$this->id;
    } else {
      $where = " J.ID = ".$this->id;
    }
    $_p_sql = "select replace(replace(R.SELECT_QUERY, '<CHANGE_ID>','?'),'<TICKET_ID>',' and HD_TICKET.ID = ?') from JKUERY.JSON J ".
    " join /*ORG implied */ HD_TICKET_RULE R on J.HD_TICKET_RULE_ID=R.ID ".
    "WHERE ".$where;
    $p_sql = $db-> GetOne($_p_sql);
    return $stmt = $db->Prepare($p_sql);
  } // end getRuleStmt;

  function changeORG(){
    return true; 
  } // end changeORG;

  private function formatJSON(){
    $this->Log("formatting...");
    $this->Log($this->format);
    /* need the following set and then printJSON() can be called instead
     * version 
     * jdata
     * purpose
     * message
     * format
     * status
     */
    switch($this->format){ 
    case 0:
      $message = isset($this->message) ? ', "message" : "'.$this->message.'"' : '';
      $ver = isset($this->version) ? ', "version" : "'.$this->version.'"' : '';
      $purpose = isset($this->purpose) ? ', "purpose" : "'.$this->purpose.'"' : '';
      $r = '{ "json" : '.$this->json.', "status" : "'.$this->status.'" '.$message.$ver.$purpose.'}';
      $this->Log($r);
      $validj =json_decode($r);
      $json = json_encode($validj);
      break;
    case 1:
    default:
      $r = array('json' => $this->json);
      if(isset($this->message)){
      $r['message'] = $this->message;
      }
      if(isset($this->version)){
      $r['version'] = $this->version;
      }
      if(isset($this->purpose)){
      $r['purpose'] = $this->purpose;
      }
      $r['status'] = $this->status;
      //$_json = new Services_JSON();
      //$json = $_json->encode($r);
      $json = json_encode($r,  JSON_FORCE_OBJECT);
      break;
      //        default:;
      //         throw(new Exception("unknown jformat: $jautoformat"));
    }
    return $json;
  } // end formatJSON;

  public function printJSON(){
$this->Log("printing....");
    header("Cache-Control: no-cache, must-revalidate");
    header("Expires: 0");
    header("Content-type: text/javascript");
    print( $this->formatJSON() );
  } // end printJSON; 

  public function sourceType($p,$jautoformat){
    $this->format = $jautoformat;
    $this->p = $p;
    switch($this->query_type){
    case 'rule':
      /*
       * use this when your source is a ticket rule -- you might not even have anything stored in JKUERY table ;
       *  this does not cover the scenario when you want to reference  rule from JKUERY table;
       */
      $this->p = $p;
      $stmt = $this->getRuleStmt();
      if($this->getData($stmt,$p)){
      $this->printJSON();
      }
      break;
    case 'lookup':
    default:
      // use this when you want to lookup the prepared object via JKUERY tables;
      $stmt = $this->getJkueryStmt();
      break;
    } // end switch ; 
  } // end sourceType;

  function getData($stmt,$p=false){
    try{
      $db=dbConnect();
      $this->Log($this->format);
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
	$this->Log('is set? '.isset($p));
	$this->json = isset($p) ? $db->GetAssoc($stmt,$p) : $db->GetAssoc($stmt);
break;
      } // end switch ; 
      $this->status="success";
    } catch (Exception $e) {
      $this->status = "error";
      $this->message = "Error: ".$e->GetMessage();
      return false;
    }
    return true;
  } // end getData;
} // end class ;
?>
