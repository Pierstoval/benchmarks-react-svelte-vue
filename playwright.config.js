// @ts-check
const { readdirSync } = require('fs');
const { defineConfig, devices } = require('@playwright/test');

const apps = readdirSync(__dirname + '/apps/', { withFileTypes: true })
  .filter((dirent) => dirent.isDirectory())
  .map((dirent) => dirent.name);

function error(message) {
  console.error(`\x1b[31m [ERROR] ${message}\x1b[0m`);
}

/**
 * Headed desktop browsers (full browser binaries, not headless-shell).
 * bench_it_all.bash always runs under xvfb-run and sets BENCHMARK_DISPLAY_BACKEND=x11
 * so Chromium targets Xvfb, not an interactive Wayland compositor when both exist.
 */
const browsers = [
  { browserName: 'chromium', device: devices['Desktop Chrome'] },
  { browserName: 'firefox', device: devices['Desktop Firefox'] },
  { browserName: 'webkit', device: devices['Desktop Safari'] },
];

const forceXvfbX11 = process.env.BENCHMARK_DISPLAY_BACKEND === 'x11';

const appToTest = process.env.TEST_APP || null;

if (apps.indexOf(appToTest) < 0) {
  error('You must specify which application to test by specifying the TEST_APP environment variable.');
  error('Possible values:');
  error(' ' + apps.join(', ') + '');
  process.exit(1);
}

const port = 13000;
const path = __dirname + '/apps/' + appToTest + '/dist/';

const webserver = {
  port,
  command: `npx http-server -p ${port} ${path}`,
  timeout: 30 * 1000,
  reuseExistingServer: !process.env.CI,
};

const finalProjects = browsers.map(({ browserName, device }) => {
  /** @type {import('@playwright/test').Project['use']} */
  const use = {
    ...device,
    browserName,
    // Match the Xvfb virtual screen used by the benchmark runner.
    viewport: { width: 1920, height: 1080 },
    headless: false,
    port,
  };

  // Chromium-only flags; WebKit/Firefox reject unknown launch args.
  if (browserName === 'chromium') {
    const args = ['--disable-dev-shm-usage'];
    // When launched via bench_it_all.bash under xvfb-run, pin Ozone to X11 so a
    // host Wayland session cannot steal the window.
    if (forceXvfbX11) {
      args.push('--ozone-platform=x11');
    }
    use.launchOptions = { args };
  }

  return { name: browserName, use };
});

/**
 * @see https://playwright.dev/docs/test-configuration
 */
module.exports = defineConfig({
  testDir: './tests',
  quiet: !process.env.CI,
  /* Headed browsers under Xvfb are slower than headless-shell. */
  timeout: 120 * 1000,
  expect: {
    /**
     * Maximum time expect() should wait for the condition to be met.
     * For example in `await expect(locator).toHaveText();`
     */
    timeout: 8000,
  },
  /* Run tests in files in parallel */
  fullyParallel: false,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,
  retries: 0,
  /* One worker: headed UI + fair runtime comparison across apps. */
  workers: 1,
  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: [
    ['dot'],
    ['line'],
    ['html', { open: 'never' }],
    ['json', { outputFile: 'playwright-report/report.json' }],
  ],
  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Maximum time each action such as `click()` can take. Defaults to 0 (no limit). */
    actionTimeout: 0,
    headless: false,
    /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
    trace: 'on-first-retry',
  },

  /* Configure projects for major browsers */
  projects: finalProjects,

  /* Run your local static server before starting the tests */
  webServer: webserver,
});
