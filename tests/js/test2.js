/* jsonlint browser:true debug:true  */
/* global jQuery:true, jKuery:true, assert:true, test:true, document:true */
jQuery.noConflict();

jQuery(document).ready(
  (function($){
    var myJSON, myJSON2;

    //GROUP 1
    test('jKuery object tests', function (){
      //1
      equal(jKuery.LastJSON,undefined, "LastJSON does not exist yet");
      console.log(jKuery.LastJSON);

      //2
      //3
      myJSON = jKuery.newJkuery('test',[1,1],false);
      ok(myJSON instanceof jKuery.JSON, 'can call jKuery.newJkuery method to build jKuery objects');
      ok(jKuery.LastJSON, "LastJSON object created after the first jKuery object created ");

      //4
      var i,key;
      i=0;
      for(key in jKuery.LastJSON){
	equal(jKuery.LastJSON[key], myJSON, 'cached reference created');
	i++;
	if (i > 0){
	  break;
	}
      }
      
      //5
      //6
      try{
	myJSON = undefined;
	myJSON = new jKuery.JSON('test',[1,0],'jkuery','sqlp',false);
      } catch(e){
	ok(e, "error when calling jKuery.JSON directly");
	equal(myJSON,undefined, 'cannot call constructor directly');

        //7
        //8
        //9
        //10
	myJSON = jKuery.newJkuery('test',[1,1],false);
	myJSON2 = jKuery.newJkuery('test',[1,1],false);
	equal(myJSON2, myJSON, "new attempt to construct same object gives old reference");
	deepEqual(myJSON2,myJSON, "deeply equal");
        equal(myJSON, jKuery.newJkuery('test',[1,1],true), 'objects equal');
        deepEqual(myJSON, jKuery.newJkuery('test',[1,1],true), 'objects equal deeply');

	//11
        i=0;
	for(key in jKuery.LastJSON){
	  i++;
	}
	ok(i = 1, "there is 1 object in jKuery.LastJSON",i);

        //12
	myJSON = {};
	ok(myJSON !== myJSON2, "can de-reference one object but other stays cached");

      }
    });

    //GROUP 2
    asyncTest('test aboutjKuery demo',3, function(){
        $.getScript('../kbox/samba/jkuery/www/2.1/jquery.aboutjKuery.js',function(){
          var el = document.getElementById('aboutLink');
          var a = $(el).find(a).get();

          ok($(el).length > 0, 'about link exists');
          equal($._data( el, "events" ).click.length, 1  ,'has one jQuery click event');
          window.myvar = undefined;
          function openAboutWindow(str){
            window.myvar = true;
          }
          $(a).click();
          equal(window.myvar,undefined, 'inline handler is not called');
          console.log(jQuery._data( a ));
          start();
      });
    });

  })(jQuery)
);
