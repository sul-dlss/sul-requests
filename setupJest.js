import { JSDOM } from 'jsdom';
import $ from 'jquery';
import '@testing-library/jest-dom';

import readFixtures from 'read_fixtures';

const jsdom = new JSDOM('<html></html>', { pretendToBeVisual: true });
const { window } = jsdom;

global.readFixtures = readFixtures;
global.window = window;
global.jQuery = $;
global.$ = global.jQuery;