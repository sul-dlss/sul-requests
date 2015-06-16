//= require item_selector/item_selector_breadcrumbs
//= require jasmine-jquery

fixture.preload('no_limit_item_selector.html');

describe('Item Selector Breadcrumbs', function() {
  beforeAll(function() {
    this.fixtures = fixture.load('no_limit_item_selector.html');
  });

  describe('breadcrumbContainer()', function() {
    it('is present', function() {
      expect(itemSelectorBreadcrumbs.breadcrumbContainer().length).toBe(1);
    });
  });

  describe('addBreadcrumb()', function() {
    it('adds the breadcrumb pill', function() {
      expect(
        itemSelectorBreadcrumbs.breadcrumbContainer()
                               .find('.breadcrumb-pill')
                               .length
      ).toBe(0);
      var firstCheckbox = itemSelectorBreadcrumbs.checkboxes().first();
      itemSelectorBreadcrumbs.addBreadcrumb(firstCheckbox);
      expect(
        itemSelectorBreadcrumbs.breadcrumbContainer()
                               .find('.breadcrumb-pill')
                               .length
      ).toBe(1);
    });

    it('adds remove behavior to the pill', function() {
      itemSelectorBreadcrumbs.addBreadcrumbBehavior();
      var firstCheckbox = itemSelectorBreadcrumbs.checkboxes().first();
      firstCheckbox.prop('checked', true);
      itemSelectorBreadcrumbs.addBreadcrumb(firstCheckbox);

      itemSelectorBreadcrumbs.breadcrumbContainer()
                             .find('.breadcrumb-pill .close')
                             .trigger('click');
      expect(
        itemSelectorBreadcrumbs.breadcrumbContainer()
                               .find('.breadcrumb-pill')
                               .length
      ).toBe(0);

      expect(firstCheckbox.prop('checked')).toBe(false);
    });
  });

  describe('removeBreadcrumb()', function() {
    it('removes the breadcrumb element', function() {
      var firstCheckbox = itemSelectorBreadcrumbs.checkboxes().first();
      itemSelectorBreadcrumbs.addBreadcrumb(firstCheckbox);

      expect(
        itemSelectorBreadcrumbs.breadcrumbContainer()
                               .find('.breadcrumb-pill')
                               .length
      ).toBe(1);
      itemSelectorBreadcrumbs.removeBreadcrumb(firstCheckbox);

      expect(
        itemSelectorBreadcrumbs.breadcrumbContainer()
                               .find('.breadcrumb-pill')
                               .length
      ).toBe(0);
    });
  });
});
