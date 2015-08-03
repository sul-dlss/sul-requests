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
            _this.selectorElement()
                 .trigger('item-selector:selected', [$(this)]);
          } else {
            _this.selectorElement()
                 .trigger('item-selector:deselected', [$(this)]);
          }
        });
      });
    },

    options: {},

    selectorElement: function() {
      return $(this.options.selector);
    },

    checkboxes: function() {
      return this.selectorElement()
                 .find('input[type="checkbox"], input[type="radio"]');
    },

    numberOfSelectedCheckboxes: function() {
      var selection;
      selection = this.selectorElement()
                      .data('selected-items') || this.checkboxes()
                                                     .filter(':checked').length;
      return parseInt(selection, 10);
    },

    breadcrumbContainer: function() {
      return $('[data-behavior="breadcrumb-container"]');
    }
  };
})();

itemSelector.init();
