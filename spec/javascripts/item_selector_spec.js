const itemSelector = require('../../app/assets/javascripts/item_selector.js');

const fixture = readFixtures('no_limit_item_selector.html');

describe('Item Selector', () => {
  beforeEach(() => {
    document.body.innerHTML = fixture;
  });
  describe('selectorElement()', () => {
    it('returns the item selector element', () => {
      expect(
        itemSelector.selectorElement().length
      ).toBe(1);
    });
  });

  describe('checkboxes()', () => {
    it('returns the list of checkboxes in the item selector', () => {
      expect(
        itemSelector.checkboxes().length
      ).toBe(9);
    });
  });

  describe('numberOfSelectedCheckboxes()', () => {
    it('returns the number of checked checkboxes', () => {
      expect(itemSelector.numberOfSelectedCheckboxes()).toBe(0);
      itemSelector.checkboxes()
                  .first()
                  .prop('checked', true);
      itemSelector.checkboxes()
                  .last()
                  .prop('checked', true);
      expect(itemSelector.numberOfSelectedCheckboxes()).toBe(2);
    });
    it('returns the data attribute from the selector', () => {
      expect(itemSelector.numberOfSelectedCheckboxes()).toBe(0);
      itemSelector.selectorElement().data('selected-items', 2);
      expect(itemSelector.numberOfSelectedCheckboxes()).toBe(2);
    });
  });
});
