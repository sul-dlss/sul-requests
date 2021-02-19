var noJS = (function() {
  return {
    init: function() {
      var _this = this;
      $(document).on('turbolinks:load', function(){
        _this.toggleNoJS();
      });
    },

    toggleNoJS: function() {
      $('.no-js').removeClass('no-js');
    }
  };
})();

noJS.init();

// Basic support of CommonJS module for import into test
if (typeof exports === "object") {
  module.exports = noJS;
}
