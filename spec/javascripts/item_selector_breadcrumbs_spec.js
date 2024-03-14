const itemSelector = require('../../app/javascript/item_selector.js');
global.itemSelector = itemSelector;
const itemSelectorBreadcrumbs = require('../../app/javascript/item_selector/item_selector_breadcrumbs.js');

const fixture = readFixtures('no_limit_item_selector.html');

describe('Item Selector Breadcrumbs', () => {
  beforeEach(() => {
    document.body.innerHTML = fixture;
  });

  describe('breadcrumbContainer()', () => {
    it('is present', () => {
      expect(itemSelectorBreadcrumbs.breadcrumbContainer().length).toBe(1);
    });
  });

  describe('addBreadcrumb()', () => {
    it('adds the breadcrumb pill', () => {
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

    it('adds remove behavior to the pill', () => {
      itemSelectorBreadcrumbs.addBreadcrumbBehavior();
      var firstCheckbox = itemSelectorBreadcrumbs.checkboxes().first();
      firstCheckbox.prop('checked', true);
      itemSelectorBreadcrumbs.addBreadcrumb(firstCheckbox);

      itemSelectorBreadcrumbs.breadcrumbContainer()
                             .find('.breadcrumb-pill .btn-close')
                             .trigger('click');
      expect(
        itemSelectorBreadcrumbs.breadcrumbContainer()
                               .find('.breadcrumb-pill')
                               .length
      ).toBe(0);

      expect(firstCheckbox.prop('checked')).toBe(false);
    });
  });

  describe('removeBreadcrumb()', () => {
    it('removes the breadcrumb element', () => {
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
