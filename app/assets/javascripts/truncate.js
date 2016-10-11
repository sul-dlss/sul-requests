var truncate = (function() {
    return {
        init: function() {
          $(document).on('turbolinks:load', function() {
            $("[data-behavior='truncate']").trunk8({
              lines: 2,
              tooltip: false
            });
          });
      }
    };
}());

truncate.init();
