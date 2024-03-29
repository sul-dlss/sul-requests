import $ from 'jquery'

var toggleShowTabs = (function() {
  var defaultOptions = {
    buttonSelector: '[data-toggle="show"]'
  };

  return {
    init: function(opts) {
      var _this = this;
      _this.options = $.extend(defaultOptions, opts);
      $(document).on('turbo:load', function(){
        _this.addToggleBehavior();
      });
    },

    options: {},

    addToggleBehavior: function() {
      var _this = this;
      $(document).on('click', _this.options.buttonSelector, function(e) {
        e.preventDefault();
        var showElement = $(document).find($(this).data('show'));
        showElement.show();
        showElement.attr('aria-hidden', 'false');

        var hideElement = $(document).find($(this).data('hide'));
        hideElement.hide();
        hideElement.attr('aria-hidden', 'true');

        if ($(this).data('focus')) {
          showElement.find($(this).data('focus')).focus();
        }
      });
    }
  };
})();

toggleShowTabs.init();

// Basic support of CommonJS module for import into test
if (typeof exports === "object") {
  module.exports = toggleShowTabs;
}
