import { JSDOM } from 'jsdom';
import jQuery from 'jquery';
// import List from 'list.min';
import '@testing-library/jest-dom';

const jsdom = new JSDOM('<html></html>', { pretendToBeVisual: true });
const { window } = jsdom;

console.error("jquery", jQuery)
const more = jQuery.extend({one: '1'}, {two: '2'})

// import readFixtures from 'read_fixtures';


// global.readFixtures = readFixtures;
global.window = window;
global.jQuery = jQuery;
global.$ = global.jQuery;
// global.List = List;
