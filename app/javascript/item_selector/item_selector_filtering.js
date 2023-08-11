import List from '../list.min'
import itemSelector from '../item_selector'

var itemSelectorFiltering = (function() {
  var listOptions = {
    page: 10000,
    valueNames: ['callnumber', 'status']
  };

  return $.extend({}, itemSelector, {
    init: function() {
      var _this = this;
      $(document).on('turbolinks:load', function(){
        var list = _this.listPlugin();
        _this.setDefaultSort(list);
        _this.clearSearchInputOnFormSubmit(list);
      });
    },

    listPlugin: function() {
      return new List(this.selectorElement().attr('id'), listOptions);
    },

    setDefaultSort: function(list) {
      // List.js dynamically injects behavior, so we need to check
      // if the list is sortable before setting the default sort
      if($.isFunction(list.sort)) {
        list.sort('callnumber', { order: 'asc'});
      }
    },

    clearSearchInputOnFormSubmit: function(list) {
      var _this = this;
      _this.selectorElement().closest('form').on('submit', function() {
        list.search(); // Clear search filter so all selections are present
        _this.filterInput().val('');
      });
    },

    filterInput: function() {
      return this.selectorElement().find('input.search');
    }
  });
})();

itemSelectorFiltering.init();

// Basic support of CommonJS module for import into test
if (typeof exports === "object") {
  module.exports = itemSelectorFiltering;
}
