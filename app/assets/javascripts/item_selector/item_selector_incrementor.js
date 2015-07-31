var itemSelectorIncrementor = (function() {
  return $.extend({}, itemSelector, {
    init: function() {
      var _this = this;
      $(document).on('ready page:load', function(){
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
