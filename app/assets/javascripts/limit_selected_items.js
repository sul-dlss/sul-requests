(function($) {
  $.fn.limitSelectedItems = function() {
    this.each(function(){
      var itemSelector = $(this);
      var limit = parseInt(itemSelector.data('limit-selected-items'), 10);
      var counter = $(itemSelector.data('counter-target'));
      var checkboxSelector = 'input[type="checkbox"]';
      var checkboxes = $(checkboxSelector, itemSelector);
      var initSelected = $(checkboxSelector + ':checked', itemSelector).length;

      // Set initial states to handle Back-Forward Cache
      updateSelectedItemsData(itemSelector, initSelected);
      updateCounterText(counter, initSelected);

      checkboxes.on('change', function(e){
        var numberOfSelectedCheckboxes = itemSelector.data('selected-items');
        // We need to track if the check box is being checked or unchecked
        // individually since we can't depend on simply querying all
        // checked check boxes (search removes them from the DOM)
        if ($(this).prop('checked')) {
          numberOfSelectedCheckboxes += 1;
        } else {
          numberOfSelectedCheckboxes -= 1;
        }

        if ( limit && numberOfSelectedCheckboxes > limit ) {
          e.preventDefault();
          $(this).prop('checked', false);
          numberOfSelectedCheckboxes -= 1;
        }

        updateSelectedItemsData(itemSelector, numberOfSelectedCheckboxes);
        updateCounterText(counter, numberOfSelectedCheckboxes);
      });
    });
  };

  function updateSelectedItemsData(selector, number) {
    selector.data('selected-items', number);
  }

  function updateCounterText(counter, number) {
    counter.text(number + ' items selected');
  }

  return this;
})(jQuery);

$(document).on('ready page:load', function(){
  $('[data-limit-selected-items]').limitSelectedItems();
});
