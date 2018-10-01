var requestFormValidator = (function() {

  return $.extend({}, itemSelector, {
    init: function() {
      var _this = this;
      $(document).on('turbolinks:load', function(){
        _this.setupEventListeners();

        // If there are no selected items
        if (!_this.anItemIsSelected()) {
          // Disable all buttons
          _this.disableButton(_this.submitButtons());
        }

        // If the fields that require additional user validation are not valid
        if(!additionalUserValidationFields.fieldsAreValid()) {
          // Disable the button that requires additional user validation
          _this.disableButton(_this.additionalValidationButton());
        }
      });
    },

    setupEventListeners: function() {
      var _this = this;
      // When an item is deselected
      _this.selectorElement().on('item-selector:deselected', function() {
        // And the number of selected items is now 0
        if(!_this.anItemIsSelected()) {
          // Disable all buttons
          _this.disableButton(_this.submitButtons());
        }
      });

      // When an item is selected
      _this.selectorElement().on('item-selector:selected', function() {
        // Enable the button that require no additional user validation
        _this.enableButton(_this.noAdditionalValidationButton());

        // And the fields that require additional validation are valid
        if(additionalUserValidationFields.fieldsAreValid()) {
          // Enable the button that require additional user validation
          _this.enableButton(_this.additionalValidationButton());
        }
      });

      // When the additional user validation fails
      $('form').on('item-selector:additional-user-validation-failed', function() {
        // Disable the button that require additional user validation
        _this.disableButton(_this.additionalValidationButton());
      });

      // When the additional user validation passes
      $('form').on('item-selector:additional-user-validation-passed', function() {
        // And there is an item selected
        if(_this.anItemIsSelected()) {
          // Enable the button that require additional user validations
          _this.enableButton(_this.additionalValidationButton());
        }
      });

    },

    anItemIsSelected: function() {
      if(this.checkboxes().length === 0) {
        return true; // Single item scenario
      } else {
        return this.numberOfSelectedCheckboxes() > 0;
      }
    },

    enableButton: function(button) {
      button.prop('disabled', false);
      button.removeClass('disabled');
      button.closest('form').unbind('submit.disabled-button');
    },

    disableButton: function(button) {
      button.prop('disabled', true);
      button.addClass('disabled');
      button.closest('form').on('submit.disabled-button', function(e) {
        if(button.is(':visible')) {
          e.preventDefault();
        }
      });
    },

    noAdditionalValidationButton: function() {
      return $('[data-additional-user-validation="false"]');
    },

    additionalValidationButton: function() {
      return $('[data-additional-user-validation="true"]');
    },

    submitButtons: function() {
      return $(':submit');
    }
  });
})();

requestFormValidator.init();
