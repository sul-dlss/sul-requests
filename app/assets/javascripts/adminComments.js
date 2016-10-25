/* global alert */

var adminComments = (function() {
  var adminCommentFormSelector = '#new_admin_comment';
  var adminCommentListSelector = '[data-behavior="admin-comments-list"]';
  var adminCommentToggleSelector = '[data-behavior="toggle-admin-comment-form"]';
  var adminCommentFormCancelButton = '[data-behavior="admin-comment-cancel"]';

  function commentTemplate(comment) {
    return '<li>' +
             comment.comment +
             '<span class="text-muted">' +
               ' - ' +
               comment.commenter + ' - ' +
               comment.created_at +
              '</span>' +
           '</li>';
  }

  return {
    init: function(holdingsTable) {
      this.holdingsTable = $(holdingsTable);
      this.form = this.holdingsTable.find(adminCommentFormSelector);

      this.addCommentToggleBehavior();

      this.onAjaxSuccess();

      this.onAjaxError();

      this.addCancelButtonBehavior();
    },

    addCommentToggleBehavior: function() {
      var _this = this;
      var commentToggle = _this.holdingsTable.find(adminCommentToggleSelector);
      commentToggle.on('click', function() {
        _this.toggleForm();
      });
    },

    onAjaxSuccess: function() {
      var _this = this;
      _this.form.on('ajax:success', function(e, comment){
        _this.form.find('input[type="text"]').val('');
        var commentList = _this.holdingsTable.find(adminCommentListSelector);

        commentList.append(commentTemplate(comment));
      });
    },

    onAjaxError: function() {
      this.form.on('ajax:error', function() {
        alert('There was a problem saving your comment.');
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
