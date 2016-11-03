//= require 'item_selector/item_selector_breadcrumbs'

var itemSelectorAdHocItems = (function() {
  var defaultOptions = {
    selector: '[data-behavior="ad-hoc-items"]'
  };

  var sanitizeValue = function(val) {
    return val.replace(/\W+/g, '');
  };

  var adHocItemTemplate = function(value) {
    var barcode = sanitizeValue(value);

    return $(
      '<span data-barcode="' +
        barcode +
      '" data-callnumber="' +
        value +
      '"></span>'
    );
  };

  var adHochiddenFieldTemplate = function(name, value) {
    return '<input id="hidden-' + sanitizeValue(value) + '"' +
    'type="hidden" ' +
    'name="' + name + '" ' +
    'value="' + value + '" />';
  };

  return $.extend({}, itemSelector, {
    init: function(opts) {
      var _this = this;
      _this.adHocOptions = $.extend(defaultOptions, opts);
      $(document).on('turbolinks:load', function(){
        _this.addItemsBehavior();
        _this.setupDefaultBreadcrumbs();
        _this.enableAddButtonOnDeselect();
        _this.disableAddButtonOnMaxItems();
      });
    },

    setupDefaultBreadcrumbs: function() {
      var _this = this;
      _this.breadcrumbContainer()
           .find('input:hidden')
           .each(function() {
              _this.addItem($(this).val());
              $(this).remove();
            });
    },


    adHocOptions: {},

    addItemsBehavior: function() {
      var _this = this;
      _this.addItemsButton().on('click', function() {
        var value = _this.addItemsInput().val();
        _this.addItem(value);
        _this.addItemsInput().val('');
      });
    },

    addItem: function(value) {
      if ( value !== '') {
        var item = adHocItemTemplate(value);
        this.selectorElement()
            .trigger('item-selector:selected',
              [item, adHochiddenFieldTemplate(this.hiddenFieldName(), value)]);
      }
    },

    disableAddButtonOnMaxItems: function() {
      var _this = this;
      _this.selectorElement()
           .on('item-selector:max-selected-reached', function() {
             _this.addItemsButton().addClass('disabled');
           });
    },

    enableAddButtonOnDeselect: function() {
      var _this = this;
      _this.selectorElement().on('item-selector:deselected', function() {
        _this.addItemsButton().removeClass('disabled');
      });
    },

    addItemsInput: function() {
      return $(this.adHocOptions.selector).find('input[type="text"]');
    },

    hiddenFieldName: function() {
      return $(this.adHocOptions.selector).data('hidden-field-name');
    },

    addItemsButton: function() {
      return $(this.adHocOptions.selector).find(
        '[data-behavior="submit-ad-hoc-items"]'
      );
    }
  });
})();

itemSelectorAdHocItems.init();
