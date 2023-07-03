import mediationTable from "../../app/assets/javascripts/mediation_table.js"

const fixture = readFixtures('mediation_table.html');

describe('Mediation Table', () => {
  beforeEach(() => {
    document.body.innerHTML = fixture;
  });

  describe('Rows', () =>{
    it('gets all the mediateable rows by selector', () =>{
      expect(mediationTable.mediatableRows().length).toBe(3);
    });
  });

  describe('Row toggling', () =>{
    describe('showRow', () => {
      it('adds the expanded class to the row', () => {
        var lastRow = mediationTable.mediatableRows().last();
        lastRow.removeClass('expanded');
        expect(lastRow[0]).not.toHaveClass('expanded');
        mediationTable.showRow(lastRow);
        expect(lastRow[0]).toHaveClass('expanded');
      });
    });

    describe('hideRow', () => {
      it('removes the expanded class on the row', () => {
        var lastRow = mediationTable.mediatableRows().last();
        lastRow.addClass('expanded');
        expect(lastRow[0]).toHaveClass('expanded');
        mediationTable.hideRow(lastRow);
        expect(lastRow[0]).not.toHaveClass('expanded');
      });
    });
  });

  describe('Toggle Handle', () => {
    it('finds the handle in the row', () => {
      var row = mediationTable.mediatableRows().first();
      expect(mediationTable.toggleHandle(row).attr('id')).toBe('toggle-handle1');
    });
  });

  describe('rowIsProcessed', () => {
    it('is truthy when the next row is a populated holdings row', () => {
      var lastRow = mediationTable.mediatableRows().last();
      expect(mediationTable.rowIsProcessed(lastRow)).toBeTruthy();
    });

    it('is falsy when the next row is not a populated holdings row', () => {
      var firstRow = mediationTable.mediatableRows().first();
      expect(mediationTable.rowIsProcessed(firstRow)).toBeFalsy();
    });
  });

  describe('holdingsRow', () => {
    it('returns the row that will contain the holdings', () => {
      var lastRow = mediationTable.mediatableRows().last();
      expect(mediationTable.holdingsRow(lastRow).length).toBe(1);
    });

    it('returns nothing when not present', () => {
      var firstRow = mediationTable.mediatableRows().first();
      expect(mediationTable.holdingsRow(firstRow).length).toBe(0);
    });
  });

  describe('createHoldingsRow', () => {
    it('adds a row to place the holdings into', () => {
      var firstRow = mediationTable.mediatableRows().first();
      expect(firstRow.next('tr.holdings').length).toBe(0);
      mediationTable.createHoldingsRow(firstRow);
      expect(firstRow.next('tr.holdings').length).toBe(1);
    });
  });

  describe('Options', () => {
    it('has defaults', () => {
      expect(mediationTable.options.selector).toBe('[data-mediate-request]');
    });

    it('extends default with passed in attributes', () => {
      mediationTable.init({ selector: '.something-else' });
      expect(mediationTable.options.selector).toBe('.something-else');
    });
  });
});
