(function($) {
  $.fn.limitSelectedItems = function() {
    this.each(function(){
      var itemSelector = $(this);
      var limit = 5;
      var counter = $(itemSelector.data('counter-target'));
      var checkboxSelector = 'input[type="checkbox"]';
      var checkboxes = $(checkboxSelector, itemSelector);
      checkboxes.on('change', function(e){
        var numberOfSelectedCheckboxes = (itemSelector.data('selected-items') || 0);
        // We need to track if the check box is being checked or unchecked
        // individually since we can't depend on simply querying all
        // checked check boxes (search removes them from the DOM)
        if ($(this).prop('checked')) {
          numberOfSelectedCheckboxes += 1;
        } else {
          numberOfSelectedCheckboxes -= 1;
        }

        if ( numberOfSelectedCheckboxes > limit ) {
          e.preventDefault();
          $(this).prop('checked', false);
          numberOfSelectedCheckboxes -= 1;
        }

        itemSelector.data('selected-items', numberOfSelectedCheckboxes);
        counter.text(numberOfSelectedCheckboxes + ' items selected');

      });
    });
  };
})(jQuery);

$(document).on('ready page:load', function(){
  $('[data-limit-selected-items="true"]').limitSelectedItems();
});
