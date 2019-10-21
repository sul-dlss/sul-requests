//= require additional_user_validation_fields
//= require jasmine-jquery

fixture.preload('additional_user_validation_fields_elements.html');
fixture.preload('additional_user_validation_fields_single_input_elements.html');

describe('Additional User Validation Fields', function() {
  describe('singleUserFields()', function() {
    beforeAll(function() {
      this.fixtures = fixture.load('additional_user_validation_fields_single_input_elements.html');
    });

    it('returns the single user field', function() {
      expect(additionalUserValidationFields.singleUserFields()).toExist();
      expect(additionalUserValidationFields.singleUserFields().length).toBe(1);
    });

    describe('fieldsAreValid()', function() {
      it('returns true when the single user field is filled out', function() {
        expect(additionalUserValidationFields.fieldsAreValid()).toBe(false);
        expect($('#input1')[0].checkValidity()).toBe(true)

        $('#input1').val('Some ID');
        expect(additionalUserValidationFields.fieldsAreValid()).toBe(true);
        expect($('#input1')[0].checkValidity()).toBe(false)
      });

      it('sets the custom validity on the element when there is a minwidth set', () => {
        $('#input1').val('123');
        additionalUserValidationFields.fieldsAreValid();
        expect($('#input1')[0].checkValidity()).toBe(false)
        $('#input1').val('0123456789');
        additionalUserValidationFields.fieldsAreValid();
        expect($('#input1')[0].checkValidity()).toBe(true)
      });
    });
  });

  describe('groupedUserFields()', function() {
    beforeAll(function() {
      this.fixtures = fixture.load('additional_user_validation_fields_elements.html');
    });

    describe('buttonWrapper()', function() {
      it('returns the div wrapping the button', function() {
        expect(additionalUserValidationFields.buttonWrapper()).toExist();
      });
    });

    describe('submitButtons()', function() {
      it('returns the submit button', function() {
        expect(additionalUserValidationFields.submitButtons()).toExist();
      });
    });

    it('returns the grouped user fields', function() {
      expect(additionalUserValidationFields.groupedUserFields()).toExist();
      expect(additionalUserValidationFields.groupedUserFields().length).toBe(2);
    });

    describe('fieldsAreValid()', () => {
      it('returns true when all the grouped fields are filled out', function() {
        expect(additionalUserValidationFields.fieldsAreValid()).toBe(false);
        $('#input2').val('Some name');
        expect(additionalUserValidationFields.fieldsAreValid()).toBe(false);
        $('#input3').val('some@email.com');
        expect(additionalUserValidationFields.fieldsAreValid()).toBe(true);
      });
    });
  });
});
