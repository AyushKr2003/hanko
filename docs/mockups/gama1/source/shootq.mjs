import { chromium } from '/opt/node-tools/node_modules/playwright/index.mjs';
const [, , url, out, w = '1600', h = '900'] = process.argv;
const b = await chromium.launch();
const p = await b.newPage({ viewport: { width: +w, height: +h }, deviceScaleFactor: 2 });
p.on('pageerror', e => console.log('error:', e.message));
await p.goto(url); await p.waitForSelector('body[data-ready]', { timeout: 60000 }); await p.waitForTimeout(300);
await p.screenshot({ path: out, fullPage: true }); await b.close();
