var dateSelector = (function() {
  var defaultOptions = {
    mediatedPageFieldSelector: 'input[data-request-type="mediated_page"]',
    dropdownSelector: '[data-paging-schedule-updater="true"]',
    singleLibrarySelector: '[data-single-library-value]'
  };

  return {
    init: function(opts) {
      var _this = this;
      _this.options = $.extend(defaultOptions, opts);
      $(document).on('turbolinks:load', function(){
        _this.setupListeners();
      });
    },

    options: {},

    setupListeners: function() {
      var _this = this;
      if ( _this.mediatedDateField().length > 0 ) {
        _this.destinationDropdown().on('change', function() {
          _this.validateDateField();
        });

        $('[data-scheduler-text]').on('paging-schedule:updated', function(_, data) {
          _this.setMinDate(data.date);
        });

        _this.mediatedDateField().on('change', function() {
          _this.validateDateField();
        });
      }
    },

    setMinDate: function(date) {
      if (date) {
        this.mediatedDateField().prop('min', date);
      }
    },

    selectedDate: function() {
      return new Date(
        this.mediatedDateField().val()
      ).toISOString().slice(0, 10);
    },

    validateDateField: function() {
      var _this = this;
      $.getJSON(_this.hoursLookupUrl(_this.destination(), _this.selectedDate()))
       .done(function(data){
          if(data.ok === true) {
            _this.setDateFieldAsValid();
          } else {
            _this.setDateFieldAsInvalid();
          }
       })
       .fail(function(){
         _this.setDateFieldAsInvalid();
       });
    },

    destination: function() {
      if (this.singleLibraryElement().length > 0) {
        return this.singleLibraryElement().data('single-library-value');
      } else {
        return this.destinationDropdown().val();
      }
    },

    destinationDropdown: function() {
      return $(this.options.dropdownSelector);
    },

    singleLibraryElement: function() {
      return $(this.options.singleLibrarySelector);
    },

    setDateFieldAsValid: function() {
      this.mediatedDateField().closest('.form-group').removeClass('has-error');
      this.mediatedDateField()[0].setCustomValidity('');
      this.mediatedDateField().siblings('.help-block').remove();
    },

    setDateFieldAsInvalid: function() {
      this.mediatedDateField().closest('.form-group').addClass('has-error');
      this.mediatedDateField()[0].setCustomValidity(
        'This library is not open on ' + this.selectedDate()
      );
    },

    mediatedDateField: function() {
      return $(this.options.mediatedPageFieldSelector);
    },

    hoursLookupUrl: function(destination, date) {
      return this.baseUrl() + '/' + destination + '/' + date;
    },

    baseUrl: function(container) {
      return $('[data-scheduler-lookup-url]').data('scheduler-lookup-url');
    },
  };
})();

dateSelector.init();
