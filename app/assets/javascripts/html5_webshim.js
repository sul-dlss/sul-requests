$(document).on('ready page:load', function(){
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

  window.webshim.polyfill('forms-ext');
});
