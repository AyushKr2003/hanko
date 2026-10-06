// Render a mockup: node shoot.mjs "file:///abs/path/page.html?query" out.png [width] [height]
// a05-motion.html expects frames in out/fr/ rendered from emaki.html first (see docs/DESIGN.md).
import { chromium } from 'playwright';
const [, , url, out, w = '1600', h = '900'] = process.argv;
const b = await chromium.launch();
const p = await b.newPage({ viewport: { width: +w, height: +h }, deviceScaleFactor: 2 });
await p.goto(url.includes('://') ? url : 'file://' + url);
await p.waitForSelector('body[data-ready]', { timeout: 60000 });
await p.waitForTimeout(300);
await p.screenshot({ path: out, fullPage: true });
await b.close();
