// const util = import * from 'util';
// const exec = util.promisify(require('child_process').exec);

// console.log('Getting asset pipeline lookup path from Rails');
// const { stdout, stderr } = await exec('bundle exec rake asset_paths');
// if (stderr) {
//   console.error(stderr);
// }
const paths = [] //stdout.trim().split('\n');


export default {
  // moduleDirectories: [
  //   'node_modules',
  //   'spec/javascripts',
  //   ...paths,
  // ],
  rootDir: './',
  setupFilesAfterEnv: [
    '<rootDir>/setupJest.js',
  ],
  testEnvironment: 'jest-environment-node',
  testMatch: [
    '<rootDir>/spec/javascripts/*_spec.js',
  ],
  transform: {},
};
