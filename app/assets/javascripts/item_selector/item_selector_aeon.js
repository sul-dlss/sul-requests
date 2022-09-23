var itemSelectorAeon = (function () {

  return $.extend({}, itemSelector, {
    init: function () {
      var _this = this;
      $(document).on('turbolinks:load', function () {
        _this.setupDefaultAeonFields();
        _this.addAeonBehavior();
      });
    },

    setupDefaultAeonFields: function () {
      var _this = this;
      _this.checkboxes()
           .filter(':checked')
           .each(function () {
             _this.enableAeonFields($(this));
           });
    },

    addAeonBehavior: function () {
      var _this = this;
      _this.selectorElement()
        .on('item-selector:selected', function (event, item) {
          _this.enableAeonFields(item);
        });

      _this.selectorElement()
        .on('item-selector:deselected', function (event, item) {
          _this.disableAeonFields(item);
        });
    },

    // we disable/enable additional hidden inputs used to send information to
    // Aeon, which are required when submitting requests to the external request
    // endpoint. each checkbox has two additional hidden inputs, one for the
    // associated barcode and one that tracks the index of the request, which
    // must exist when submitting multiple requests at once.

    enableAeonFields: function (item) {
      item.nextAll('.aeon_barcode').prop('disabled', false);
      item.nextAll('.aeon_request_index').prop('disabled', false);
    },

    disableAeonFields: function (item) {
      item.nextAll('.aeon_barcode').prop('disabled', true);
      item.nextAll('.aeon_request_index').prop('disabled', true);
    }
  });
})();

itemSelectorAeon.init();

// Basic support of CommonJS module for import into test
if (typeof exports === "object") {
  module.exports = itemSelectorAeon;
}
