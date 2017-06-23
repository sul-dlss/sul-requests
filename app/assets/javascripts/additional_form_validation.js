var additionalFormValidation = (function() {
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
          if(!_this.fieldsAreValid() && _this.submitButtons().is(':visible')) {
            _this.disableButton();
          }

          _this.addFormvalidationBehavior();
        }
      });
    },
    options: {},

    enableButton: function() {
      this.submitButtons().removeClass('disabled');
      this.submitButtons().removeAttr('disabled');
      this.submitButtons().closest('form').unbind('submit.disabled-button');
    },

    disableButton: function() {
      this.addTooltipToButtonWrapper();
      this.submitButtons().addClass('disabled');
      this.submitButtons().closest('form').on('submit.disabled-button', function(e) {
        e.preventDefault();
      });
    },

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
            _this.enableButton();
          } else {
            _this.disableButton();
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

additionalFormValidation.init();
