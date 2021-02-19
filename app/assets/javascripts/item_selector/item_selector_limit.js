var itemSelectorLimit = (function() {

  var selectorLimit = function(_this) {
    return parseInt(
      _this.selectorElement()
           .find('[data-limit-selected-items]')
           .data('limit-selected-items'), 10);
  };

  return $.extend({}, itemSelector, {
    init: function() {
      var _this = this;
      $(document).on('turbolinks:load', function(){
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
      _this.searchListener();
      _this.selectorElement().on('item-selector:selected', function(_, item) {
        _this.increaseSelectedNumber();
        _this.enforceSelectedItemLimit(item);
      });

      _this.selectorElement().on('item-selector:deselected', function(_, item) {
        _this.decreaseSelectedNumber();
        _this.enforceSelectedItemLimit(item);
      });
    },

    searchListener: function(){
      var _this = this;
      var limit = selectorLimit(_this);
      $('#item-selector-search').on('blur', function(){
        if (_this.numberOfSelectedCheckboxes() >= limit){
          _this.disableUnselected();
        }

        if ( _this.numberOfSelectedCheckboxes() < limit ) {
          _this.reenableUnselected();
        }
      });
    },

    enforceSelectedItemLimit: function(checkbox) {
      var _this = this;
      var limit = selectorLimit(_this);
      if ( limit ) {

        if ( _this.numberOfSelectedCheckboxes() > limit ) {
          _this.selectorElement()
               .trigger('item-selector:deselected', [checkbox]);
        }

        if ( _this.numberOfSelectedCheckboxes() < limit ) {
          _this.reenableUnselected();
        }

        if ( _this.numberOfSelectedCheckboxes() >= limit ) {
          _this.selectorElement()
               .trigger('item-selector:max-selected-reached');
          _this.disableUnselected();
        }
      }
    },

    disableUnselected: function(){
      this.selectorElement()
        .find('input[type="checkbox"]:not(:checked)')
        .attr('disabled','disabled');
    },

    reenableUnselected: function(){
      this.selectorElement()
        .find($('input[type="checkbox"]').attr('disabled', 'disabled'))
        .removeAttr('disabled');
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

// Basic support of CommonJS module for import into test
if (typeof exports === "object") {
  module.exports = itemSelectorLimit;
}
