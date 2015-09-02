var noJS = (function() {
  return {
    init: function() {
      var _this = this;
      $(document).on('ready page:load', function(){
        _this.toggleNoJS();
      });
    },

    toggleNoJS: function() {
      $('.no-js').removeClass('no-js');
    }
  };
})();

noJS.init();