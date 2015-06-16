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
        _this.addBreadcrumbBehavior();
      });
    },

    addBreadcrumbBehavior: function() {
      var _this = this;
      _this.checkboxes().each(function() {
        $(this).on('item-selector:selected', function() {
          _this.addBreadcrumb($(this));
        });

        $(this).on('item-selector:deselected', function() {
          _this.removeBreadcrumb($(this));
        });
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
      pill.find('.close').on('click', function() {
        item.prop('checked', false)
            .trigger('item-selector:deselected');
      });
    },

    breadcrumbContainer: function() {
      return $('[data-behavior="breadcrumb-container"]');
    }
  });
})();

itemSelectorBreadcrumbs.init();
