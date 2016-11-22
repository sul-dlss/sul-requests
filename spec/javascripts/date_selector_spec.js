//= require date_selector
//= require jasmine-jquery

fixture.preload('date_selector.html');

describe('Date Selector', function() {
  beforeAll(function() {
    this.fixtures = fixture.load('date_selector.html');
  });

  describe('setDateFieldAsValid()', function() {
    it('it removes the error class from the parent form-group and the error message', function() {
      var formGroup = dateSelector.mediatedDateField().closest('.form-group');
      formGroup.addClass('has-error');
      expect(formGroup).toHaveClass('has-error');
      dateSelector.setDateFieldAsValid();
      expect(formGroup).not.toHaveClass('has-error');
      expect(dateSelector.mediatedDateField().siblings('.help-block').length).toBe(0);
      expect(dateSelector.mediatedDateWarning().text()).toBe('');
    });
  });

  describe('setDateFieldAsInvalid()', function() {
    it('it adds the error class from the parent form-group', function() {
      dateSelector.mediatedDateField().val('2016-01-01');
      var formGroup = dateSelector.mediatedDateField().closest('.form-group');
      expect(formGroup).not.toHaveClass('has-error');
      dateSelector.setDateFieldAsInvalid();
      expect(formGroup).toHaveClass('has-error');
      expect(dateSelector.mediatedDateWarning().text()).toBe('This library is not open on 2016-01-01');
    });
  });

  describe('setMinDate()', function() {
    it('sets the min attribute of the input', function() {
      expect(dateSelector.mediatedDateField().attr('min')).toBeUndefined();
      dateSelector.setMinDate('2016-01-01');
      expect(dateSelector.mediatedDateField().attr('min')).toBe('2016-01-01');
    });
  });

  describe('selectedDate()', function() {
    it('gets the value of the date field', function() {
      dateSelector.mediatedDateField().val('2015-01-01');
      expect(dateSelector.selectedDate()).toBe('2015-01-01');
    });
  });

  describe('mediatedDateField()', function() {
    it('exists', function() {
      expect(dateSelector.mediatedDateField()).toExist();
    });
  });
});
