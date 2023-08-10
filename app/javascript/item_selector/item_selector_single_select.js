import itemSelector from '../item_selector'

var itemSelectorSingleSelect = (function() {

  return $.extend({}, itemSelector, {
    init: function() {
      var _this = this;
      $(document).on('turbolinks:load', function(){
        _this.addDeselectBehaviorForRadioButtons();
      });
    },

    addDeselectBehaviorForRadioButtons: function() {
      var _this = this;
      var selections = [];
      _this.selectorElement()
           .on('item-selector:selected', function(e, checkbox) {
        if(checkbox.prop('type') == 'radio') {
          selections.push(checkbox);
          if(_this.numberOfSelectedCheckboxes() > 1) {
            _this.selectorElement()
                 .trigger('item-selector:deselected', [selections[0]]);
            selections.shift();
          }
        }
      });
    }
  });
})();
itemSelectorSingleSelect.init();
