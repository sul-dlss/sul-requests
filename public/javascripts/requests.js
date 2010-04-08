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

// Utility function - used in setting date
function pad(value, length) {
  length = length || 2;
  return "0000".substr(0,length - Math.min(String(value).length, length)) + value;
};
