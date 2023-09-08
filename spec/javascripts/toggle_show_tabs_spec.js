const toggleShowTabs = require('../../app/javascript/toggle_show_tabs.js');

const fixture = readFixtures('toggle_show_tabs.html');

describe('Toggling show tabs', function() {
  beforeEach(() => {
    document.body.innerHTML = fixture;
  });

  describe('addToggleBehavior()', function() {
    it('it allows the user to toggle back and forth between panes', function() {
      toggleShowTabs.addToggleBehavior();

      expect(document.querySelector('#thing-a')).toBeVisible();
      expect(document.querySelector('#thing-b')).not.toBeVisible();
      
      $('#thing-a a').trigger('click');
      
      expect(document.querySelector('#thing-a')).not.toBeVisible();
      expect(document.querySelector('#thing-b')).toBeVisible();
      expect(document.querySelector('#thing-b input')).toHaveFocus();
      
      $('#thing-b a').trigger('click');
      
      expect(document.querySelector('#thing-a')).toBeVisible();
      expect(document.querySelector('#thing-b')).not.toBeVisible();
    });
  });
});
