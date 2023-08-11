const itemSelector = require('../../app/javascript/item_selector.js');
global.itemSelector = itemSelector;
const itemSelectorCurrentLocationNote = require('../../app/javascript/item_selector/item_selector_current_location_note.js');

const fixture = readFixtures('checkedout_item_selector.html');

describe('Checked Out Note Toggling', () => {
  beforeEach(() => {
    document.body.innerHTML = fixture;
  });

  describe('toggling behavior on item select events', () => {
    beforeEach(() =>{
      itemSelectorCurrentLocationNote.addCurrentLocationNoteToggleBehavior();
    });

    it('shows the item checkedout note with the selected event', () => {
      var checkbox = $('input[type="checkbox"]');
      expect(
        itemSelectorCurrentLocationNote.currentLocationNote(checkbox)[0]
      ).not.toBeVisible();

      itemSelectorCurrentLocationNote
        .selectorElement()
        .trigger('item-selector:selected', [checkbox]);

      expect(
        itemSelectorCurrentLocationNote.currentLocationNote(checkbox)[0]
      ).toBeVisible();
    });

    it('hides the item checkedout note with the deselected event', () => {
      var checkbox = $('input[type="checkbox"]');
      $('[data-behavior="current-location-note"]').show();
      expect(
        itemSelectorCurrentLocationNote.currentLocationNote(checkbox)[0]
      ).toBeVisible();

      itemSelectorCurrentLocationNote
        .selectorElement()
        .trigger('item-selector:deselected', [checkbox]);

      expect(
        itemSelectorCurrentLocationNote.currentLocationNote(checkbox)[0]
      ).not.toBeVisible();
    });
  });

  describe('showCurrentLocationNote()', () => {
    it('displays the hidden note', () => {
      var checkbox = $('input[type="checkbox"]');
      expect(
        itemSelectorCurrentLocationNote.currentLocationNote(checkbox)[0]
      ).not.toBeVisible();

      itemSelectorCurrentLocationNote.showCurrentLocationNote(checkbox);

      expect(
        itemSelectorCurrentLocationNote.currentLocationNote(checkbox)[0]
      ).toBeVisible();
    });
  });

  describe('hideCurrentLocationtNote()', () => {
    it('hides the visible note', () => {
      var checkbox = $('input[type="checkbox"]');
      $('[data-behavior="current-location-note"]').show();
      expect(
        itemSelectorCurrentLocationNote.currentLocationNote(checkbox)[0]
      ).toBeVisible();

      itemSelectorCurrentLocationNote.hideCurrentLocationtNote(checkbox);

      expect(
        itemSelectorCurrentLocationNote.currentLocationNote(checkbox)[0]
      ).not.toBeVisible();
    });
  });

  describe('currentLocationNote()', () => {
    it('returns the checkedout note given a checkbox', () => {
      var checkbox = $('input[type="checkbox"]');
      expect(itemSelectorCurrentLocationNote.currentLocationNote(checkbox).length).toBe(1);
    });
  });
});
