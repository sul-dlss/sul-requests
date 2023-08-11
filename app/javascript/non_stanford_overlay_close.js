/* global iframePostMessage */
import $ from 'jquery'

var nonStanfordOverlay = (function() {
  var yesSelector = '[data-behavior="close-overlay"]';
  function addOverlayCloseBehavior() {
    $(yesSelector).on('click', function(){
      var targetSelector = $(this).data('close-target');
      $(this).parents(targetSelector).hide();
    });
  }

  return {
    init: function() {
      $(document).on('turbo:load', function(){
        addOverlayCloseBehavior();
      });
    }
  };
})();

nonStanfordOverlay.init();
