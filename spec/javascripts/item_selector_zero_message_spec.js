//= require item_selector/item_selector_zero_message
//= require jasmine-jquery

fixture.preload('limited_item_selector.html');

describe('Item Selector Zero Message', function() {
  beforeAll(function() {
    this.fixtures = fixture.load('limited_item_selector.html');
    itemSelectorZeroMessage.init();
  });

  describe('zeroMessageContainer()', function() {
    it('is present', function() {
      expect(
        itemSelectorZeroMessage.zeroMessageContainer().length
      ).toBe(1);
    });
  });

  describe('Adding/Removing Messages', function() {
    it('can toggle the messages', function() {
      expect($('.zero-items-message:visible').length).toBe(1);
      itemSelectorZeroMessage.removeZeroMessage();
      expect($('.zero-items-message:visible').length).toBe(0);
      itemSelectorZeroMessage.addZeroMessage();
      expect($('.zero-items-message:visible').length).toBe(1);
    });
  });

});
