const { test } = require('./base_test');
const { expect } = require('@playwright/test');

test('Test todo app', async ({ page, port }, testInfo) => {
    await page.goto(`http://127.0.0.1:${port}/`);
    expect(page.url()).toBe(`http://127.0.0.1:${port}/`);

    const numberOfElements = 200;

    const timeStart = await page.evaluate(() => performance.now());

    for (let i = 0; i <= numberOfElements; i++) {
        const text = 'Test content '+i;
        await page.getByPlaceholder('Add a new element').fill(text);
        await page.getByRole('button', { name: 'Add' }).click({ force: true });
        await expect(page.locator(`ul li`).nth(i)).toContainText(text);
    }

    for (let i = numberOfElements; i >= 0; i--) {
        const text = 'Test content '+i;
        await expect(page.locator(`ul li`).nth(i)).toContainText(text);
        await page.locator(`ul li`).nth(i).locator('button').click({ force: true });
        await expect(page.locator(`ul`)).not.toContainText(text);
    }

    const timeEnd = await page.evaluate(() => performance.now());
    const wallTimeMs = Math.round(timeEnd - timeStart);

    testInfo.annotations.push({
        type: 'browser_wall_time_ms',
        description: String(wallTimeMs),
    });
});
