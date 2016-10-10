var itemSelectorZeroMessage = (function() {

  return $.extend({}, itemSelector, {
    init: function() {
      var _this = this;
      $(document).on('turbolinks:load', function(){
        if ($('[data-behavior="item-selector"]').length > 0) {
          _this.setupDeselectedMessageListener();
          _this.setupSelectedMessageListener();

          if ( _this.numberOfSelectedCheckboxes() === 0) {
            _this.addZeroMessage();
          }
        }
      });
    },

    setupDeselectedMessageListener: function() {
      var _this = this;
      _this.selectorElement().on('item-selector:deselected', function() {
        if ( _this.numberOfSelectedCheckboxes() === 0) {
          _this.addZeroMessage();
        }
      });
    },
  
    setupSelectedMessageListener: function() {
      var _this = this;
      _this.selectorElement().on('item-selector:selected', function() {
        _this.removeZeroMessage();
      });
    },

    addZeroMessage: function() {
      this.zeroMessageContainer().show();
    },

    removeZeroMessage: function() {
      this.zeroMessageContainer().hide();
    },

    zeroMessageContainer: function() {
      return $('.zero-items-message');
    }
  });
})();

itemSelectorZeroMessage.init();
