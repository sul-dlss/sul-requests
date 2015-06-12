//= require item_selector
//= require jasmine-jquery

fixture.preload('no_limit_item_selector.html');

describe('Item Selector', function() {
  beforeAll(function() {
    this.fixtures = fixture.load('no_limit_item_selector.html');
  });
  describe('selectorElement()', function() {
    it('returns the item selector element', function() {
      expect(
        itemSelector.selectorElement().length
      ).toBe(1);
    });
  });

  describe('checkboxes()', function() {
    it('returns the list of checkboxes in the item selector', function() {
      expect(
        itemSelector.checkboxes().length
      ).toBe(9);
    });
  });

  describe('numberOfSelectedCheckboxes()', function() {
    it('returns the number of checked checkboxes', function() {
      expect(itemSelector.numberOfSelectedCheckboxes()).toBe(0);
      itemSelector.checkboxes()
                  .first()
                  .prop('checked', true);
      itemSelector.checkboxes()
                  .last()
                  .prop('checked', true);
      expect(itemSelector.numberOfSelectedCheckboxes()).toBe(2);
    });
    it('returns the data attribute from the selector', function() {
      expect(itemSelector.numberOfSelectedCheckboxes()).toBe(0);
      itemSelector.selectorElement().data('selected-items', 2);
      expect(itemSelector.numberOfSelectedCheckboxes()).toBe(2);
    });
  });
});
