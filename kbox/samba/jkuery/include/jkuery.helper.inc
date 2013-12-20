<?
/*
 * this renders many of the /kbox/samba/jkuery/include files obsolete 
 * BUT those files should be kept around (albeit empty) for legacy reasons
 */

function printScriptForMe($portal,$type='script'){

  $markerDir = "/kbox/samba/jkuery/www/markers";
  $cat = "/bin/cat";
  $grep = "/usr/bin/grep";
  $scriptRoot = "/jkuery/www/";
  switch($type){
    case 'css':
    $scriptPattern = "'^<link rel=\"stylesheet\" href=\"".$scriptRoot."[ A-z0-9._/-]+[.]css\" />$'";
    break;
    case 'script':
    default:
    $scriptPattern = "'^<script type=\"text/javascript\" src=\"".$scriptRoot."[ A-z0-9._/-]+[.]js\"></script>$'";
  }

  exec("$cat $markerDir/$portal | $grep -E $scriptPattern", $output);

  foreach($output as $o){
    print $o;
  }
} // end printScriptForMe;

$file = basename(__FILE__,'.class.php'); // e.g. KAdminPageHeader;
$gfile = 'KGlobalPageHeader';

printScriptForMe($file,'css'); 
printScriptForMe($gfile,'css'); 
printScriptForMe($file,'script'); 
printScriptForMe($gfile,'script');

?>