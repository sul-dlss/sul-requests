//= require mediation_table
//= require jasmine-jquery
fixture.preload('mediation_table.html');
describe('Mediation Table', function() {
  beforeAll(function() {
    this.fixtures = fixture.load('mediation_table.html');
  });

  describe('Rows', function(){
    it('gets all the mediateable rows by selector', function(){
      expect(mediationTable.mediatableRows().length).toBe(3);
    });
  });

  describe('Row toggling', function(){
    describe('showRow', function() {
      it('adds the expanded class to the row', function() {
        var lastRow = mediationTable.mediatableRows().last();
        lastRow.removeClass('expanded');
        expect(lastRow).not.toHaveClass('expanded');
        mediationTable.showRow(lastRow);
        expect(lastRow).toHaveClass('expanded');
      });
    });

    describe('hideRow', function() {
      it('removes the expanded class on the row', function() {
        var lastRow = mediationTable.mediatableRows().last();
        lastRow.addClass('expanded');
        expect(lastRow).toHaveClass('expanded');
        mediationTable.hideRow(lastRow);
        expect(lastRow).not.toHaveClass('expanded');
      });
    });
  });

  describe('Toggle Handle', function() {
    it('finds the handle in the row', function() {
      var row = mediationTable.mediatableRows().first();
      expect(mediationTable.toggleHandle(row).attr('id')).toBe('toggle-handle1');
    });
  });

  describe('rowIsProcessed', function() {
    it('is truthy when the next row is a populated holdings row', function() {
      var lastRow = mediationTable.mediatableRows().last();
      expect(mediationTable.rowIsProcessed(lastRow)).toBeTruthy();
    });

    it('is falsy when the next row is not a populated holdings row', function() {
      var firstRow = mediationTable.mediatableRows().first();
      expect(mediationTable.rowIsProcessed(firstRow)).toBeFalsy();
    });
  });

  describe('holdingsRow', function() {
    it('returns the row that will contain the holdings', function() {
      var lastRow = mediationTable.mediatableRows().last();
      expect(mediationTable.holdingsRow(lastRow).length).toBe(1);
    });

    it('returns nothing when not present', function() {
      var firstRow = mediationTable.mediatableRows().first();
      expect(mediationTable.holdingsRow(firstRow).length).toBe(0);
    });
  });

  describe('createHoldingsRow', function() {
    it('adds a row to place the holdings into', function() {
      var firstRow = mediationTable.mediatableRows().first();
      expect(firstRow.next('tr.holdings').length).toBe(0);
      mediationTable.createHoldingsRow(firstRow);
      expect(firstRow.next('tr.holdings').length).toBe(1);
    });
  });

  describe('Options', function() {
    it('has defaults', function() {
      expect(mediationTable.options.selector).toBe('[data-mediate-request]');
    });

    it('extends default with passed in attributes', function() {
      mediationTable.init({ selector: '.something-else' });
      expect(mediationTable.options.selector).toBe('.something-else');
    });
  });
});
