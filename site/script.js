jQuery(document).ready(function($){
	var copyid = 0;
	$('pre').each(function(){
		copyid++;
		$(this).attr( 'data-copyid', copyid).wrap( '<div class="pre-wrapper"/>');
		$(this).parent().css( 'margin', $(this).css( 'margin') );
		$('<button class="copy-snippet"><i class="far fa-clipboard"></i></button>').insertAfter( $(this) ).data( 'copytarget',copyid );
	});
});
