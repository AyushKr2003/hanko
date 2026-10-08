// node docs/kata/prototype/kata.test.mjs — the resolver is pure, so it runs under Node
// (the same tests would move to tests/unit.mjs with core/Kata.js).
import assert from 'node:assert/strict';
import { PARTS, DESIGNS, AUTO, TOUCHES, resolve, surprise, describe } from './kata.js';
let n = 0; const t = (name, f) => { f(); n++; console.log('ok', name); };

t('every design resolves every part, with no warnings', () => {
  for (const d of Object.keys(DESIGNS)) { const s = resolve({ design: d }); assert.deepEqual(s.warnings, []); for (const k of Object.keys(PARTS)) assert.ok(PARTS[k].v[s[k]], `${d}.${k}=${s[k]}`); }
});
t('designs resolve to their own parts and partners', () => {
  assert.equal(resolve({ design: 'leaf' }).corner, 'cut'); assert.equal(resolve({ design: 'leaf' }).tempo, 'snap');
  assert.equal(resolve({ design: 'margin' }).divider, 'hairline'); assert.equal(resolve({ design: 'shoji' }).tempo, 'johakyu');
});
t('partners follow a borrowed part', () => {
  const s = resolve({ design: 'shoji', borrow: { surface: 'paper', arrive: 'fold' } });
  assert.equal(s.corner, 'soft'); assert.equal(s.divider, 'hairline'); assert.equal(s.tempo, 'spring');
});
t('a partner set by hand wins over auto', () => {
  const s = resolve({ design: 'leaf', borrow: { corner: 'soft' } }); assert.equal(s.corner, 'soft'); assert.equal(s.divider, 'score');
});
t('auto gives a part back', () => { assert.equal(resolve({ design: 'leaf', borrow: { slider: 'auto' } }).slider, 'block'); });
t('unknown values fall back with a warning', () => {
  const s = resolve({ design: 'nope', borrow: { slider: 'laser' }, touches: { season: 'always' } });
  assert.equal(s.design, 'margin'); assert.equal(s.slider, 'ruler'); assert.equal(s.touches.season, 'off'); assert.equal(s.warnings.length, 3);
});
t('touches come from the design and can be switched', () => {
  assert.equal(resolve({ design: 'shoji' }).touches.season, 'kanji');
  assert.equal(resolve({ design: 'margin', touches: { season: 'english' } }).touches.season, 'english');
});
t('describe names what was borrowed', () => {
  assert.equal(describe(resolve({ design: 'shoji' })), 'Shōji');
  assert.equal(describe(resolve({ design: 'shoji', borrow: { slider: 'ruler' } })), 'Shōji with Margin’s slider');
  assert.equal(describe(resolve({ design: 'leaf', borrow: { slider: 'block' } })), 'Leaf');   // borrowing your own part is no borrow
});
t('surprise always resolves cleanly', () => {
  for (let i = 1; i < 500; i++) { const s = resolve(surprise(i * 7919)); assert.deepEqual(s.warnings, []); assert.ok(s.borrowed.length >= 2 && s.borrowed.length <= 3, JSON.stringify(s.borrowed)); }
});
t('every variant can be reached from some design', () => {
  for (const [k, p] of Object.entries(PARTS)) for (const v of Object.keys(p.v)) assert.equal(resolve({ design: 'margin', borrow: { [k]: v } })[k], v);
});
console.log(`${n} passed`);
