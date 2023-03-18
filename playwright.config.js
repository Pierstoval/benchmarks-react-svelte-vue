// @ts-check
const { defineConfig, devices } = require('@playwright/test');


const apps = [
  { port: 3000, appName: 'svelte', path: 'svelte/dist/' },
  { port: 3001, appName: 'svelte-kit', path: 'svelte-kit/build/' },
  { port: 3002, appName: 'react', path: 'react/build/' },
  { port: 3003, appName: 'react-vite', path: 'react-vite/dist/' },
  { port: 3004, appName: 'react-next', path: 'react-next/out/' },
  { port: 3005, appName: 'vue', path: 'vue/dist/' },
  { port: 3006, appName: 'vue-nuxt', path: 'vue-nuxt/dist/' },
]

const browsers = [
  { browserName: 'chromium', devices: devices['Desktop Chrome'] },
  { browserName: 'firefox', devices: devices['Desktop Firefox'] },
  { browserName: 'webkit', devices: devices['Desktop Safari'] },
];

const webservers = [];
const finalProjects = [];

apps.forEach(({port, appName, path}) => {
  webservers.push({
    port,
    command: `npx http-server -p ${port} ${path}`,
    timeout: 10 * 1000,
    reuseExistingServer: !process.env.CI,
  });

  browsers.forEach(({browserName, devices}) => {
    finalProjects.push({
      name: `${appName} with browser ${browserName}`,
      use: {
        port,
        devices: {
          uses: {...devices},
        },
      }
    });
  });
});

/**
 * Read environment variables from file.
 * https://github.com/motdotla/dotenv
 */
// require('dotenv').config();

/**
 * @see https://playwright.dev/docs/test-configuration
 */
module.exports = defineConfig({
  testDir: './tests',
  quiet: !process.env.CI,
  /* Maximum time one test can run for. */
  timeout: 120 * 1000,
  expect: {
    /**
     * Maximum time expect() should wait for the condition to be met.
     * For example in `await expect(locator).toHaveText();`
     */
    timeout: 5000
  },
  /* Run tests in files in parallel */
  fullyParallel: true,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,
  retries: 0,
  /* Opt out of parallel tests on CI. */
  workers: process.env.CI ? 1 : undefined,
  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: [
      ['dot'],
      ['html', {open: 'never'}],
      ['json', {outputFile: 'playwright-report/report.json'}]
  ],
  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Maximum time each action such as `click()` can take. Defaults to 0 (no limit). */
    actionTimeout: 0,
    /* Base URL to use in actions like `await page.goto('/')`. */
    // baseURL: 'http://localhost:3000',

    /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
    trace: 'on-first-retry',
  },

  /* Configure projects for major browsers */
  projects: finalProjects,
  //[
    //{
    //  name: 'chromium', use: { ...devices['Desktop Chrome'] },
    //},

    //{
    //  name: 'firefox', use: { ...devices['Desktop Firefox'] },
    //},

    //{
    //  name: 'webkit', use: { ...devices['Desktop Safari'] },
    //},

    /* Test against mobile viewports. */
    // {
    //   name: 'Mobile Chrome',
    //   use: { ...devices['Pixel 5'] },
    // },
    // {
    //   name: 'Mobile Safari',
    //   use: { ...devices['iPhone 12'] },
    // },

    /* Test against branded browsers. */
    // {
    //   name: 'Microsoft Edge',
    //   use: { channel: 'msedge' },
    // },
    // {
    //   name: 'Google Chrome',
    //   use: { channel: 'chrome' },
    // },
  //],

  /* Folder for test artifacts such as screenshots, videos, traces, etc. */
  // outputDir: 'test-results/',

  /* Run your local dev server before starting the tests */
  // webServer: {
  //   command: 'npm run start',
  //   port: 3000,
  // },
  webServer: webservers,
});

