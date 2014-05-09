/* Gerald Gillespie 2014 */

/* this example will prevent the typical search from occurring.  Some customers do not like the
 * performance penalty that the default search implies because it searches too many fields.
 * We find that the most common type of search is for a ticket number or a ticket title so
 * it makes sense for the common search to only use those fields.
 *
 * what this example does is "suck" the search terms out and if it is a valid ticket number
 * format then it will put that into a ticket number search.  otherwise it will only search titles
 *
 * if you wanted to expand this to search more fields you would have to additionally set the
 * FINDFIELDS[UNION_SELECTX] conjunction operator to AND / OR
 */

( function($,K) {


  $(document).ready(  function(){

    // detect comptabile version ;
    if( $.inArray(K.getPageVersion(), ['90545','90546']) < 0 ){
      return false;
    }  // if ; 

    // detect page of kbox and only invoke on helpdesk search ; 
    if( K.getPageURL() == 'ticket_list.php' ){
      console.log('in the ticket list');
      // hide the advanced search by default if we hijacked it ;
      if( $('#FINDFIELDS\\[INPUT2\\]').val() == 'hijackedsearch' ) {
        $('#advSearchButton').trigger('click');
      } 

      $('#search').on('submit', function(e){
        // suck out the search parms ;
        var searchStr = $('#search').find('input[name="SEARCH_SELECTION_TEXT"]').val().trim(),
            wfieldVal,
            expSelectVal;
        
        // disallow zero length search ;
        if( searchStr == '' ){
          alert('you must enter some text');
        } 
        
        /*  test if the search parms are a ticket number;
         * use the appropriate search field for the given data
         */
        if( /^((tick):?)?[0-9]+$/g.test( searchStr ) ){
          wfieldVal = 'HD_TICKET.ID';
          expSelectVal = 'EQUALS';
        } else {
          wfieldVal = 'HD_TICKET.TITLE';
          expSelectVal = 'CONTAINS';
        }  // if ;

        // zero out any existing advanced search fields we are not going to use;
        $('#FINDFIELDS\\[UNION_SELECT3\\]').val( '0' );
        $('#FINDFIELDS\\[UNION_SELECT4\\]').val( '0' );
        $('#FINDFIELDS\\[UNION_SELECT3\\]').trigger('change');
        $('#FINDFIELDS\\[UNION_SELECT4\\]').trigger('change');
        
        // set the advanced search fields ; 
        $('#FINDFIELDS\\[WFIELD1\\]').val( wfieldVal );
        $('#FINDFIELDS\\[EXP_SELECT1\\]').val( expSelectVal );
        $('#FINDFIELDS\\[INPUT1\\]').val( searchStr );

        // set the advanced search fields row 2 with breadcrumbs;
        $('#FINDFIELDS\\[UNION_SELECT2\\]').val( 'AND' );
        $('#FINDFIELDS\\[UNION_SELECT2\\]').trigger('change');
        $('#FINDFIELDS\\[WFIELD2\\]').val( 'HD_TICKET.TITLE' );
        $('#FINDFIELDS\\[EXP_SELECT2\\]').val( 'NO_CONTAIN' );
        $('#FINDFIELDS\\[INPUT2\\]').val( 'hijackedsearch' );

        // trigger the search ;
        //$('#advSearchForm').find('form').trigger('submit'); // this won't work on K1 ;
        $('#advSearchForm').find('form').find('input[name="aq_search"]').trigger('click');

        // prevent default search behaviour;
        e.preventDefault();
      });  // on submit ; 
    }  // if ; 
  });  // on ready ;
})(jQuery,jKuery);
