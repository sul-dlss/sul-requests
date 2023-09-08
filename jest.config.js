const config = {
  testEnvironment: 'jsdom',
  moduleDirectories: [
    'node_modules',
    'spec/javascripts',
    'app/assets/builds',
  ],
  rootDir: './',
  setupFilesAfterEnv: [
    '<rootDir>/setupJest.js',
  ],
  testMatch: [
    '<rootDir>/spec/javascripts/*_spec.js',
  ],
};

module.exports = config;
