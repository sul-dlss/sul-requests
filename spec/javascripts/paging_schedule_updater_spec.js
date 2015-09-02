//= require paging_schedule_updater
//= require jasmine-jquery

fixture.preload('paging_schedule_elements.html');
fixture.preload('no_dropdown_paging_schedule.html');

describe('Paging schedule updater', function() {
  describe('Elements', function() {
    beforeAll(function() {
      this.fixtures = fixture.load('paging_schedule_elements.html');
    });
    describe('containers', function() {
      it('are present', function() {
        expect(pagingScheduleUpdater.containers().length).toBe(1);
      });
    });

    describe('schedulerUrl', function() {
      it('returns the url with the given destination', function() {
        var container = pagingScheduleUpdater.containers().first();
        expect(
          pagingScheduleUpdater.schedulerUrl(container, 'DEST')
        ).toBe('abc/DEST');
      });
    });
  });

  describe('with a dropdown', function() {
    beforeAll(function() {
      this.fixtures = fixture.load('paging_schedule_elements.html');
    });
    describe('destinationDropdown', function() {
      it('are present', function() {
        var container = pagingScheduleUpdater.containers().first();
        expect(
          pagingScheduleUpdater.destinationDropdown(container).length
        ).toBe(1);
      });
    });
  });

  describe('without a dropdown', function() {
    beforeAll(function() {
      this.fixtures = fixture.load('no_dropdown_paging_schedule.html');
    });

    describe('singleLibraryElement', function() {
      it('are present', function() {
        var container = pagingScheduleUpdater.containers().first();
        expect(pagingScheduleUpdater.singleLibraryElement(container).length).toBe(2);
      });
    });
  });

  describe('updateSchedulerText', function() {
    it('updates the given element text', function() {
      var schedulerText = $('[data-scheduler-text="true"]').first();
      var data = { text: 'Updated Text' };
      expect(schedulerText.text()).toBe('');
      pagingScheduleUpdater.updateSchedulerText(schedulerText, data);
      expect(schedulerText.text()).toBe('Updated Text');
    });
  });
});
