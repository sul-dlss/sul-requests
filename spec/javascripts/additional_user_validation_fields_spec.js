const additionalUserValidationFields = require('../../app/javascript/additional_user_validation_fields.js');

const fixture_elements = readFixtures('additional_user_validation_fields_elements.html');
const fixture_single_input = readFixtures('additional_user_validation_fields_single_input_elements.html');

describe('Additional User Validation Fields', () => {
  describe('singleUserFields()', () => {
    beforeEach(() => {
      document.body.innerHTML = fixture_single_input;
    });

    it('returns the single user field', () => {
      expect(additionalUserValidationFields.singleUserFields().length).toBe(1);
    });

    describe('fieldsAreValid()', () => {
      it('returns true when the single user field is filled out', () => {
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

  describe('groupedUserFields()', () => {
    beforeEach(() => {
      document.body.innerHTML = fixture_elements;
    });

    describe('buttonWrapper()', () => {
      it('returns the div wrapping the button', () => {
        expect(additionalUserValidationFields.buttonWrapper().length).toBe(1);
      });
    });

    describe('submitButtons()', () => {
      it('returns the submit button', () => {
        expect(additionalUserValidationFields.submitButtons().length).toBe(1);
      });
    });

    it('returns the grouped user fields', () => {
      expect(additionalUserValidationFields.groupedUserFields().length).toBe(2);
    });

    describe('fieldsAreValid()', () => {
      it('returns true when all the grouped fields are filled out', () => {
        expect(additionalUserValidationFields.fieldsAreValid()).toBe(false);
        $('#input2').val('Some name');
        expect(additionalUserValidationFields.fieldsAreValid()).toBe(false);
        $('#input3').val('some@email.com');
        expect(additionalUserValidationFields.fieldsAreValid()).toBe(true);
      });
    });
  });
});
