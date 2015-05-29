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
        if(_this.rowIsProcessed(row)) {
          _this.toggleRow(row);
        } else {
          _this.addHoldings(row);
          _this.setRowProcessed(row);
        }
      });
    },

    toggleRow: function(row) {
      if ( row.hasClass('expanded') ) {
        row.removeClass('expanded');
        row.next('tr').hide();
      } else {
        row.addClass('expanded');
        row.next('tr').show();
      }
    },

    addHoldings: function(row) {
      $.ajax(row.data('mediate-request')).done(function(data){
        row.after('<tr><td colspan="5">' + data + '</td></tr>');
        row.addClass('expanded');
      });
    },

    toggleHandle: function(row) {
      return row.find('[data-behavior="mediate-toggle"]');
    },

    setRowProcessed: function(row) {
      row.data('holdings-processed', 'true');
    },

    rowIsProcessed: function(row) {
      return row.data('holdings-processed') == 'true';
    }
  };

})();

mediationTable.init();
