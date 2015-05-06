(function($) {
  $.fn.toggleNameAndEmailInputs = function() {
    this.each(function(){
      $(this).on('click', function(){
        var target = $($(this).data('target'));
        var content = $($(this).data('content-target'));
        var link = $($(this).data('link'));
        var targetScope = $(this).data('target');
        var store = target.detach();
        var form = $('form').last();

        content.append(link.show()).show();
        content.appendTo(form);
        store.appendTo(form).hide();

        if ( targetScope === '[data-no-sunet-content]' )
        {
          link.hide();
        }
      });
    });
  };
})(jQuery);

$(document).on('ready page:load', function(){
  $('[data-no-sunet="true"]').toggleNameAndEmailInputs();
});
