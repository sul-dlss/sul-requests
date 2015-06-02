var mediationTable = (function() {
  var defaultOptions = {
    selector: '[data-mediate-request]'
  };

  return {
    init: function(opts) {
      var _this = this;
      _this.options = $.extend(defaultOptions, opts);
      $(document).on('ready page:load', function(){
        _this.addToggleHoldingsBehavior();
      });
      return this;
    },

    options: {},

    addToggleHoldingsBehavior: function() {
      var _this = this;
      _this.mediatableRows().each(function(){
        _this.addToggleClick($(this));
      });
    },

    mediatableRows: function() {
      return $(this.options.selector);
    },

    addToggleClick: function(row) {
      var _this = this;
      var toggle = _this.toggleHandle(row);
      toggle.on('click', function() {
        _this.toggleHoldings(row);
      });
    },

    toggleHoldings: function(row) {
      if ( row.hasClass('expanded') ) {
        this.hideRow(row);
      } else {
        this.showRow(row);
      }
    },

    showRow: function(row) {
      this.addHoldings(row);
      row.addClass('expanded');
      this.holdingsRow(row).show();
    },

    hideRow: function(row) {
      row.removeClass('expanded');
      this.holdingsRow(row).hide();
    },

    addHoldings: function(row) {
      var _this = this;
      if ( !_this.rowIsProcessed(row) ) {
        var holdingsRow = _this.createHoldingsRow(row);
        $.ajax(row.data('mediate-request')).done(function(data){
          holdingsRow.find('td').html(data);
          row.addClass('expanded');
        });
      }
    },

    createHoldingsRow: function(row) {
      var holdingsRow = $('<tr class="holdings"><td colspan="5"></td></tr>');
      row.after(holdingsRow);
      return holdingsRow;
    },

    toggleHandle: function(row) {
      return row.find('[data-behavior="mediate-toggle"]');
    },

    holdingsRow: function(row) {
      return row.next('tr.holdings');
    },

    rowIsProcessed: function(row) {
      return this.holdingsRow(row).find('table').length > 0;
    }
  };

})();

mediationTable.init();
