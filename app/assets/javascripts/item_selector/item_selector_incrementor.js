//= require 'item_selector/item_selector_limit'
//= require 'item_selector/item_selector_limit_message'
//= require 'item_selector/item_selector_zero_message'

var itemSelectorIncrementor = (function() {
  return $.extend({}, itemSelector, {
    init: function() {
      var _this = this;
      $(document).on('turbolinks:load', function(){
        _this.setDefaultItemCounter();
        _this.addIncrementBehavior();
      });
    },

    addIncrementBehavior: function() {
      var _this = this;
      _this.selectorElement().on('item-selector:selected', function() {
        _this.increaseSelectedItemCount();
      });

      _this.selectorElement().on('item-selector:deselected', function() {
        _this.decreaseSelectedItemCount();
      });
    },

    increaseSelectedItemCount: function() {
      this.selectedItemCounter().text(
        parseInt(this.selectedItemCounter().text(), 10) + 1
      );
    },

    decreaseSelectedItemCount: function() {
      this.selectedItemCounter().text(
        parseInt(this.selectedItemCounter().text(), 10) - 1
      );
    },

    setDefaultItemCounter: function() {
      this.selectedItemCounter().text(
        this.numberOfSelectedCheckboxes()
      );
    },

    selectedItemCounter: function() {
      var counterSelector = this.selectorElement()
                                .find('[data-counter-target]')
                                .data('counter-target');
      return $(counterSelector).find('[data-count]');
    }
  });
})();

itemSelectorIncrementor.init();

// Basic support of CommonJS module for import into test
if (typeof exports === "object") {
  module.exports = itemSelectorIncrementor;
}
