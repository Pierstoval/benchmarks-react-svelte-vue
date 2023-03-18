const base = require('@playwright/test');

exports.test = base.test.extend({
    port: [null, { option: true }],
});
