var mediationTable = (function() {
  var defaultOptions = {
    selector: '[data-mediate-request]'
  };

  var listOptions = {
    page: 10000,
    valueNames: [
      'needed_date',
      'title',
      'requester',
      'created_at',
      'comment'
    ]
  };

  return {
    init: function(opts) {
      var _this = this;
      _this.options = $.extend(defaultOptions, opts);
      $(document).on('turbolinks:load', function(){
        _this.addToggleHoldingsBehavior();
        _this.addSortableColumns();
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

    addSortableColumns: function() {
      var _this = this;
      if ( _this.tableElement().length > 0 ) {
        var list = new List(_this.tableElement().attr('id'), listOptions);
        list.on('sortComplete', function() {
          _this.restripeTable();
          _this.hideAllRows();
        });
      }
    },

    restripeTable: function() {
      this.tableElement()
           .find('tr:nth-child(even)')
           .removeClass('odd')
           .addClass('even');
      this.tableElement()
           .find('tr:nth-child(odd)')
           .removeClass('even')
           .addClass('odd');
    },

    hideAllRows: function() {
      var _this = this;
      _this.mediatableRows().each(function() {
        _this.hideRow($(this));
      });
    },

    tableElement: function() {
      return this.mediatableRows().closest('table');
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
      var holdingsRow = $('<tr class="holdings"><td colspan="7"></td></tr>');
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
