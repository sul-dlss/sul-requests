var itemSelectorLimit = (function() {

  var selectorLimit = function(_this) {
    return parseInt(
      _this.selectorElement()
           .find('[data-limit-selected-items]')
           .data('limit-selected-items'), 10);
  };

  return $.extend(itemSelector, {
    init: function() {
      var _this = this;
      $(document).on('ready page:load', function(){
        _this.setupEventListeners();
        _this.setupDefaults();
      });
    },

    setupDefaults: function() {
      this.selectorElement()
          .data('selected-items', this.numberOfSelectedCheckboxes());
    },

    setupEventListeners: function() {
      var _this = this;
      _this.checkboxes().each(function() {
        $(this).on('item-selector:selected', function() {
          _this.increaseSelectedNumber();
          _this.enforceSelectedItemLimit($(this));
        });

        $(this).on('item-selector:deselected', function() {
          _this.decreaseSelectedNumber();
        });
      });
    },

    enforceSelectedItemLimit: function(checkbox) {
      var _this = this;
      var limit = selectorLimit(_this);
      if (limit && _this.numberOfSelectedCheckboxes() > limit) {
        _this.selectorElement().trigger('item-selector:max-selected-reached');
        checkbox.prop('checked', false)
                .trigger('item-selector:deselected');
      }
    },

    increaseSelectedNumber: function() {
      this.selectorElement().data(
        'selected-items',
        parseInt(this.selectorElement().data('selected-items'), 10) + 1
      );
    },

    decreaseSelectedNumber: function() {
      this.selectorElement().data(
        'selected-items',
        parseInt(this.selectorElement().data('selected-items'), 10) - 1
      );
    }
  });
})();

itemSelectorLimit.init();
