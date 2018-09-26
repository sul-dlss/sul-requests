var additionalUserValidationFields = (function() {
  var defaultOptions = {
    singleUserFieldSelector: '[data-behavior="single-user-field"]',
    groupedUserFieldSelector: '[data-behavior="grouped-user-field"]',
    buttonSelector: '[data-additional-user-validation="true"]'
  };

  return {
    init: function(opts) {
      var _this = this;
      _this.options = $.extend(defaultOptions, opts);
      $(document).on('turbolinks:load', function(){
        if(_this.submitButtons().length > 0) {
          _this.addFormvalidationBehavior();
        }
      });
    },
    options: {},

    addFormvalidationBehavior: function() {
      var _this = this;
      _this.singleUserFields().each(function() {
        _this.addInputListenerBehavior($(this));
      });
      _this.groupedUserFields().each(function() {
        _this.addInputListenerBehavior($(this));
      });
    },

    addInputListenerBehavior: function(input) {
      var _this = this;
      input.on('propertychange change input paste blur', function() {
        if(_this.submitButtons().is(':visible')) {
          if ( _this.fieldsAreValid() ) {
            $('form').trigger('item-selector:additional-user-validation-passed');
          } else {
            $('form').trigger('item-selector:additional-user-validation-failed');
          }
        }
      });
    },

    fieldsAreValid: function() {
      return this.validateSingleUserFields() || this.validateGroupUserFields();
    },

    validateSingleUserFields: function() {
      var valid = false;
      this.singleUserFields().each(function() {
        if ( $(this).val() ) {
          valid = true;
        }
      });
      return valid;
    },

    validateGroupUserFields: function() {
      return $.grep(this.groupedUserFields(), function(field, _) {
        return $(field).val();
      }).length == this.groupedUserFields().length;
    },

    addTooltipToButtonWrapper: function() {
      this.buttonWrapper().attr('data-toggle', 'tooltip')
                          .attr('data-placement', 'top')
                          .attr('data-title', 'Enter your Library ID or your name and email to complete you request.')
                          .tooltip();
    },

    removeTooltip: function() {
      this.buttonWrapper().tooltip('destroy');
    },

    singleUserFields: function() {
      return $(this.options.singleUserFieldSelector);
    },

    groupedUserFields: function() {
      return $(this.options.groupedUserFieldSelector);
    },

    submitButtons: function() {
      return $(this.options.buttonSelector);
    },

    buttonWrapper: function() {
      return this.submitButtons().parent('.button-wrapper');
    }
  };

})();

additionalUserValidationFields.init();
