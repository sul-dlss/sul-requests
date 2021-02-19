const itemSelector = require('../../app/assets/javascripts/item_selector.js');
global.itemSelector = itemSelector;
const itemSelectorZeroMessage = require('../../app/assets/javascripts/item_selector/item_selector_zero_message.js');

const fixture = readFixtures('limited_item_selector.html');

describe('Item Selector Zero Message', () => {
  beforeEach(() => {
    document.body.innerHTML = fixture;
  });

  describe('zeroMessageContainer()', () => {
    it('is present', () => {
      expect(
        itemSelectorZeroMessage.zeroMessageContainer().length
      ).toBe(1);
    });
  });

  describe('Adding/Removing Messages', () => {
    it('can toggle the messages', () => {
      expect(document.querySelector('.zero-items-message')).toBeVisible();
      itemSelectorZeroMessage.removeZeroMessage();
      expect(document.querySelector('.zero-items-message')).not.toBeVisible();
      itemSelectorZeroMessage.addZeroMessage();
      expect(document.querySelector('.zero-items-message')).toBeVisible();
    });
  });

});
