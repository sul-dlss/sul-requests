var iframePostMessage = (function() {
  return {
    init: function() {
      var _this = this;
      $(document).on('turbolinks:load', function(){
        if (top != self) {
          setInterval(function(){
            _this.sendMessage({
              contentHeight: $('html').outerHeight(true),
              successPage: $('.success-page').length > 0
            });
          }, 1000);
        }
      });
    },

    // If we ever extend the message to include something other than
    // sinle height data or status booleans then we should replace
    // '*' with the origin of who we will allow our messages to be sent
    // to. As it stands the data we are sending isn't sensitive and
    // can't be used to identify the user in any way.
    sendMessage: function(message) {
      parent.postMessage(message, '*');
    },

    sendCloseParentModalMessage: function() {
      this.sendMessage({ closeModal: true });
    }
  };
})();

iframePostMessage.init();
