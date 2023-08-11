import $ from 'jquery'

var itemApproval = (function() {
  var defaultOptions = {
    buttonSelector: '[data-behavior="item-approval"]',
    approverInfoSelector: '[data-behavior="approver-information"]'
  };

  return {
    init: function(opts) {
      var _this = this;
      _this.options = $.extend(defaultOptions, opts);
      $(document).on('turbolinks:load', function(){
        _this.addApprovalBehavior();
      });
    },

    options: {},

    addApprovalBehavior: function() {
      var _this = this;
      $(document).on('click', _this.options.buttonSelector, function() {
        if($(this).data('approval-behavior-added') === undefined) {
          var row = $(this).closest('tr');
          if(!_this.rowIsApproved(row)) {
            _this.approveItem($(this));
          }
        }
        $(this).data('approval-behavior-added', 'true');
      });
    },

    approveItem: function(item) {
      var _this = this;
      var url = item.data('item-approval-url');

      _this.disableElement(item);
      $.ajax(url).done(function(data) {
         _this.markRowAsApproved(item);
         _this.updateApproverInformation(item, data);
         _this.updateAllApprovedNote(item);
       }).fail(function(data) {
         if (data.responseJSON) {
           _this.addItemErrorInformation(item, data.responseJSON);
           _this.markRowAsError(item);
         }
         _this.addHoldingsLevelAlert(item, data);
         _this.enableElement(item);
       });
    },

    disableElement: function(elt) {
      elt.attr('disabled', 'disabled');
    },

    enableElement: function(elt) {
      elt.removeAttr('disabled');
    },

    markRowAsApproved: function(item) {
      item.closest('tr').addClass('approved');
      item.closest('tr').find(this.options.buttonSelector).html('Approved');
    },

    markRowAsError: function(item) {
      item.closest('tr').addClass('errored');
    },

    updateApproverInformation: function(item, data) {
      var approverInfo = item.closest('tr')
                             .find(this.options.approverInfoSelector);
      approverInfo.text(data.approver + ' - ' + data.approval_time);
    },

    addHoldingsLevelAlert: function(item, data) {
      var json = data.responseJSON;
      if(!json || (json.errored && !json.usererr_code)) {
        var holdingsTable = item.closest('table');
        if(holdingsTable.prev('.alert.alert-danger').length === 0) {
          holdingsTable.before(this.alertHtmlTemplate());
        }
      }
    },

    updateAllApprovedNote: function(item) {
      if(this.allItemsAreApproved(item)) {
        var tableRow = item.closest('tr.holdings').prev('tr');
        tableRow.find('[data-behavior="all-approved-note"]').show();
        tableRow.find('[data-behavior="mixed-approved-note"]').hide();
      }
    },

    addItemErrorInformation: function(item, data) {
      item.closest('tr')
          .find('.request-status')
          .text(data.text);
    },

    allItemsAreApproved: function(item) {
      var tbody = item.closest('table tbody');
      return tbody.find('tr').length == tbody.find('tr.approved').length;
    },

    rowIsApproved: function(row) {
      return row.hasClass('approved');
    },

    alertHtmlTemplate: function() {
      var template = [
        '<div class="alert alert-danger">',
          'There was a problem with this request.',
          'Try again, or contact technical support.',
          'No message has been sent to the patron',
        '</div>'
      ].join(' ');
      return $(template);
    }
  };
})();

itemApproval.init();

// Basic support of CommonJS module for import into test
if (typeof exports === "object") {
  module.exports = itemApproval;
}
