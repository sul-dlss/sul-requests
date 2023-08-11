const itemSelector = require('../../app/assets/javascripts/item_selector.js');
global.itemSelector = itemSelector;
const itemSelectorLimit = require('../../app/assets/javascripts/item_selector/item_selector_limit.js');

const fixture = readFixtures('limited_item_selector.html');

describe('Item Selector', () => {
  beforeEach(() => {
    document.body.innerHTML = fixture;
    itemSelector.init();
    itemSelectorLimit.init();
    $(document).trigger('turbolinks:load');
  });
  afterEach(() => {
    $(document).off(); // reset listeners between the tests
  });

  describe('setupDefaults()', () => {
    it('sets the default based on the numberOfSelectedCheckboxes', () => {
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

  describe('enforceSelectedItemLimit()', () => {
    it('disables selection if the limit has been passed', () => {
      itemSelectorLimit.checkboxes().filter(':nth-child(1)').trigger('click');
      itemSelectorLimit.checkboxes().filter(':nth-child(2)').trigger('click');
      itemSelectorLimit.checkboxes().filter(':nth-child(3)').trigger('click');
      expect(itemSelectorLimit.checkboxes().filter(':checked').length).toBe(3);

      const fourthCheckbox = itemSelectorLimit.checkboxes()
                                            .filter(':nth-child(4)');
      fourthCheckbox.trigger('click') // makes no change because we're over the threshold
      expect(itemSelectorLimit.checkboxes().filter(':checked').length).toBe(3);

      // Uncheck the third one so we're under the threshold
      itemSelectorLimit.checkboxes().filter(':nth-child(3)').trigger('click');
      expect(itemSelectorLimit.checkboxes().filter(':checked').length).toBe(2);
      fourthCheckbox.trigger('click') // Increments the number checked as we were under the threshold
      expect(itemSelectorLimit.checkboxes().filter(':checked').length).toBe(3);
    });

  });

  describe('increaseSelectedNumber() and decreaseSelectedNumber()', () => {
    beforeEach(() => { itemSelectorLimit.setupDefaults(); });
    it('increases and decreases the number in the data attribute', () => {
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
