var itemSelectorBreadcrumbs = (function() {

  var breadcrumbTemplate = function(item) {
    var barcode = item.data('barcode');
    var callnumber = item.data('callnumber');
    return $([
      '<div id="breadcrumb-' + barcode + '" class="breadcrumb-pill">',
        callnumber,
        '<div class="pill-addon">',
          '<button type="button" class="close" aria-label="Close">',
            '<span aria-hidden="true">&times;</span>',
          '</button>',
        '</div>',
      '</div>'
    ].join('\n'));
  };

  return $.extend(itemSelector, {
    init: function() {
      var _this = this;
      $(document).on('ready page:load', function(){
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
           .on('item-selector:selected', function(event, item) {
             _this.addBreadcrumb(item);
      });

      _this.selectorElement()
           .on('item-selector:deselected', function(event, item) {
             _this.removeBreadcrumb(item);
      });
    },

    addBreadcrumb: function(item) {
      var pill = breadcrumbTemplate(item);
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
    },

    breadcrumbContainer: function() {
      return $('[data-behavior="breadcrumb-container"]');
    }
  });
})();

itemSelectorBreadcrumbs.init();
