(function($) {
  $.fn.limitSelectedItems = function() {
    this.each(function(){
      var itemSelector = $(this);
      var limit = 5;
      var counter = $(itemSelector.data('counter-target'));
      var checkboxSelector = 'input[type="checkbox"]';
      var checkedSelector = checkboxSelector + ':checked';
      var checkboxes = $(checkboxSelector, itemSelector);
      checkboxes.on('change', function(e){
        if ( $(checkedSelector, itemSelector).length > limit ) {
          e.preventDefault();
          $(this).prop('checked', false);
        }
        counter.text($(checkedSelector, itemSelector).length + ' items selected');
      });
    });
  };
})(jQuery);

$(document).on('ready page:load', function(){
  $('[data-limit-selected-items="true"]').limitSelectedItems();
});
