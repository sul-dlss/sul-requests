//= require no_js
//= require jasmine-jquery

fixture.preload('no_js.html');

describe('No Javascript', function() {
  beforeAll(function() {
    this.fixtures = fixture.load('no_js.html');
  });

  describe('the no-js class', function() {
    it('is not present', function() {
      expect($('.no-js').length).toEqual(1);
      noJS.toggleNoJS();
      expect($('.no-js').length).toEqual(0);
    });
  });
});
