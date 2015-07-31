//= require item_selector/item_selector_zero_disable_submit
//= require jasmine-jquery

fixture.preload('limited_item_selector.html');

describe('Item Selector Zero Disable Submit', function() {
  beforeAll(function() {
    this.fixtures = fixture.load('limited_item_selector.html');
  });

  describe('Toggling the submit button', function() {
    it('can toggle the messages', function() {
      var f = $(this.fixtures[0]);
      itemSelectorZeroDisableSubmit.enableSubmit();
      expect(itemSelectorZeroDisableSubmit.submitButton().is(':enabled')).toBe(true);
      itemSelectorZeroDisableSubmit.disableSubmit();
      expect(itemSelectorZeroDisableSubmit.submitButton().is(':enabled')).toBe(false);
    });
  });

});
