const { test } = require('./base_test');
const { expect } = require("@playwright/test");

test('Test todo app', async ({ page, port }) => {
    await page.goto(`http://127.0.0.1:${port}/`);
    expect(page.url()).toBe(`http://127.0.0.1:${port}/`);

    const numberOfElements = 100;

    for (let i = 0; i <= numberOfElements; i++) {
        const text = 'Test content '+i;
        await page.getByPlaceholder('Add a new element').fill(text);
        await page.getByRole('button', { name: 'Add' }).click();
        await expect(page.locator(`ul li`).nth(i)).toContainText(text);
    }

    for (let i = numberOfElements; i >= 0; i--) {
        const text = 'Test content '+i;
        await expect(page.locator(`ul li`).nth(i)).toContainText(text);
        await page.locator(`ul li`).nth(i).locator('button').click();
        await expect(page.locator(`ul`)).not.toContainText(text);
    }
});
