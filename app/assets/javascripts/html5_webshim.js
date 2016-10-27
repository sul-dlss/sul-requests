$(document).on('turbolinks:load', function(){
  if (window.webshim) {
    window.webshim.setOptions('forms-ext', {
      lazyCustomMessages: true,
      replaceUI: true,
      waitReady: true,
      type: 'date',
      date: {
        startView: 2,
        openOnFocus: true,
        popover: {
          position: {
            my: 'center bottom',
            at: 'center top',
            collision: 'none'
          }
        }
      }
    });

    window.webshim.activeLang('en-US');
    window.webshim.polyfill('forms-ext');
  }
});
