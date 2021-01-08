var itemSelectorCurrentLocationNote = (function() {
  return $.extend({}, itemSelector, {
    init: function() {
      var _this = this;
      $(document).on('turbolinks:load', function(){
        _this.addCurrentLocationNoteToggleBehavior();
      });
    },

    addCurrentLocationNoteToggleBehavior: function() {
      var _this = this;
      _this.selectorElement().on('item-selector:selected', function(_, item) {
        _this.showCurrentLocationNote(item);
      });
      _this.selectorElement().on('item-selector:deselected', function(_, item) {
        _this.hideCurrentLocationtNote(item);
      });
    },

    showCurrentLocationNote: function(item) {
      var note = this.currentLocationNote(item);
      if (note) { note.show(); }
    },

    hideCurrentLocationtNote: function(item) {
      var note = this.currentLocationNote(item);
      if (note) { note.hide(); }
    },

    currentLocationNote: function(item) {
      return item.closest('.input-group')
                 .find('[data-behavior="current-location-note"]');
    }
  });
})();

itemSelectorCurrentLocationNote.init();
