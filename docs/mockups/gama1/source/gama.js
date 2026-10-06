// gama1: one bar, every part a setting. Requires alpha.js first.
function ticks(n, on, low) { let s = `<span class="ticks${low ? ' low' : ''}">`; for (let i = 0; i < n; i++) s += `<i class="${i < on ? '' : 'off'}"></i>`; return s + '</span>'; }
function sig(n) { let s = '<span class="sig">'; [4, 6, 8, 10].forEach((h, i) => s += `<i class="${i < n ? '' : 'off'}" style="height:${h}px"></i>`); return s + '</span>'; }

const OPTS = {
  seal:    ['stamp', 'workspace', 'none'],
  spaces:  ['folio', 'layout', 'kanji', 'dots'],
  title:   ['cell', 'byline', 'none'],
  clock:   ['stacked', 'inline', 'mono'],
  clockAt: ['center', 'right'],
  media:   ['cell', 'underline', 'none'],
  status:  ['cells', 'glyphs', 'numerals'],
  meters:  ['ticks', 'off'],
  notif:   ['count', 'stamps'],
  edge:    ['hairline', 'dayrule', 'rod', 'rodrule'],
  rules:   ['on', 'off'],
  height:  [32, 36, 40, 44],
  surface: ['solid', 'glass', 'inset'],
  position:['top', 'bottom'],
  panels:  ['sheets', 'scroll'],
};
const PRESETS = {
  Sheet:      { seal: 'stamp', spaces: 'folio', title: 'cell', clock: 'stacked', clockAt: 'center', media: 'cell', status: 'cells', meters: 'ticks', notif: 'count', edge: 'dayrule', rules: 'on', height: 36, surface: 'solid', panels: 'sheets' },
  Scroll:     { seal: 'workspace', spaces: 'layout', title: 'byline', clock: 'inline', clockAt: 'center', media: 'underline', status: 'glyphs', meters: 'off', notif: 'stamps', edge: 'rod', rules: 'off', height: 40, surface: 'solid', panels: 'scroll' },
  Hanko:      { seal: 'workspace', spaces: 'layout', title: 'byline', clock: 'stacked', clockAt: 'center', media: 'underline', status: 'cells', meters: 'ticks', notif: 'stamps', edge: 'rodrule', rules: 'on', height: 40, surface: 'solid', panels: 'scroll' },
  Quiet:      { seal: 'stamp', spaces: 'dots', title: 'none', clock: 'inline', clockAt: 'center', media: 'none', status: 'numerals', meters: 'off', notif: 'count', edge: 'hairline', rules: 'off', height: 32, surface: 'glass', panels: 'sheets' },
  Instrument: { seal: 'stamp', spaces: 'kanji', title: 'cell', clock: 'mono', clockAt: 'right', media: 'cell', status: 'cells', meters: 'ticks', notif: 'count', edge: 'dayrule', rules: 'on', height: 44, surface: 'solid', panels: 'sheets' },
  Islet:      { seal: 'workspace', spaces: 'kanji', title: 'byline', clock: 'inline', clockAt: 'center', media: 'underline', status: 'glyphs', meters: 'ticks', notif: 'stamps', edge: 'rodrule', rules: 'off', height: 36, surface: 'inset', panels: 'scroll' },
};
const STATE = {
  ws: [{ win: L.two }, { win: L.one }, { win: L.three, on: true, f: 0 }, { win: L.four, urg: true }, {}],
  active: 3, app: 'Alacritty', title: 'nvim', path: '~/code/hanko/', file: 'Bar.qml',
  time: '21:44', day: 'TUE', date: '06 OCT', dateLong: 'Tue 6 Oct',
  media: { song: 'Water Copy', artist: 'Hiroshi Yoshimura', p: .38 },
  vol: 62, net: 'Kumo', sigN: 3, bat: 91, notif: ['S', 'G', '火'],
};

