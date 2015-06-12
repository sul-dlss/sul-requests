var itemSelector = (function() {
  var defaultOptions = {
    selector: '[data-behavior="item-selector"]'
  };

  return {
    init: function(opts) {
      var _this = this;
      _this.options = $.extend(defaultOptions, opts);
      $(document).on('ready page:load', function(){
        _this.setupEventTriggers();
      });
    },

    setupEventTriggers: function() {
      var _this = this;
      _this.checkboxes().each(function() {
        $(this).on('change', function() {
          if ( $(this).is(':checked') ) {
            $(this).trigger('item-selector:selected');
          } else {
            $(this).trigger('item-selector:deselected');
          }
        });
      });
    },

    options: {},

    selectorElement: function() {
      return $(this.options.selector);
    },

    checkboxes: function() {
      return this.selectorElement().find('input[type="checkbox"]');
    },

    numberOfSelectedCheckboxes: function() {
      var selection;
      selection = this.selectorElement()
                      .data('selected-items') || this.checkboxes()
                                                     .filter(':checked').length;
      return parseInt(selection, 10);
    }
  };
})();

itemSelector.init();
