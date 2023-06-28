import itemSelector from "../../app/assets/javascripts/item_selector.js"
global.itemSelector = itemSelector;
const itemSelectorActive = require('../../app/assets/javascripts/item_selector/item_selector_active.js');

const fixture = readFixtures('input_group_selector.html');

describe('Item Selector Active Behavior', () => {
  beforeEach(() => {
    document.body.innerHTML = fixture;
  });

  describe('addActive()', () => {
    it('adds the active class to the row', () => {
      var firstCheckbox = itemSelectorActive.checkboxes().first();

      itemSelectorActive.addActive(firstCheckbox);
      expect(
        firstCheckbox.closest('.input-group.active').length
      ).toBe(1);
    });
  });

  describe('removeActive()', () => {
    it('removes the active class from the row', () => {
      var firstCheckbox = itemSelectorActive.checkboxes().first();

      itemSelectorActive.addActive(firstCheckbox);

      expect(
        firstCheckbox.closest('.input-group.active').length
      ).toBe(1);

      itemSelectorActive.removeActive(firstCheckbox);

      expect(
        firstCheckbox.closest('.input-group.active').length
      ).toBe(0);
    });
  });
});
