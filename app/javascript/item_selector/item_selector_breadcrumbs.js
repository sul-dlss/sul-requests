import itemSelector from '../item_selector'

var itemSelectorBreadcrumbs = (function() {

  var breadcrumbTemplate = function(item, extraMarkup) {
    var barcode = item.data('barcode');
    var callnumber = item.data('callnumber');
    return $([
      '<div id="breadcrumb-' + barcode + '" class="breadcrumb-pill">',
        callnumber,
        extraMarkup,
        '<div class="pill-addon">',
          '<button type="button" class="close" aria-label="Close">',
            '<span aria-hidden="true">&times;</span>',
          '</button>',
        '</div>',
      '</div>'
    ].join('\n'));
  };

  return $.extend({}, itemSelector, {
    init: function() {
      var _this = this;
      $(document).on('turbo:load', function(){
        _this.setupDefaultBreadcrumbs();
        _this.addBreadcrumbBehavior();
      });
    },

    setupDefaultBreadcrumbs: function() {
      var _this = this;
      _this.checkboxes()
           .filter(':checked')
           .each(function() {
             _this.addBreadcrumb($(this));
           });
    },

    addBreadcrumbBehavior: function() {
      var _this = this;
      _this.selectorElement()
           .on('item-selector:selected', function(event, item, extraMarkup) {
             _this.addBreadcrumb(item, extraMarkup);
      });

      _this.selectorElement()
           .on('item-selector:deselected', function(event, item) {
             _this.removeBreadcrumb(item);
      });
    },

    addBreadcrumb: function(item, extraMarkup) {
      var pill = breadcrumbTemplate(item, extraMarkup);
      this.breadcrumbContainer().append(pill);
      this.addBreadcrumbRemoveBehavior(pill, item);
    },

    removeBreadcrumb: function(item) {
      this.breadcrumbContainer()
          .find('#breadcrumb-' + item.data('barcode'))
          .remove();
    },

    addBreadcrumbRemoveBehavior: function(pill, item) {
      var _this = this;
      pill.find('.close').on('click', function() {
        item.prop('checked', false);
        _this.selectorElement()
             .trigger('item-selector:deselected', [item]);
      });
    }
  });
})();

itemSelectorBreadcrumbs.init();

// Basic support of CommonJS module for import into test
if (typeof exports === "object") {
  module.exports = itemSelectorBreadcrumbs;
}
