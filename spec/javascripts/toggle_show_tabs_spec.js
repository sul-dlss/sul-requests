//= require toggle_show_tabs
//= require jasmine-jquery

fixture.preload('toggle_show_tabs.html');

describe('Toggling show tabs', function() {
  beforeAll(function() {
    this.fixtures = fixture.load('toggle_show_tabs.html');
  });

  describe('addToggleBehavior()', function() {
    it('it allows the user to toggle back and forth between panes', function() {
      toggleShowTabs.addToggleBehavior();

      expect($('#thing-a:visible').length).toEqual(1);
      expect($('#thing-b:visible').length).toEqual(0);
      
      $('#thing-a a').click();
      
      expect($('#thing-a:visible').length).toEqual(0);
      expect($('#thing-b:visible').length).toEqual(1);
      expect($('#thing-b input')).toEqual($( document.activeElement ));
      
      $('#thing-b a').click();
      
      expect($('#thing-a:visible').length).toEqual(1);
      expect($('#thing-b:visible').length).toEqual(0);
    });
  });
});
