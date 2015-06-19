var itemSelectorFiltering = (function() {

  var defaultOptions = {
    selector: '[data-filter-selected-items="true"]'
  };

  var listOptions = {
    page: 10000,
    valueNames: ['callnumber', 'status']
  };

  return $.extend(itemSelector, {
    init: function(opts) {
      var _this = this;
      _this.filteringOptions = $.extend(defaultOptions, opts);
      $(document).on('ready page:load', function(){
        _this.initializeListPlugin();
      });
    },

    filteringOptions: {},

    initializeListPlugin: function() {
      $(this.filteringOptions.selector).each(function() {
        new List($(this).attr('id'), listOptions);
      });
    }
  });
})();

itemSelectorFiltering.init();
