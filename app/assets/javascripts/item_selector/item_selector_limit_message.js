var itemSelectorLimitMessage = (function() {

  return $.extend({}, itemSelector, {
    init: function() {
      var _this = this;
      $(document).on('turbolinks:load', function(){
        _this.setupMaxSelectedListener();
        _this.setupDeselectedListener();
      });
    },

    setupDeselectedListener: function() {
      var _this = this;
      _this.selectorElement().on('item-selector:deselected', function() {
        _this.removeMessage();
      });
    },

    setupMaxSelectedListener: function() {
      var _this = this;
      _this.selectorElement()
           .on('item-selector:max-selected-reached', function() {
             _this.addMessage();
      });
    },

    addMessage: function() {
      this.messageContainer().html(this.limitReachedMessage());
    },

    removeMessage: function() {
      var message = this.messageContainer().find('#max-items-reached');
      if ( message.length > 0 ) {
        message.remove();
      }
    },

    messageContainer: function() {
      return $('[data-behavior="max-items-message"]');
    },

    limitReachedMessage: function() {
      return [
        '<div id="max-items-reached" class="alert alert-danger" role="alert">',
          this.selectorElement().data('limit-reached-message'),
        '</div>'
      ].join('\n');
    }
  });
})();

itemSelectorLimitMessage.init();

// Basic support of CommonJS module for import into test
if (typeof exports === "object") {
  module.exports = itemSelectorLimitMessage;
}
