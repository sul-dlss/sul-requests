var itemSelectorCheckedoutNote = (function() {
  return $.extend({}, itemSelector, {
    init: function() {
      var _this = this;
      $(document).on('ready page:load', function(){
        _this.addCheckedoutNoteToggleBehavior();
      });
    },

    addCheckedoutNoteToggleBehavior: function() {
      var _this = this;
      _this.selectorElement().on('item-selector:selected', function(_, item) {
        _this.showCheckedoutNote(item);
      });
      _this.selectorElement().on('item-selector:deselected', function(_, item) {
        _this.hideCheckedoutNote(item);
      });
    },

    showCheckedoutNote: function(item) {
      var note = this.checkedoutNote(item);
      if (note) { note.show(); }
    },

    hideCheckedoutNote: function(item) {
      var note = this.checkedoutNote(item);
      if (note) { note.hide(); }
    },

    checkedoutNote: function(item) {
      return item.closest('.input-group')
                 .find('[data-behavior="checkedout-note"]');
    }
  });
})();

itemSelectorCheckedoutNote.init();
