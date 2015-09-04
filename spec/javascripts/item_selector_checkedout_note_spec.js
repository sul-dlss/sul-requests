//= require item_selector/item_selector_checkedout_note
//= require jasmine-jquery

fixture.preload('checkedout_item_selector.html');

describe('Checked Out Note Toggling', function() {
  beforeAll(function() {
    this.fixtures = fixture.load('checkedout_item_selector.html');
  });

  describe('toggling behavior on item select events', function() {
    beforeEach(function(){
      itemSelectorCheckedoutNote.addCheckedoutNoteToggleBehavior();
    });

    it('shows the item checkedout note with the selected event', function() {
      var checkbox = $('input[type="checkbox"]');
      expect(
        itemSelectorCheckedoutNote.checkedoutNote(checkbox)
      ).not.toBeVisible();

      itemSelectorCheckedoutNote
        .selectorElement()
        .trigger('item-selector:selected', [checkbox]);

      expect(
        itemSelectorCheckedoutNote.checkedoutNote(checkbox)
      ).toBeVisible();
    });

    it('hides the item checkedout note with the deselected event', function() {
      var checkbox = $('input[type="checkbox"]');
      $('[data-behavior="checkedout-note"]').show();
      expect(
        itemSelectorCheckedoutNote.checkedoutNote(checkbox)
      ).toBeVisible();

      itemSelectorCheckedoutNote
        .selectorElement()
        .trigger('item-selector:deselected', [checkbox]);

      expect(
        itemSelectorCheckedoutNote.checkedoutNote(checkbox)
      ).not.toBeVisible();
    });
  });

  describe('showCheckedoutNote()', function() {
    it('displays the hidden note', function() {
      var checkbox = $('input[type="checkbox"]');
      expect(
        itemSelectorCheckedoutNote.checkedoutNote(checkbox)
      ).not.toBeVisible();

      itemSelectorCheckedoutNote.showCheckedoutNote(checkbox);

      expect(
        itemSelectorCheckedoutNote.checkedoutNote(checkbox)
      ).toBeVisible();
    });
  });

  describe('hideCheckedoutNote()', function() {
    it('hides the visible note', function() {
      var checkbox = $('input[type="checkbox"]');
      $('[data-behavior="checkedout-note"]').show();
      expect(
        itemSelectorCheckedoutNote.checkedoutNote(checkbox)
      ).toBeVisible();

      itemSelectorCheckedoutNote.hideCheckedoutNote(checkbox);

      expect(
        itemSelectorCheckedoutNote.checkedoutNote(checkbox)
      ).not.toBeVisible();
    });
  });

  describe('checkedoutNote()', function() {
    it('returns the checkedout note given a checkbox', function() {
      var checkbox = $('input[type="checkbox"]');
      expect(itemSelectorCheckedoutNote.checkedoutNote(checkbox)).toExist();
    });
  });
});
