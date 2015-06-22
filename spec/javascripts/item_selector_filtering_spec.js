//= require item_selector/item_selector_filtering
//= require jasmine-jquery

fixture.preload('no_limit_item_selector.html');

describe('Item Selector Filtering', function() {
  beforeAll(function() {
    this.fixtures = fixture.load('no_limit_item_selector.html');
  });

  describe('filterInput()', function() {
    it('is present', function() {
      expect(itemSelectorFiltering.filterInput()).toExist();
    });

    it('is an HTML input', function() {
      expect(itemSelectorFiltering.filterInput()).toEqual('input[type="text"]');
    });
  });

  describe('listPlugin()', function() {
    it('is present', function() {
      expect(itemSelectorFiltering.listPlugin()).toBeDefined();
    });

    it('is a List', function() {
      expect(itemSelectorFiltering.listPlugin()).toEqual(jasmine.any(List));
    });
  });
});
