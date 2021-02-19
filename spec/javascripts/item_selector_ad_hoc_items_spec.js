const itemSelector = require('../../app/assets/javascripts/item_selector.js');
global.itemSelector = itemSelector;
const itemSelectorAdHocItems = require('../../app/assets/javascripts/item_selector/item_selector_ad_hoc_items.js');

const fixture = readFixtures('ad_hoc_items_item_selector.html');

describe('Item Selector Ad-Hoc Items', () =>{
  beforeEach(() => {
    document.body.innerHTML = fixture;
  });

  describe('addItemsInput()', () => {
    it('is present', () => {
      expect(itemSelectorAdHocItems.addItemsInput().length).toBe(1);
    });
  });

  describe('addItemsButton()', () => {
    it('is present', () => {
      expect(itemSelectorAdHocItems.addItemsButton().length).toBe(1);
    });
  });

  describe('disableAddButtonOnMaxItems()', () => {
    it('disables the Add link when max items is reached', () => {
      expect(
        itemSelectorAdHocItems.addItemsButton()[0]
      ).not.toHaveClass('disabled');

      itemSelectorAdHocItems.disableAddButtonOnMaxItems();
      itemSelectorAdHocItems.selectorElement()
                            .trigger('item-selector:max-selected-reached');

      expect(
        itemSelectorAdHocItems.addItemsButton()[0]
      ).toHaveClass('disabled');
    });
  });

  describe('enableAddButtonOnDeselect()', () => {
    it('enables the Add link when an item is deselected', () => {
      itemSelectorAdHocItems.enableAddButtonOnDeselect();

      itemSelectorAdHocItems.addItemsButton().addClass('disabled');
      itemSelectorAdHocItems.selectorElement()
                            .trigger('item-selector:deselected');

      expect(
        itemSelectorAdHocItems.addItemsButton()[0]
      ).not.toHaveClass('disabled');
    });
  });
});
