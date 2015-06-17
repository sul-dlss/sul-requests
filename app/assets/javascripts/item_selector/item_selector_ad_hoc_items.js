var itemSelectorAdHocItems = (function() {
  var defaultOptions = {
    selector: '[data-behavior="ad-hoc-items"]'
  };

  var santizeCallnumber = function(callnumber) {
    return callnumber.replace(/\W+/g, '');
  };

  var adHocItemTemplate = function(value) {
    return $(
      '<span data-barcode="' +
        santizeCallnumber(value) +
      '" data-callnumber="' +
        value +
      '"></span>'
    );
  };

  var adHochiddenFieldTemplate = function(item, fieldName) {
    return $(
      '<input id="hidden-' + item.data('barcode') + '" ' +
      'type="hidden" ' +
      'name="' + fieldName + '" ' +
      'value="' + item.data('callnumber') + '" />'
    );
  };

  return $.extend(itemSelector, {
    init: function(opts) {
      var _this = this;
      _this.adHocOptions = $.extend(defaultOptions, opts);
      $(document).on('ready page:load', function(){
        _this.addItemsBehavior();
        _this.enableAddButtonOnDeselect();
        _this.disableAddButtonOnMaxItems();
      });
    },

    adHocOptions: {},

    addItemsBehavior: function() {
      var _this = this;
      _this.addItemsButton().on('click', function() {
        var value = _this.addItemsInput().val();
        if ( value !== '') {
          var item = adHocItemTemplate(value);
          _this.selectorElement()
               .trigger('item-selector:selected', [item]);
          _this.addHiddenAdHocField(item);
          _this.addAdditionalRemoveBreadcrumbBehavior(item);
          _this.addItemsInput().val('');
        }
      });
    },

    addAdditionalRemoveBreadcrumbBehavior: function(item) {
      var barcode = item.data('barcode');
      $('#breadcrumb-' + barcode)
        .find('.close').on('click', function() {
          $('#hidden-' + barcode).remove();
      });
    },

    addHiddenAdHocField: function(item) {
      var _this = this;
      _this.breadcrumbContainer().append(
        adHochiddenFieldTemplate(item, _this.hiddenFieldName())
      );
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
