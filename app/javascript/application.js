// Entry point for the build script in your package.json
import './jquery-shim'
import Rails from 'rails-ujs'
import './trunk8'
import 'bootstrap'

import './additional_user_validation_fields'
import './date_selector'
import './item_approval'
import './item_selector'
import './mediation_table'
import './no_js'
import './non_stanford_overlay_close'
import './paging_schedule_updater'
import './request_form_valiator'
import './toggle_show_tabs'
import './truncate'
import './item_selector/item_selector_active'
import './item_selector/item_selector_aeon'
import './item_selector/item_selector_breadcrumbs'
import './item_selector/item_selector_current_location_note'
import './item_selector/item_selector_filtering'
import './item_selector/item_selector_incrementor'
import './item_selector/item_selector_limit'
import './item_selector/item_selector_limit_message'
import './item_selector/item_selector_single_select'
import './item_selector/item_selector_zero_message'

$.swap = function (elem, options, callback, args) {
  var ret, name, old = {};

  // Remember the old values, and insert the new ones
  for (name in options) {
      old[name] = elem.style[name];
      elem.style[name] = options[name];
  }

  ret = callback.apply(elem, args || []);

  // Revert the old values
  for (name in options) {
      elem.style[name] = old[name];
  }

  return ret;
}

// normally, we'd put this in its own file, but when we tried
// that, the functionality broke, and it didn't seem worth spending
// the time to debug further.
$(document).on('turbo:load', function() {
  $("[data-toggle='tooltip']").tooltip();
});

Rails.start()
import "@hotwired/turbo-rails"
