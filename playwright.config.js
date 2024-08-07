import { readdirSync } from 'fs';

// @ts-check
const { defineConfig, devices } = require('@playwright/test');


const apps = readdirSync(__dirname+"/apps/", { withFileTypes: true })
    .filter(dirent => dirent.isDirectory())
    .map(dirent => dirent.name);

function error(message) {
  console.error(`\x1b[31m [ERROR] ${message}\x1b[0m`)
}

const browsers = [
  { browserName: 'chromium', devices: devices['Desktop Chrome'] },
  { browserName: 'firefox', devices: devices['Desktop Firefox'] },
  { browserName: 'webkit', devices: devices['Desktop Safari'] },
];

const appToTest = process.env.TEST_APP || null;

if (apps.indexOf(appToTest) < 0) {
  error("You must specify which application to test by specifying the TEST_APP environment variable.");
  error("Possible values:")
  error(" "+apps.join(", ")+"");
  process.exit(1);
}

const port = 13000;
const path = __dirname+"/apps/"+appToTest+"/dist/";

const webserver = {
  port,
  command: `npx http-server -p ${port} ${path}`,
  timeout: 30 * 1000,
  reuseExistingServer: !process.env.CI,
};

const finalProjects = browsers
    .map(({browserName, devices}) => {
      return {
        name: `${browserName}`,
        use: {
          port,
          devices: {
            uses: {...devices},
          },
        }
      };
    })
;

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
  timeout: 40 * 1000,
  expect: {
    /**
     * Maximum time expect() should wait for the condition to be met.
     * For example in `await expect(locator).toHaveText();`
     */
    timeout: 8000
  },
  /* Run tests in files in parallel */
  fullyParallel: false,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,
  retries: 0,
  /* Opt out of parallel tests on CI. */
  workers: process.env.CI ? 1 : undefined,
  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: [
      ['dot'],
      ['line'],
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
  webServer: webserver,
});
