const itemSelector = require('../../app/javascript/item_selector.js');
global.itemSelector = itemSelector;
const itemSelectorFiltering = require('../../app/javascript/item_selector/item_selector_filtering.js');
import List from 'list.js'
const fixture = readFixtures('no_limit_item_selector.html');

describe('Item Selector Filtering', () => {
  beforeEach(() => {
    document.body.innerHTML = fixture;
  });

  describe('filterInput()', () => {
    it('is present', () => {
      expect(itemSelectorFiltering.filterInput().length).toBe(1);
    });

    it('is an HTML input', () => {
      expect(itemSelectorFiltering.filterInput()[0]).toContainHTML('<input type="text"');
    });
  });

  describe('listPlugin()', () => {
    it('is present', () => {
      expect(itemSelectorFiltering.listPlugin()).toBeDefined();
    });

    it('is a List', () => {
      expect(itemSelectorFiltering.listPlugin()).toEqual(jasmine.any(List));
    });
  });
});
