(function($) {
  $.fn.filterSelectedItems = function() {
    var listOptions = {
      page: 10000,
      valueNames: ['callnumber', 'status']
    };
    this.each(function(){
      new List($(this).attr('id'), listOptions);
    });
  };
})(jQuery);

$(document).on('ready page:load', function(){
  $('[data-filter-selected-items="true"]').filterSelectedItems();
});
