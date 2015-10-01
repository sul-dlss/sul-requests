var itemApproval = (function() {
  var defaultOptions = {
    buttonSelector: '[data-behavior="item-approval"]',
    approverInfoSelector: '[data-behavior="approver-information"]'
  };

  return {
    init: function(opts) {
      var _this = this;
      _this.options = $.extend(defaultOptions, opts);
      $(document).on('ready page:load', function(){
        _this.addApprovalBehavior();
      });
    },

    options: {},

    addApprovalBehavior: function() {
      var _this = this;
      $(document).on('click', _this.options.buttonSelector, function() {
        var row = $(this).closest('tr');
        if(!_this.rowIsApproved(row)) {
          _this.approveItem($(this));
        }
      });
    },

    approveItem: function(item) {
      var _this = this;
      var url = item.data('item-approval-url');
      $.ajax(url).success(function(data) {
         _this.markRowAsApproved(item);
         _this.updateApproverInformation(item, data);
         _this.updateAllApprovedNote(item);
       }).fail(function() {
         alert('The item was not able to be approved.');
       });
    },

    markRowAsApproved: function(item) {
      item.closest('tr').addClass('approved');
      item.closest('tr').find(this.options.buttonSelector).html('Approved');
    },

    updateApproverInformation: function(item, data) {
      var approverInfo = item.closest('tr')
                             .find(this.options.approverInfoSelector);
      approverInfo.text(data.approver + ' - ' + data.approval_time);
    },

    updateAllApprovedNote: function(item) {
      if(this.allItemsAreApproved(item)) {
        item.closest('tr.holdings')
            .prev('tr')
            .find('[data-behavior="all-approved-note"]')
            .show();
      }
    },

    allItemsAreApproved: function(item) {
      var tbody = item.closest('table tbody');
      return tbody.find('tr').length == tbody.find('tr.approved').length;
    },

    rowIsApproved: function(row) {
      return row.hasClass('approved');
    }
  };
})();

itemApproval.init();
