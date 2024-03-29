import itemSelector from '../item_selector'

var itemSelectorActive = (function() {

  return $.extend({}, itemSelector, {
    init: function() {
      var _this = this;
      $(document).on('turbo:load', function(){
        _this.setupDefaultActiveRows();
        _this.addActiveBehavior();
      });
    },

    setupDefaultActiveRows: function() {
      var _this = this;
      _this.checkboxes()
           .filter(':checked')
           .each(function() {
             _this.addActive($(this));
           });
    },

    addActiveBehavior: function() {
      var _this = this;
      _this.selectorElement()
           .on('item-selector:selected', function(event, item) {
             _this.addActive(item);
      });

      _this.selectorElement()
           .on('item-selector:deselected', function(event, item) {
             _this.removeActive(item);
      });
    },

    addActive: function(item) {
      item.closest('.input-group').addClass('active');
    },

    removeActive: function(item) {
      item.closest('.input-group').removeClass('active');
    }
  });
})();

itemSelectorActive.init();

// Basic support of CommonJS module for import into test
if (typeof exports === "object") {
  module.exports = itemSelectorActive;
}
