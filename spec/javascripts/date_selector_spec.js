const dateSelector = require('../../app/javascript/date_selector.js');

const fixture = readFixtures('date_selector.html');

describe('Date Selector', () => {
  beforeEach(() => {
    document.body.innerHTML = fixture;
  });

  describe('setDateFieldAsValid()', () => {
    it('it removes the error class from the parent form-group and the error message', () => {
      var formGroup = dateSelector.mediatedDateField().closest('.form-group');
      formGroup.addClass('has-error');
      expect(formGroup[0]).toHaveClass('has-error');
      dateSelector.setDateFieldAsValid();
      expect(formGroup[0]).not.toHaveClass('has-error');
      expect(dateSelector.mediatedDateField().siblings('.help-block').length).toBe(0);
      expect(dateSelector.mediatedDateWarning().text()).toBe('');
    });
  });

  describe('setDateFieldAsInvalid()', () => {
    it('it adds the error class from the parent form-group', () => {
      dateSelector.mediatedDateField().val('2016-01-01');
      var formGroup = dateSelector.mediatedDateField().closest('.form-group');
      expect(formGroup[0]).not.toHaveClass('has-error');
      dateSelector.setDateFieldAsInvalid();
      expect(formGroup[0]).toHaveClass('has-error');
      expect(dateSelector.mediatedDateWarning().text()).toBe('This library is not open on 2016-01-01');
    });
  });

  describe('setMinDate()', () => {
    it('sets the min attribute of the input', () => {
      expect(dateSelector.mediatedDateField().attr('min')).toBeUndefined();
      dateSelector.setMinDate('2016-01-01');
      expect(dateSelector.mediatedDateField().attr('min')).toBe('2016-01-01');
    });
  });

  describe('selectedDate()', () => {
    it('gets the value of the date field', () => {
      dateSelector.mediatedDateField().val('2015-01-01');
      expect(dateSelector.selectedDate()).toBe('2015-01-01');
    });
  });

  describe('mediatedDateField()', () => {
    it('exists', () => {
      expect(dateSelector.mediatedDateField().length).toBe(1);
    });
  });
});
