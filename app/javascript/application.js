// Entry point for the build script in your package.json
import './jquery-shim'
import Rails from 'rails-ujs'
import './trunk8'
import 'bootstrap'

import './date_selector'
import './item_approval'
import './mediation_table'
import './no_js'
import './paging_schedule_updater'
import './truncate'

// normally, we'd put this in its own file, but when we tried
// that, the functionality broke, and it didn't seem worth spending
// the time to debug further.
$(document).on('turbo:load', function() {
  $("[data-toggle='tooltip']").tooltip();
});

Rails.start()
import "@hotwired/turbo-rails"
