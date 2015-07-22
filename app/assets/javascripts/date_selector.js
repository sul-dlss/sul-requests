var dateSelector = (function() {
  var defaultOptions = {
    mediatedPageFieldSelector: 'input[data-request-type="mediated_page"]'
  };

  return {
    init: function(opts) {
      var _this = this;
      _this.options = $.extend(defaultOptions, opts);
      $(document).on('ready page:load', function(){
        _this.setupListeners();
      });
    },

    options: {},

    setupListeners: function() {
      var _this = this;
      if ( _this.mediatedDateField().length > 0 ) {
        pagingScheduleUpdater
          .schedulerText()
          .on('paging-schedule:updated', function(_, data) {
            _this.setMinDate(data.date);
            _this.restrictToOpenDates(
              data.destination_business_days
            );
        });
      }
    },

    setMinDate: function(date) {
      if (date) {
        this.mediatedDateField().prop('min', date);
      }
    },

    restrictToOpenDates: function(openDates) {
      var _this = this;
      _this.mediatedDateField().on('change', function() {
        if ( openDates.indexOf(_this.selectedDate()) > -1 ) {
          _this.setDateFieldAsValid();
        } else {
          _this.setDateFieldAsInvalid();
        }
      });
    },

    selectedDate: function() {
      return new Date(
        this.mediatedDateField().val()
      ).toISOString().slice(0, 10);
    },

    setDateFieldAsValid: function() {
      this.mediatedDateField().closest('.form-group').removeClass('has-error');
      this.mediatedDateField()[0].setCustomValidity('');
    },

    setDateFieldAsInvalid: function() {
      this.mediatedDateField().closest('.form-group').addClass('has-error');
      this.mediatedDateField()[0].setCustomValidity(
        'The destination library is not open on ' + this.selectedDate()
      );
    },

    mediatedDateField: function() {
      return $(this.options.mediatedPageFieldSelector);
    }
  };
})();

dateSelector.init();
