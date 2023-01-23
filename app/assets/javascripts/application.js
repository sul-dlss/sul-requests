// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery3
//= require rails-ujs
//= require turbolinks
//= require jquery_nested_form
//= require bootstrap/alert
//= require bootstrap/collapse
//= require bootstrap/tooltip
//= require bootstrap-sprockets
//= require bootstrap-editable
//= require bootstrap-editable-rails
//= require list.min.js
//= require no_js
//= require trunk8
//= require_tree .

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
$(document).on('turbolinks:load', function() {
  $('.editable').editable();
  $("[data-toggle='tooltip']").tooltip();
});
