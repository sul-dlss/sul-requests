export default (function() {
  var adminCommentFormSelector = '#new_admin_comment';
  var adminCommentToggleSelector = '[data-behavior="toggle-admin-comment-form"]';
  var adminCommentFormCancelButton = '[data-behavior="admin-comment-cancel"]';

  return {
    init: function(holdingsTable) {
      this.holdingsTable = $(holdingsTable);
      this.form = this.holdingsTable.find(adminCommentFormSelector);

      this.addCommentToggleBehavior();

      this.addCancelButtonBehavior();
    },

    addCommentToggleBehavior: function() {
      var _this = this;
      var commentToggle = _this.holdingsTable.find(adminCommentToggleSelector);
      commentToggle.on('click', function() {
        _this.toggleForm();
      });
    },

    addCancelButtonBehavior: function() {
      var _this = this;
      var cancelButton = _this.holdingsTable.find(adminCommentFormCancelButton);
      cancelButton.on('click', function(e){
        e.preventDefault();

        _this.clearForm();
        _this.toggleForm();
      });
    },

    clearForm: function() {
      this.form.find('input[type="text"]').val('');
    },

    toggleForm: function() {
      this.form.slideToggle();
    }
  };
})();
