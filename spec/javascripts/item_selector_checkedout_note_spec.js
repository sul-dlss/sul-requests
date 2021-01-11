//= require item_selector/item_selector_current_location_note
//= require jasmine-jquery

fixture.preload('checkedout_item_selector.html');

describe('Checked Out Note Toggling', function() {
  beforeAll(function() {
    this.fixtures = fixture.load('checkedout_item_selector.html');
  });

  describe('toggling behavior on item select events', function() {
    beforeEach(function(){
      itemSelectorCurrentLocationNote.addCurrentLocationNoteToggleBehavior();
    });

    it('shows the item checkedout note with the selected event', function() {
      var checkbox = $('input[type="checkbox"]');
      expect(
        itemSelectorCurrentLocationNote.currentLocationNote(checkbox)
      ).not.toBeVisible();

      itemSelectorCurrentLocationNote
        .selectorElement()
        .trigger('item-selector:selected', [checkbox]);

      expect(
        itemSelectorCurrentLocationNote.currentLocationNote(checkbox)
      ).toBeVisible();
    });

    it('hides the item checkedout note with the deselected event', function() {
      var checkbox = $('input[type="checkbox"]');
      $('[data-behavior="current-location-note"]').show();
      expect(
        itemSelectorCurrentLocationNote.currentLocationNote(checkbox)
      ).toBeVisible();

      itemSelectorCurrentLocationNote
        .selectorElement()
        .trigger('item-selector:deselected', [checkbox]);

      expect(
        itemSelectorCurrentLocationNote.currentLocationNote(checkbox)
      ).not.toBeVisible();
    });
  });

  describe('showCurrentLocationNote()', function() {
    it('displays the hidden note', function() {
      var checkbox = $('input[type="checkbox"]');
      expect(
        itemSelectorCurrentLocationNote.currentLocationNote(checkbox)
      ).not.toBeVisible();

      itemSelectorCurrentLocationNote.showCurrentLocationNote(checkbox);

      expect(
        itemSelectorCurrentLocationNote.currentLocationNote(checkbox)
      ).toBeVisible();
    });
  });

  describe('hideCurrentLocationtNote()', function() {
    it('hides the visible note', function() {
      var checkbox = $('input[type="checkbox"]');
      $('[data-behavior="current-location-note"]').show();
      expect(
        itemSelectorCurrentLocationNote.currentLocationNote(checkbox)
      ).toBeVisible();

      itemSelectorCurrentLocationNote.hideCurrentLocationtNote(checkbox);

      expect(
        itemSelectorCurrentLocationNote.currentLocationNote(checkbox)
      ).not.toBeVisible();
    });
  });

  describe('currentLocationNote()', function() {
    it('returns the checkedout note given a checkbox', function() {
      var checkbox = $('input[type="checkbox"]');
      expect(itemSelectorCurrentLocationNote.currentLocationNote(checkbox)).toExist();
    });
  });
});
