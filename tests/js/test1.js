/* jsonlint browser:true debug:true  */
/* global jQuery:true, jKuery:true, assert:true, test:true, document:true */
jQuery.noConflict();

jQuery(document).ready(
  (function($){
    var myJSON, myJSON2;

    test('jKuery object tests', function (){
      assert(!jKuery.LastJSON, "LastJSON does not exist yet");

      myJSON = jKuery.newJkuery('test',[1,1],false);

      assert(myJSON instanceof jKuery.JSON, 'can call newJkuery');
      assert(jKuery.LastJSON, "LastJSON created");

      var i,key;
      i=0;
      for(key in jKuery.LastJSON){
	assert(jKuery.LastJSON[key] == myJSON, 'cached reference created');
	i++;
	if (i > 0){
	  break;
	}
      }
      
      try{
	myJSON = undefined;
	myJSON = new jKuery.JSON('test',[1,0],'jkuery','sqlp',false);
      } catch(e){
	assert(e, "error when calling jKuery.JSON directly");
	assert(myJSON == undefined, 'cannot call constructor directly');

	myJSON = jKuery.newJkuery('test',[1,1],false);
	myJSON2 = jKuery.newJkuery('test',[1,1],false);
	assert(myJSON2 === myJSON, "new attempt to construct same object gives old reference");
	i=0;
	for(key in jKuery.LastJSON){
	  i++;
	}
	assert(i = 1, "there is 1 object in jKuery.LastJSON",i);

	myJSON = {};
	assert(myJSON !== myJSON2, "can deference one object but other stays cached");

      }
    });

  })(jQuery)
);
