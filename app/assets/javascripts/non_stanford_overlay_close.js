/* global iframePostMessage */

var nonStanfordOverlay = (function() {
  var yesSelector = '[data-behavior="close-overlay"]';
  var noSelector = '[data-behavior="close-parent-modal"]';
  function addOverlayCloseBehavior() {
    $(yesSelector).on('click', function(){
      var targetSelector = $(this).data('close-target');
      $(this).parents(targetSelector).hide();
    });
  }

  function inModal() {
    return $('.modal-body').length > 0;
  }

  function addModalCloseBehavior() {
    if (inModal()) {
      $(noSelector).on('click', function(e){
        e.preventDefault();
        iframePostMessage.sendCloseParentModalMessage();
      });
    }
  }

  return {
    init: function() {
      $(document).on('turbolinks:load', function(){
        addOverlayCloseBehavior();
        addModalCloseBehavior();
      });
    }
  };
})();

nonStanfordOverlay.init();
