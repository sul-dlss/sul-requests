/* global alert */

export default (function() {
  var buttonSelector = '[data-behavior="mark-as-complete"]';

  return {
    init: function(holdingsTable){
      this.holdingsTable = $(holdingsTable);

      this.onAjaxSuccess();
      this.onAjaxError();
    },

    onAjaxSuccess: function() {
      var _this = this;
      _this.markAsCompleteForm().on('ajax:success', function(event) {
        const request = event.detail[0]
        if(request.approval_status === 'marked_as_done') {
          _this.disableMarkAsCompleteButton();
          _this.markRequestRowAsMixedStatus();
        }
      });
    },

    onAjaxError: function() {
      this.markAsCompleteForm().on('ajax:error', function() {
        alert('There was a problem marking this request as complete.');
      });
    },

    disableMarkAsCompleteButton: function() {
      this.markAsCompleteButton().attr('disabled', 'true');
    },

    markRequestRowAsMixedStatus: function() {
      var requestRow =  this.holdingsTable
                            .closest('tr.holdings')
                            .prev('tr');
      if(requestRow.find('[data-behavior="all-approved-note"]').is(':hidden')) {
        requestRow
          .find('[data-behavior="mixed-approved-note"]')
          .show();
      }
    },

    markAsCompleteButton: function() {
      return this.holdingsTable.find(buttonSelector);
    },

    markAsCompleteForm: function() {
      return this.markAsCompleteButton().parent('form');
    }
  };
})();