function hbHTML(o, s) {
  o = Object.assign({}, PRESETS.Hanko, o); s = Object.assign({}, STATE, s);
  const R = o.rules === 'on' ? '<div class="rule"></div>' : '<div class="gap"></div>';
  const RF = o.rules === 'on' ? '<div class="rule full"></div>' : '<div class="gap"></div>';
  // seal
  const seal = o.seal === 'none' ? '' : `<div class="z" style="padding:0 10px 0 4px"><span class="seal">${o.seal === 'workspace' ? KNUM[s.active] : (o.sealGlyph || '印')}</span></div>${RF}`;
  // spaces
  let sp = '';
  if (o.spaces === 'folio') sp = `<div class="folio" style="padding:0 6px">${s.ws.map((w, i) => { const st = w.on ? 'on' : (w.win && w.win.length ? 'occ' : ''); const dots = w.win && !w.on ? `<span class="dots">${'<i></i>'.repeat(w.win.length)}</span>` : ''; return `<span class="ws ${st}">${w.on ? '<span class="lead">//</span>' : ''}${String(i + 1).padStart(2, '0')}${dots}${w.urg ? '<span class="urg"></span>' : ''}</span>`; }).join('')}</div>`;
  if (o.spaces === 'layout') sp = `<div class="spaces" style="margin:0 4px">${s.ws.map(glyph).join('')}</div>`;
  if (o.spaces === 'kanji') sp = `<div class="kws">${s.ws.map((w, i) => `<span class="${w.on ? 'on' : (w.win && w.win.length ? 'occ' : '')}">${KNUM[i + 1]}${w.urg ? '<span class="u"></span>' : ''}${w.win && !w.on ? `<span class="wc">${'<i></i>'.repeat(w.win.length)}</span>` : ''}</span>`).join('')}</div>`;
  if (o.spaces === 'dots') sp = `<div class="dws">${s.ws.map(w => `<i class="${w.on ? 'on' : (w.win && w.win.length ? 'occ' : '')} ${w.urg ? 'u' : ''}"></i>`).join('')}</div>`;
  sp = `<div class="z" style="padding:0 8px">${sp}</div>`;
  // title
  let tt = '';
  if (o.title === 'cell') tt = `${R}<div class="cell title"><div class="lab">${s.app} <span class="jp">窓</span></div><div class="val">${s.title} <span class="dim">${s.path}</span>${s.file}</div></div>`;
  if (o.title === 'byline') tt = `<div class="gap"></div><div class="z"><div class="byline"><span class="app">${s.app}</span><span class="tt">${s.title} · <b>${s.path}</b>${s.file}</span></div></div>`;
  // clock
  let ck = '';
  if (o.clock === 'stacked') ck = `<div class="clock"><span class="t">${s.time.replace(':', '<span class="c">:</span>')}</span><span class="d"><b>${s.day}</b><span>${s.date}</span></span></div>`;
  if (o.clock === 'inline') ck = `<div class="z" style="gap:10px;align-items:baseline;align-self:center;padding:0 12px"><span class="clk">${s.time.replace(':', '<span class="sep">:</span>')}</span><span class="dt">${s.dateLong}</span></div>`;
  if (o.clock === 'mono') ck = `<div class="z" style="padding:0 12px"><span class="mclk">${s.time}<small>${s.day} ${s.date}</small></span></div>`;
  // media
  let md = '';
  if (s.media && o.media === 'cell') md = `<div class="cell"><div class="lab">Now <span class="jp">再生</span></div><div class="val">${s.media.artist} <span class="dim">— ${s.media.song}</span></div></div>${R}`;
  if (s.media && o.media === 'underline') md = `<div class="z" style="padding:0 6px"><div class="np"><div class="s"><em>${s.media.song}</em> · ${s.media.artist}</div><div class="p"><b style="width:${s.media.p * 100}%"></b></div></div></div><div class="gap"></div>`;
  // status
  const T = o.meters === 'ticks';
  let stt = '';
  const low = s.bat <= 15;
  if (o.status === 'cells') stt = `
    <div class="cell"><div class="lab">Net <span class="jp">接続</span></div><div class="val">${s.net}${sig(s.sigN)}</div></div>${R}
    <div class="cell"><div class="lab">Vol <span class="jp">音</span></div><div class="val">${s.vol}<span class="unit">%</span>${T ? ticks(10, Math.round(s.vol / 10)) : ''}</div></div>${R}
    <div class="cell"><div class="lab">Bat <span class="jp">電</span></div><div class="val" ${low ? 'style="color:var(--alert)"' : ''}>${s.bat}<span class="unit">%</span>${T ? ticks(10, Math.round(s.bat / 10), low) : ''}</div></div>`;
  if (o.status === 'glyphs') stt = `<div class="z gs" style="gap:14px;padding:0 4px">
    <span class="g"><span class="k">音</span>${s.vol}${T ? ticks(5, Math.round(s.vol / 20)) : ''}</span>
    <span class="g"><span class="k">網</span>${s.net}</span>
    <span class="g ${low ? 'warn' : ''}"><span class="k">電</span>${s.bat}${T ? ticks(5, Math.round(s.bat / 20), low) : ''}</span></div>`;
  if (o.status === 'numerals') stt = `<div class="z"><div class="nus"><span><b>VOL</b>${s.vol}${T ? ' ' + ticks(5, Math.round(s.vol / 20)) : ''}</span><span class="sep">·</span><span><b>NET</b>${s.net}</span><span class="sep">·</span><span class="${low ? 'w' : ''}"><b>BAT</b>${s.bat}%${T ? ' ' + ticks(5, Math.round(s.bat / 20), low) : ''}</span></div></div>`;
  // notifications
  let nt = '';
  if (o.notif === 'count') nt = o.status === 'cells' ? `<div class="cell" style="align-items:center;padding:0 12px"><div class="lab">Inbox</div><div class="val" style="font-family:var(--mono);font-size:12px">${String(s.notif.length).padStart(2, '0')}${s.notif.length ? '<span class="cnt"><span class="d"></span></span>' : ''}</div></div>` : `<div class="z" style="padding:0 4px"><span class="cnt"><small>INBOX</small>${String(s.notif.length).padStart(2, '0')}${s.notif.length ? '<span class="d"></span>' : ''}</span></div>`;
  if (o.notif === 'stamps') nt = `<div class="z" style="padding:0 4px">${s.notif.length ? `<div class="stamps ${o.fan ? 'fan' : ''}">${s.notif.map((x, i) => `<span class="st" style="transform:rotate(${[-6, 4, -2, 3][i % 4]}deg)">${x}</span>`).join('')}<span class="n">${String(s.notif.length).padStart(2, '0')}</span></div>` : '<span class="optlab">QUIET</span>'}</div>`;
  // edge
  let edge = '';
  const frac = (() => { const [h, m] = s.time.split(':').map(Number); return (h * 60 + m) / 1440; })();
  if (o.edge === 'dayrule') { edge = `<div class="dayrule"><div class="base"></div><div class="elapsed" style="width:${frac * 100}%"></div>`; for (let i = 1; i < 24; i++) edge += `<div class="tk${i % 6 === 0 ? ' maj' : ''}" style="left:${i / 24 * 100}%"></div>`; edge += `<div class="now" style="left:${frac * 100}%"></div></div>`; }
  if (o.edge === 'rod') edge = `<div class="rod"><span class="grip"></span></div>`;
  if (o.edge === 'rodrule') { edge = `<div class="rod rodrule"><span class="done" style="width:${frac * 100}%"></span>`; for (let i = 1; i < 24; i++) edge += `<span class="rtk ${i % 6 === 0 ? 'm' : ''}" style="left:${i / 24 * 100}%"></span>`; edge += `<span class="rnow" style="left:${frac * 100}%"></span><span class="grip"></span></div>`; }
  const cls = ['hb', 'h' + o.height, o.surface === 'solid' ? '' : o.surface, o.position === 'bottom' ? 'bottom' : '', 'e-' + o.edge].join(' ');
  const center = o.clockAt === 'center' ? ck : '';
  const rightClock = o.clockAt === 'right' ? `${R}${ck}` : '';
  return `<div class="${cls}" style="height:${o.height}px">
    <div class="z zl">${seal}${sp}${tt}</div>
    <div class="z zc">${center}</div>
    <div class="z zr">${md}${stt}${R}${nt}${rightClock}</div>
    ${edge}</div>`;
}
function mountHB(host, o, s) { host.innerHTML = hbHTML(o, s); return host.firstElementChild; }
