//= require item_selector/item_selector_limit_message
//= require jasmine-jquery

fixture.preload('limited_item_selector.html');

describe('Item Selector Limit Message', function() {
  beforeAll(function() {
    this.fixtures = fixture.load('limited_item_selector.html');
  });

  describe('messageContainer()', function() {
    it('is present', function() {
      expect(
        itemSelectorLimitMessage.messageContainer().length
      ).toBe(1);
    });
  });

  describe('Adding/Removing Messages', function() {
    it('can toggle the messages', function() {
      expect($('#max-items-reached').length).toBe(0);
      itemSelectorLimitMessage.addMessage();
      expect($('#max-items-reached').length).toBe(1);

      expect(
        $('#max-items-reached p').first().text()
      ).toBe('You\'ve reached the maximum of 4 items per day.');

      itemSelectorLimitMessage.removeMessage();

      expect($('#max-items-reached').length).toBe(0);
    });
  });

});
