<?
/*
 * this renders many of the /kbox/samba/jkuery/include files obsolete 
 * BUT those files should be kept around (albeit empty) for legacy reasons
 * 
 * this forces the linked script and css files to conform to a certain format
 */

function printScriptForMe($portal,$type='script'){

  $markerDir = "/kbox/samba/jkuery/www/markers";
  $cat = "/bin/cat";
  $grep = "/usr/bin/grep";
  $scriptRoot = "/jkuery/www/";
  switch($type){
    case 'css':
    $scriptPattern = "'^<link rel=\"stylesheet\" href=\"(".$scriptRoot."|http[s]?://)[ A-z0-9._/-]+[.]css\" />$'";
    break;
    case 'script':
    default:
    $scriptPattern = "'^<script type=\"text/javascript\" src=\"(".$scriptRoot."|http[s]?://)[ A-z0-9._/-]+[.]js\"></script>$'";
  }

  exec("$cat $markerDir/$portal | $grep -E $scriptPattern", $output);

  foreach($output as $o){
    print $o;
  }
} // end printScriptForMe;

// $file = basename(__FILE__,'.class.php'); // e.g. KAdminPageHeader being called in the including file ; 
$gfile = 'KGlobalPageHeader';

if(preg_match('/.*Header$/',$headerfile)){
 KBLog($headerfile.' header file included by jkuery');
 printScriptForMe($gfile,'css');
 printScriptForMe($headerfile,'css');
 printScriptForMe($gfile,'script');
 printScriptForMe($headerfile,'script');
}
?>