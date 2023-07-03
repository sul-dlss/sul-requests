import itemSelector from "../../app/assets/javascripts/item_selector.js"
global.itemSelector = itemSelector;
const itemSelectorIncrementor = require('../../app/assets/javascripts/item_selector/item_selector_incrementor.js');

const fixture = readFixtures('no_limit_item_selector.html');


describe('Item Selector Incrementor', function() {
  beforeEach(() => {
    document.body.innerHTML = fixture;
  });

  describe('selectedItemCounter', function() {
    it('returns the item counter element', function() {
      var counter = itemSelectorIncrementor.selectedItemCounter();
      expect(counter.length).toBe(1);
      expect(counter.text()).toBe('0');
    });
  });

  describe('input change event', function() {
    it('adds and removes from the selected item count', function() {
      var firstCheckbox = itemSelectorIncrementor.checkboxes().first();
      itemSelectorIncrementor.addIncrementBehavior();
      expect($('[data-items-counter]').text()).toBe('0 items selected');
      firstCheckbox.trigger('item-selector:selected');
      expect($('[data-items-counter]').text()).toBe('1 items selected');
      firstCheckbox.trigger('item-selector:deselected');
      expect($('[data-items-counter]').text()).toBe('0 items selected');
    });

  });

  describe('count changing', function() {
    it('adds and removes from the selected item count', function() {
      expect($('[data-items-counter]').text()).toBe('0 items selected');
      itemSelectorIncrementor.increaseSelectedItemCount();
      expect($('[data-items-counter]').text()).toBe('1 items selected');
      itemSelectorIncrementor.decreaseSelectedItemCount();
      expect($('[data-items-counter]').text()).toBe('0 items selected');
    });
  });

  describe('setting the default selected number (for cache)', function() {
    it('sets the item counter properly', function() {
      expect($('[data-items-counter]').text()).toBe('0 items selected');
      itemSelectorIncrementor.checkboxes().first().prop('checked', true);
      itemSelectorIncrementor.setDefaultItemCounter();
      expect($('[data-items-counter]').text()).toBe('1 items selected');
    });
  });
});
