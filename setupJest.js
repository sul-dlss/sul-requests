import $ from 'jquery';
import '@testing-library/jest-dom';

import readFixtures from 'read_fixtures';


global.readFixtures = readFixtures;
global.jQuery = $;
global.$ = global.jQuery;
