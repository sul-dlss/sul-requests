//= require additional_form_validation
//= require jasmine-jquery

fixture.preload('additional_form_validation_elements.html');

describe('Additional Form Validation', function() {
  beforeAll(function() {
    this.fixtures = fixture.load('additional_form_validation_elements.html');
  });

  describe('buttonWrapper()', function() {
    it('returns the div wrapping the button', function() {
      expect(additionalFormValidation.buttonWrapper()).toExist();
    });
  });

  describe('submitButtons()', function() {
    it('returns the submit button', function() {
      expect(additionalFormValidation.submitButtons()).toExist();
    });
  });

  describe('singleUserFields()', function() {
    it('returns the single user field', function() {
      expect(additionalFormValidation.singleUserFields()).toExist();
      expect(additionalFormValidation.singleUserFields().length).toBe(1);
    });
  });

  describe('groupedUserFields()', function() {
    it('returns the grouped user fields', function() {
      expect(additionalFormValidation.groupedUserFields()).toExist();
      expect(additionalFormValidation.groupedUserFields().length).toBe(2);
    });
  });

  describe('enableButton()', function() {
    it('removes the disabled class', function() {
      additionalFormValidation.submitButtons().addClass('disabled');
      additionalFormValidation.enableButton();
      expect(additionalFormValidation.submitButtons()).not.toHaveClass('disabled');
    });
  });

  describe('disableButton()', function() {
    it('adds the disabled class', function() {
      expect(additionalFormValidation.submitButtons()).not.toHaveClass('disabled');
      additionalFormValidation.disableButton();
      expect(additionalFormValidation.submitButtons()).toHaveClass('disabled');
    });

    it('adds the tooltip to the wrapper', function() {
      expect(additionalFormValidation.buttonWrapper().data('toggle')).not.toExist();
      additionalFormValidation.disableButton();
      expect(additionalFormValidation.buttonWrapper().data('toggle')).toBe('tooltip');
    });
  });

  describe('fieldsAreValid()', function() {
    it('returns true when the single user field is filled out', function() {
      expect(additionalFormValidation.fieldsAreValid()).toBe(false);
      $('#input1').val('Some ID');
      expect(additionalFormValidation.fieldsAreValid()).toBe(true);
    });

    it('returns true when all the grouped fields are filled out', function() {
      expect(additionalFormValidation.fieldsAreValid()).toBe(false);
      $('#input2').val('Some name');
      expect(additionalFormValidation.fieldsAreValid()).toBe(false);
      $('#input3').val('some@email.com');
      expect(additionalFormValidation.fieldsAreValid()).toBe(true);
    });
  });

});
