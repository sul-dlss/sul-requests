var pagingScheduleUpdater = (function() {

  var defaultOptions = {
    dropdownSelector: '[data-paging-schedule-updater="true"]',
    containerSelector: '[data-scheduler-lookup-url]',
    textSelector: '[data-scheduler-text]',
    singleLibrarySelector: '[data-single-library-value]'
  };

  return {
    init: function(opts) {
      var _this = this;
      _this.options = $.extend(defaultOptions, opts);
      $(document).on('turbolinks:load', function(){
        _this.setInitialSchedules();
      });
    },

    options: {},

    setInitialSchedules: function() {
      var _this = this;
      _this.containers().each(function(){
        _this.renderSingleValueEstimates($(this));
        _this.renderSelectedDropdownValuesAndAddChangeBehavior($(this));
      });
    },

    renderSingleValueEstimates: function(container){
      var _this = this;
      _this.singleLibraryElement(container).each(function(){
        var destination = $(this).data('single-library-value');
        var schedulerText = $(this).find(_this.options.textSelector);
        _this.updatePagingSchedule(container, destination, schedulerText);
      });
    },

    renderSelectedDropdownValuesAndAddChangeBehavior: function(container) {
      var _this = this;
      _this.destinationDropdown(container).each(function() {
        var schedulerText = $($(this).data('text-selector'));
        _this.updatePagingSchedule(container, $(this).val(), schedulerText);
        $(this).on('change', function() {
          _this.updatePagingSchedule(container, $(this).val(), schedulerText);
        });
      });
    },

    updatePagingSchedule: function(container, destination, schedulerText) {
      var _this = this;
      $.ajax({url: _this.schedulerUrl(container, destination)})
       .done(function(data){
         _this.updateSchedulerText(schedulerText, data);
       })
       .fail(function(){
         _this.updateSchedulerText(schedulerText, {
           'text': 'No estimate available'
         });
       });
    },

    updateSchedulerText: function(schedulerText, data) {
      if(schedulerText.text() != data.text) {
        schedulerText.text(data.text);
        this.udpateSchedulerHiddenField(schedulerText, data);
        schedulerText.addClass('highlighted');
        schedulerText.trigger('paging-schedule:updated', [data]);
        setTimeout(function(){
          schedulerText.removeClass('highlighted');
        }, 1500);
      }
    },

    udpateSchedulerHiddenField: function(schedulerText, data) {
      schedulerText.next('input[data-scheduler-field="true"]').val(data.text);
    },

    containers: function() {
      return $(this.options.containerSelector);
    },

    destinationDropdown: function(container) {
      return container.find(this.options.dropdownSelector);
    },

    singleLibraryElement: function(container) {
      return container.find(this.options.singleLibrarySelector);
    },

    schedulerUrl: function(container, destination) {
      return this.baseUrl(container) + '/' + destination;
    },

    baseUrl: function(container) {
      return container.data('scheduler-lookup-url');
    },
  };
})();

pagingScheduleUpdater.init();

// Basic support of CommonJS module for import into test
if (typeof exports === "object") {
  module.exports = pagingScheduleUpdater;
}
