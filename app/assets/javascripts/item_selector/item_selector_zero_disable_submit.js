var itemSelectorZeroDisableSubmit = (function() {

  return $.extend({}, itemSelector, {
    init: function() {
      var _this = this;
      $(document).on('turbolinks:load', function(){
        if ($('[data-behavior="item-selector"]').length > 0) {
          _this.setupDeselectedButtonListener();
          _this.setupSelectedButtonListener();

          if ( _this.numberOfSelectedCheckboxes() === 0) {
            _this.disableSubmit();
          }
        }
      });
    },

    setupDeselectedButtonListener: function() {
      var _this = this;
      _this.selectorElement().on('item-selector:deselected', function() {
        if ( _this.numberOfSelectedCheckboxes() === 0) {
          _this.disableSubmit();
        }
      });
    },
  
    setupSelectedButtonListener: function() {
      var _this = this;
      _this.selectorElement().on('item-selector:selected', function() {
        _this.enableSubmit();
      });
    },

    disableSubmit: function() {
      this.submitButton().attr('disabled', true);
    },

    enableSubmit: function() {
      this.submitButton().attr('disabled', false);
    },

    submitButton: function() {
      return $(':submit');
    }
  });
})();

itemSelectorZeroDisableSubmit.init();
