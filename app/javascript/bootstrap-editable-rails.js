/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// bootstrap-editable-rails.js.coffee
// Modify parameters of X-editable suitable for Rails.

jQuery(function($) {
  const EditableForm = $.fn.editableform.Constructor;
  if (EditableForm.prototype.saveWithUrlHook == null) {
    EditableForm.prototype.saveWithUrlHook = function(value) {
      const originalUrl = this.options.url;
      const {
        resource
      } = this.options;
      this.options.url = params => {
        // TODO: should not send when create new object
        if (typeof originalUrl === 'function') { // user's function
          return originalUrl.call(this.options.scope, params);
        } else if ((originalUrl != null) && (this.options.send !== 'never')) {
          // send ajax to server and return deferred object
          const obj = {};
          obj[params.name] = params.value;
          // support custom inputtypes (eg address)
          if (resource) {
            params[resource] = obj;
          } else {
            params = obj;
          }
          delete params.name;
          delete params.value;
          delete params.pk;
          return $.ajax($.extend({
            url     : originalUrl,
            data    : params,
            type    : 'PUT', // TODO: should be 'POST' when create new object
            dataType: 'json'
          }, this.options.ajaxOptions));
        }
      };
      return this.saveWithoutUrlHook(value);
    };
    EditableForm.prototype.saveWithoutUrlHook = EditableForm.prototype.save;
    return EditableForm.prototype.save = EditableForm.prototype.saveWithUrlHook;
  }
});
