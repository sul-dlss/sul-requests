//= require item_selector/item_selector_limit
//= require jasmine-jquery

fixture.preload('limited_item_selector.html');

describe('Item Selector', function() {
  beforeAll(function() {
    this.fixtures = fixture.load('limited_item_selector.html');
  });

  describe('setupDefaults()', function() {
    it('sets the default based on the numberOfSelectedCheckboxes', function() {
      itemSelectorLimit.setupDefaults();
      expect(
        itemSelectorLimit.selectorElement().data('selected-items')
      ).toBe(0);

      itemSelectorLimit.checkboxes().first().prop('checked', true);

      itemSelectorLimit.setupDefaults();
      expect(
        itemSelectorLimit.selectorElement().data('selected-items')
      ).toBe(1);
    });
  });

  describe('enforceSelectedItemLimit()', function() {
    it('disables selection if the limit has been passed', function() {
      itemSelectorLimit.checkboxes().filter(':nth-child(1)').trigger('click');
      itemSelectorLimit.checkboxes().filter(':nth-child(2)').trigger('click');
      itemSelectorLimit.checkboxes().filter(':nth-child(3)').trigger('click');
      expect(itemSelectorLimit.checkboxes().filter(':checked').length).toBe(3);

      var fourthCheckbox = itemSelectorLimit.checkboxes()
                                            .filter(':nth-child(4)');
      spyOnEvent(fourthCheckbox, 'click');
      fourthCheckbox.('click')
      expect('click').toHaveBeenPreventedOn(fourthCheckbox)
      expect(itemSelectorLimit.checkboxes().filter(':checked').length).toBe(3);

      itemSelectorLimit.checkboxes().filter(':nth-child(3)').trigger('click');
      expect(itemSelectorLimit.checkboxes().filter(':checked').length).toBe(2);
      fourthCheckbox.('click')
      expect(itemSelectorLimit.checkboxes().filter(':checked').length).toBe(3);
    });

  });

  describe('increaseSelectedNumber() and decreaseSelectedNumber()', function() {
    beforeEach(function() { itemSelectorLimit.setupDefaults(); });
    it('increases and decreases the number in the data attribute', function() {
      expect(
        itemSelectorLimit.selectorElement().data('selected-items')
      ).toBe(0);

      itemSelectorLimit.increaseSelectedNumber();

      expect(
        itemSelectorLimit.selectorElement().data('selected-items')
      ).toBe(1);

      itemSelectorLimit.decreaseSelectedNumber();

      expect(
        itemSelectorLimit.selectorElement().data('selected-items')
      ).toBe(0);
    });
  });
});
