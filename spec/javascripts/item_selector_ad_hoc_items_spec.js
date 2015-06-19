//= require item_selector/item_selector_ad_hoc_items
//= require jasmine-jquery

fixture.preload('ad_hoc_items_item_selector.html');

describe('Item Selector Ad-Hoc Items', function(){
  beforeAll(function() {
    this.fixtures = fixture.load('ad_hoc_items_item_selector.html');
  });

  describe('addItemsInput()', function() {
    it('is present', function() {
      expect(itemSelectorAdHocItems.addItemsInput().length).toBe(1);
    });
  });

  describe('addItemsButton()', function() {
    it('is present', function() {
      expect(itemSelectorAdHocItems.addItemsButton().length).toBe(1);
    });
  });

  describe('disableAddButtonOnMaxItems()', function() {
    it('disables the Add link when max items is reached', function() {
      expect(
        itemSelectorAdHocItems.addItemsButton().attr('class')
      ).not.toMatch('disabled');

      itemSelectorAdHocItems.disableAddButtonOnMaxItems();
      itemSelectorAdHocItems.selectorElement()
                            .trigger('item-selector:max-selected-reached');

      expect(
        itemSelectorAdHocItems.addItemsButton().attr('class')
      ).toMatch('disabled');
    });
  });

  describe('enableAddButtonOnDeselect()', function() {
    it('enables the Add link when an item is deselected', function() {
      itemSelectorAdHocItems.enableAddButtonOnDeselect();

      itemSelectorAdHocItems.addItemsButton().addClass('disabled');
      itemSelectorAdHocItems.selectorElement()
                            .trigger('item-selector:deselected');

      expect(
        itemSelectorAdHocItems.addItemsButton().attr('class')
      ).not.toMatch('disabled');
    });
  });
});
