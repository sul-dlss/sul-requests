$(document).on('click', '#no-sunet-button', function(){
  setTimeout(function(){
      $('#request_user_attributes_library_id').focus();
  }, 1);

  $('form').on('keypress', function(e) {
    if(e.which == 13) {
      $('.form-group input').checkForm(e);
    }
  });

  $('.form-control').on('mouseenter mouseleave focus blur',function(e){
    $('.form-group input').checkForm(e);
  });

  $('#no-sunet-submit').click(function(e) {
    if ($('.form-group input').checkForm(e)){
      $('form').submit();
    }
  });
});

$.fn.checkForm = function(e) {
  var empty = true;

  $(this).each(function() {
    if ($(this).val().length > 0 &&
        $(this).attr('id') !=
        'request_user_attributes_name') {
      empty = false;
    }
  });

  if (!empty){
    $('[data-toggle="tooltip"]').tooltip('disable');
    return true;
  }
  else {
    $('[data-toggle="tooltip"]').tooltip('enable');
    e.preventDefault();
    return false;
  }
};
