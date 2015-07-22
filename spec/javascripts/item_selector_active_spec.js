//= require item_selector/item_selector_active
//= require jasmine-jquery

fixture.preload('input_group_selector.html');

describe('Item Selector Active Behavior', function() {
  beforeAll(function() {
    this.fixtures = fixture.load('input_group_selector.html');
  });

  describe('addActive()', function() {
    it('adds the active class to the row', function() {
      var firstCheckbox = itemSelectorBreadcrumbs.checkboxes().first();
      itemSelectorBreadcrumbs.addActive(firstCheckbox);
      expect(
        firstCheckbox.closest('.input-group.active').length
      ).toBe(1);
    });
  });

  describe('removeActive()', function() {
    it('removes the active class from the row', function() {
      var firstCheckbox = itemSelectorBreadcrumbs.checkboxes().first();

      itemSelectorBreadcrumbs.addActive(firstCheckbox);

      expect(
        firstCheckbox.closest('.input-group.active').length
      ).toBe(1);

      itemSelectorBreadcrumbs.removeActive(firstCheckbox);

      expect(
        firstCheckbox.closest('.input-group.active').length
      ).toBe(0);
    });
  });
});
