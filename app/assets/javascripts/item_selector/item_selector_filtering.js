var itemSelectorFiltering = (function() {
  var listOptions = {
    page: 10000,
    valueNames: ['callnumber', 'status']
  };

  return $.extend(itemSelector, {
    init: function() {
      var _this = this;
      $(document).on('ready page:load', function(){
        var list = _this.listPlugin();
        _this.clearSearchInputOnFormSubmit(list);
      });
    },

    listPlugin: function() {
      return new List(this.selectorElement().attr('id'), listOptions);
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
