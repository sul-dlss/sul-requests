import pagingScheduleUpdater from "../../app/assets/javascripts/paging_schedule_updater.js"

const fixture_paging_schedule = readFixtures('paging_schedule_elements.html');
const fixture_no_dropdown_paging_schedule = readFixtures('no_dropdown_paging_schedule.html');

describe('Paging schedule updater', () => {
  describe('Elements', () => {
    beforeEach(() => {
      document.body.innerHTML = fixture_paging_schedule;
    });
    describe('containers', () => {
      it('are present', () => {
        expect(pagingScheduleUpdater.containers().length).toBe(1);
      });
    });

    describe('schedulerUrl', () => {
      it('returns the url with the given destination', () => {
        var container = pagingScheduleUpdater.containers().first();
        expect(
          pagingScheduleUpdater.schedulerUrl(container, 'DEST')
        ).toBe('abc/DEST');
      });
    });
  });

  describe('with a dropdown', () => {
    beforeEach(() => {
      document.body.innerHTML = fixture_paging_schedule;
    });
    describe('destinationDropdown', () => {
      it('are present', () => {
        var container = pagingScheduleUpdater.containers().first();
        expect(
          pagingScheduleUpdater.destinationDropdown(container).length
        ).toBe(1);
      });
    });
  });

  describe('without a dropdown', () => {
    beforeEach(() => {
      document.body.innerHTML = fixture_no_dropdown_paging_schedule;
    });

    describe('singleLibraryElement', () => {
      it('are present', () => {
        var container = pagingScheduleUpdater.containers().first();
        expect(pagingScheduleUpdater.singleLibraryElement(container).length).toBe(2);
      });
    });
  });

  describe('updateSchedulerText', () => {
    it('updates the given element text', () => {
      var schedulerText = $('[data-scheduler-text="true"]').first();
      var data = { text: 'Updated Text' };
      expect(schedulerText.text()).toBe('');
      pagingScheduleUpdater.updateSchedulerText(schedulerText, data);
      expect(schedulerText.text()).toBe('Updated Text');
    });
  });
});
