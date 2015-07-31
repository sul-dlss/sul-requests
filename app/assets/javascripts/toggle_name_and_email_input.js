(function($) {
  $.fn.toggleNameAndEmailInputs = function() {
    this.each(function(){
      var contentForm = $(this).closest('form');

      $(this).on('click', function() {
        var target = $($(this).data('target'));
        var content = $($(this).data('content-target'));
        var link = $($(this).data('link'));
        var targetScope = $(this).data('target');
        var store = target.detach();

        content.append(link.show()).show();
        content.appendTo(contentForm);
        store.appendTo(contentForm).hide();

        if ( targetScope === '[data-no-sunet-content]' )
        {
          link.hide();
        }
        else if ( targetScope === '[data-no-sunet-target]' )
        {
          $(content).find('input[type=text]')
            .filter(':visible:first').focus();
        }
      });
    });
  };
})(jQuery);

$(document).on('ready page:load', function(){
  $('[data-no-sunet="true"]').toggleNameAndEmailInputs();
});
