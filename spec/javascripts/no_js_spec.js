import readFixtures from 'read_fixtures';
const noJS = require('../../app/assets/javascripts/no_js.js');

const fixture = readFixtures('no_js.html');

describe('No Javascript', function() {
  beforeEach(() => {
    document.body.innerHTML = fixture;
  });

  describe('the no-js class', function() {
    test('is not present', function() {
      expect($('.no-js').length).toEqual(1);
      noJS.toggleNoJS();
      expect($('.no-js').length).toEqual(0);
    });
  });
});
