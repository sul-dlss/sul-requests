//= require date_selector
//= require jasmine-jquery

fixture.preload('date_selector.html');

describe('Date Selector', function() {
  beforeAll(function() {
    this.fixtures = fixture.load('date_selector.html');
  });

  describe('setDateFieldAsValid()', function() {
    it('it removes the error class from the parent form-group', function() {
      var formGroup = dateSelector.mediatedDateField().closest('.form-group');
      formGroup.addClass('has-error');
      expect(formGroup).toHaveClass('has-error');
      dateSelector.setDateFieldAsValid();
      expect(formGroup).not.toHaveClass('has-error');
    });
  });

  describe('setDateFieldAsInvalid()', function() {
    it('it adds the error class from the parent form-group', function() {
      dateSelector.mediatedDateField().val('2016-01-01');
      var formGroup = dateSelector.mediatedDateField().closest('.form-group');
      expect(formGroup).not.toHaveClass('has-error');
      dateSelector.setDateFieldAsInvalid();
      expect(formGroup).toHaveClass('has-error');
    });
  });

  describe('restrictToOpenDates()', function() {
    it('is invalid when the date is not in the given dates', function() {
      var formGroup = dateSelector.mediatedDateField().closest('.form-group');
      dateSelector.restrictToOpenDates(
        ['2016-01-01', '2016-01-02', '2016-01-03']
      );
      expect(formGroup).not.toHaveClass('has-error');
      dateSelector.mediatedDateField().val('2016-01-04').trigger('change');
      expect(formGroup).toHaveClass('has-error');
    });

    it('is valid when the date is in the given dates', function() {
      var formGroup = dateSelector.mediatedDateField().closest('.form-group');
      formGroup.addClass('has-error');
      dateSelector.restrictToOpenDates(
        ['2016-01-01', '2016-01-02', '2016-01-03']
      );
      expect(formGroup).toHaveClass('has-error');
      dateSelector.mediatedDateField().val('2016-01-03').trigger('change');
      expect(formGroup).not.toHaveClass('has-error');
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
