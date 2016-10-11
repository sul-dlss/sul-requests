var iframePostMessage = (function() {
  return {
    init: function() {
      $(document).on('turbolinks:load', function(){
        if (top != self) {
          setInterval(function(){
            var message = {
              contentHeight: $('html').outerHeight(true),
              successPage: $('.success-page').length > 0
            };

            // If we ever extend the message to include something other than
            // contentHeight or the successPage boolean then we should replace
            // '*' with the origin of who we will allow our messages to be sent
            // to. As it stands the data we are sending isn't sensitive and
            // can't be used to identify the user in any way.
            parent.postMessage(message, '*');
          }, 1000);
        }
      });
    }
  };
})();

iframePostMessage.init();
