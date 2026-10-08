// node shoot.mjs <url> <out.png> [w h]  — renders at 2x once body[data-ready] is set
import { chromium } from '/opt/node-tools/node_modules/playwright/index.mjs';
const [, , url, out, w = '1600', h = '900'] = process.argv;
const b = await chromium.launch({ args: ['--allow-file-access-from-files'] });
const p = await b.newPage({ viewport: { width: +w, height: +h }, deviceScaleFactor: 2 });
p.on('pageerror', e => console.log('error:', e.message));
p.on('console', m => m.type() === 'error' && console.log('console:', m.text()));
await p.goto(url); await p.waitForSelector('body[data-ready]', { timeout: 60000 }); await p.waitForTimeout(500);
await p.screenshot({ path: out, fullPage: true }); await b.close();
