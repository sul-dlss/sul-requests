import $ from 'jquery'

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
      $(document).on('turbo:load', function(){
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
      if (this.groupedUserFields().length > 0) { // If we have a name + email field
        return this.validateGroupUserFields();   // Validate name + email field are filled out only (they are always required when present)
      } else {                                   // Else, we should only have a Library ID field
        return this.validateSingleUserFields();  // Validate Library ID field because it should be required.
      }
    },

    validateSingleUserFields: function() {
      var _this = this;
      var valid = false;
      _this.singleUserFields().each(function() {
        if ( $(this).val() && _this.customMinLengthValidation($(this)) ) {
          valid = true;
        }
      });
      return valid;
    },

    customMinLengthValidation: function(field) {
      if ( !field.attr('minlength') ) { return true; }

      if ( field.val().length < field.attr('minlength') ) {
        field[0].setCustomValidity(
          'Stanford Library ID must have 10 digits (you have entered ' + field.val().length + ' ).'
        );
      } else {
        field[0].setCustomValidity('');
      }

      return true;
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

// Basic support of CommonJS module for import into test
if (typeof exports === "object") {
  module.exports = additionalUserValidationFields;
}
