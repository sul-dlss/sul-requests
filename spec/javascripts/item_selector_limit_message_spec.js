const itemSelector = require('../../app/javascript/item_selector.js');
global.itemSelector = itemSelector;
const itemSelectorLimitMessage = require('../../app/javascript/item_selector/item_selector_limit_message.js');

const fixture = readFixtures('limited_item_selector.html');

describe('Item Selector Limit Message', () => {
  beforeEach(() => {
    document.body.innerHTML = fixture;
  });

  describe('messageContainer()', () => {
    it('is present', () => {
      expect(
        itemSelectorLimitMessage.messageContainer().length
      ).toBe(1);
    });
  });

  describe('Adding/Removing Messages', () => {
    it('can toggle the messages', () => {
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
