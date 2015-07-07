var pagingScheduleUpdater = (function() {

  var defaultOptions = {
    selector: '[data-paging-schedule-updater="true"]',
    urlSelector: '[data-scheduler-lookup-url]',
    textSelector: '[data-scheduler-text]',
    singleLibrarySelector: '[data-single-library-value]'
  };

  return {
    init: function(opts) {
      var _this = this;
      _this.options = $.extend(defaultOptions, opts);
      $(document).on('ready page:load', function(){
        _this.requestPagingScheduleData(); // Set initial schedule state
        _this.addSelectChangeBehavior();
      });
    },

    options: {},

    addSelectChangeBehavior: function() {
      var _this = this;
      _this.selectElement().on('change', function() {
        _this.requestPagingScheduleData();
      });
    },

    requestPagingScheduleData: function() {
      var _this = this;
      var originalValue = _this.schedulerValue();
      if ( originalValue && _this.schedulerText().length > 0 ) {
        $.ajax({
          url: _this.schedulerUrl(_this.schedulerValue())
        }).success(function(data) {
          if ( originalValue == _this.schedulerValue()) {
            _this.updateSchedulerText(data);
          }
        }).fail(function() {
          _this.updateSchedulerText({'text': 'No estimate available'});
        });
      }
    },

    schedulerValue: function() {
      if ( this.selectElement().val() ) {
        return this.selectElement().val();
      }else if ( this.singleLibraryValue() ) {
        return this.singleLibraryValue();
      }
    },

    updateSchedulerText: function(data) {
      var _this = this;
      if(_this.schedulerText().text() != data.text) {
        _this.schedulerText().text(data.text);
        _this.schedulerText().addClass('highlighted');
        setTimeout(function(){
          _this.schedulerText().removeClass('highlighted');
        }, 1500);
      }
    },

    selectElement: function() {
      return $(this.options.selector);
    },

    singleLibraryValue: function() {
      return $(this.options.singleLibrarySelector).data('single-library-value');
    },

    schedulerUrl: function(destination) {
      return $(this.options.urlSelector)
               .data('scheduler-lookup-url') + '/' + destination;
    },

    schedulerText: function() {
      return $(this.options.textSelector);
    }
  };
})();

pagingScheduleUpdater.init();
