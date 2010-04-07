function CheckAll()
{
	for (var i=0;i<document.requestform.elements.length;i++)
	{
		var e = document.requestform.elements[i];
		if (e.name != 'allbox' && e.name != 'request[hold_recall]')
			e.checked = document.requestform.allbox.checked;
    }
}
function UnCheckAll()
{
        for (var i=0;i<document.requestform.elements.length;i++)
        {
                var e = document.requestform.elements[i];
                if (e.name != 'allbox' && e.name != 'request[hold_recall]')
                        e.checked = false;
    }
}
/* Modified from script by: Alan Gruskoff :: http://www.performantsystems.com/
 */
function countChecked(form) {
	var total = 0;
	var max = form.request_items.length;
	for (var idx = 0; idx < max; idx++) {
		if (eval("document.requestform.request_items[" + idx + "].checked") == true) {
    		total += 1;
   		}
	}
	if ( total > 10  ) {
  		alert("You have selected more than 10 items. Your request cannot be processed unless you keep the total to 10 or fewer. " );
	}         
}   


/**
 * from http://github.com/projectblacklight/blacklight/blob/v2.4.2/assets/javascripts/lightbox.js
 */
// To create a lightbox, insert the element into a view, give it a class of .lightboxContent and an ID.
// To create the link to activate the lightbox, give the link a class of .lightboxLink and name it
// the same thing as your lightboxContent element ID.
// You will need a close link in the lightbox. You can create that by making a link that has class of
// .lightboxLink and name it the same thing as your lightboxContent ID
// Note: The Open and close links are pretty much identical.
$(document).ready(function() {
  var lightboxContainer = $('#lightboxContainer');
    $(".lightboxLink").each(function(){
        $(this).click(function(){
            var lbelem = $("#" + $(this).attr("name"));
            lightboxContainer.toggle();
            lbelem.toggle();
            return false;
        });
    });
});