(function($) {
  $.fn.addNameAndEmailInputs = function() {
    this.each(function(){
      $(this).on('click', function(){
        var target = $($(this).data('target'));
        var content = $($(this).data('content-target'));
        target.replaceWith(content);
        content.show();
      });
    });
  };
})(jQuery);

$(document).on('ready page:load', function(){
  $('[data-no-sunet="true"]').addNameAndEmailInputs();
});
