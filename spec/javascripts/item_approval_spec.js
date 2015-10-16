//= require item_approval
//= require jasmine-jquery
fixture.preload('item_approval_rows.html');

describe('Item Approval', function() {
  beforeAll(function() {
    this.fixtures = fixture.load('item_approval_rows.html');
  });

  describe('markRowAsApproved()', function() {
    it('adds the approved class to the row', function() {
      var lastButton = $('button:last');
      var lastRow = $('tr:last');
      expect(lastRow).not.toHaveClass('approved');
      itemApproval.markRowAsApproved(lastButton);
      expect(lastRow).toHaveClass('approved');
      expect(lastButton.text()).toBe('Approved');
    });
  });

  describe('markRowAsError()', function() {
    it('adds the errored class to the row', function() {
      var lastButton = $('button:last');
      var lastRow = $('tr:last');
      expect(lastRow).not.toHaveClass('errored');
      itemApproval.markRowAsError(lastButton);
      expect(lastRow).toHaveClass('errored');
    });
  });

  describe('updateApproverInformation()', function() {
    it('adds the given appover data to the approriate element', function() {
      expect($('tr:last td:last').text()).toBe('');
      var item = $('button:last');
      itemApproval.updateApproverInformation(item, {
        approver: 'jstanford',
        approval_time: '2015-01-01 3.02pm'
      });
      expect($('tr:last td:last').text()).toBe('jstanford - 2015-01-01 3.02pm');
    });
  });

  describe('rowIsApproved()', function() {
    it('returns weather the given element has the approved class or not', function() {
      expect(itemApproval.rowIsApproved($('tr:first'))).toBe(true);
      expect(itemApproval.rowIsApproved($('tr:last'))).toBe(false);
    });
  });
});
