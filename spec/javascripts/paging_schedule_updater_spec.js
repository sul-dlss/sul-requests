//= require paging_schedule_updater
//= require jasmine-jquery

fixture.preload('paging_schedule_elements.html');
fixture.preload('no_dropdown_paging_schedule.html');

describe('Paging schedule updater', function() {
  describe('With a dropdown', function() {
    beforeAll(function() {
      this.fixtures = fixture.load('paging_schedule_elements.html');
    });

    describe('selectElement()', function() {
      it('is present', function() {
        expect(pagingScheduleUpdater.selectElement().length).toBe(1);
      });
    });

    describe('schedulerValue()', function() {
      it('gets the value from the dropdown', function() {
        expect(pagingScheduleUpdater.schedulerValue()).toBe('opt1');
      });
    });

    describe('schedulerText()', function() {
      it('is present', function() {
        expect(pagingScheduleUpdater.schedulerText().length).toBe(1);
      });
    });

    describe('updateSchedulerText()', function() {
      it('updates the scheduler text element', function() {
        expect(pagingScheduleUpdater.schedulerText().text()).toBe('');
        pagingScheduleUpdater.updateSchedulerText({'text': 'SOMETHING!'});
        expect(pagingScheduleUpdater.schedulerText().text()).toBe('SOMETHING!');
      });
    });
  });

  describe('without a dropdown', function() {
    beforeAll(function() {
      this.fixtures = fixture.load('no_dropdown_paging_schedule.html');
    });

    describe('selectElement()', function() {
      it('is not present', function() {
        expect(pagingScheduleUpdater.selectElement().length).toBe(0);
      });
    });

    describe('schedulerValue()', function() {
      it('gets the value for the single item', function() {
        expect(pagingScheduleUpdater.schedulerValue()).toBe('single-opt');
      });
    });

    describe('schedulerText()', function() {
      it('is present', function() {
        expect(pagingScheduleUpdater.schedulerText().length).toBe(1);
      });
    });

    describe('updateSchedulerText()', function() {
      it('updates the scheduler text element', function() {
        expect(pagingScheduleUpdater.schedulerText().text()).toBe('');
        pagingScheduleUpdater.updateSchedulerText({'text': 'SOMETHING!'});
        expect(pagingScheduleUpdater.schedulerText().text()).toBe('SOMETHING!');
      });
    });
  });
});
