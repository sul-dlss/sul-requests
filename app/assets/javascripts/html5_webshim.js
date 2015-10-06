$(document).on('ready page:load', function(){
  if (window.webshim) {
    window.webshim.setOptions('forms-ext', {
      lazyCustomMessages: true,
      replaceUI: true,
      waitReady: true,
      type: 'date',
      date: {
        startView: 2,
        openOnFocus: true
      }
    });

    window.webshim.activeLang('en-US');
    window.webshim.polyfill('forms-ext');
  }
});
