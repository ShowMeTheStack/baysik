// Captures the screenshots used in README.md (docs/images/*.png) from the built index.html.
// usage: node build.mjs && node tools/shoot.mjs [name ...]
import { mkdirSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { launch } from './cdp.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const out = join(root, 'docs', 'images');
mkdirSync(out, { recursive: true });
const only = process.argv.slice(2);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function page(opts = {}) {
  const b = await launch({ width: opts.w || 1440, height: opts.h || 900, mobile: opts.mobile });
  await b.send('Page.addScriptToEvaluateOnNewDocument', {
    source: `try { if (!localStorage.getItem('baysik.settings')) localStorage.setItem('baysik.settings', ${JSON.stringify(JSON.stringify(Object.assign({ firstRun: false }, opts.settings || {})))}); } catch (e) {}`,
  });
  if (opts.mobile) await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 });
  await b.goto('');
  await b.waitFor('window.__baysikReady === true', 20000);
  await sleep(400);
  const p = {
    b,
    ev: (e) => b.eval(e),
    async open(path) { await b.eval(`RC.app.openFile(${JSON.stringify(path)})`); await sleep(250); },
    async lib(path) { await b.eval(`RC.Library.open(RC.app, ${JSON.stringify(path)})`); await sleep(600); },
    async run() { await b.eval('RC.app.run()'); },
    async state(s, ms = 15000) { await b.waitFor(`${JSON.stringify([].concat(s))}.includes(RC.app.runner.state)`, ms); },
    async type(t) { await b.eval(`RC.app.runner.keyboard.type(${JSON.stringify(t)}); RC.app.runner.kick()`); },
    async bp(path, re) { await b.eval(`(() => { const d = RC.app.docByPath(${JSON.stringify(path)}); const i = d.editor.lines().findIndex(l => ${re}.test(l)); RC.app.toggleBreakpoint(d.path, i); })()`); },
    async shot(name, clipSel) {
      let params = { format: 'png' };
      if (clipSel) {
        const r = await b.eval(`(() => { const r = document.querySelector(${JSON.stringify(clipSel)}).getBoundingClientRect(); return {x: r.left, y: r.top, width: r.width, height: r.height}; })()`);
        params.clip = Object.assign(r, { scale: 1 });
      }
      const res = await b.send('Page.captureScreenshot', params);
      writeFileSync(join(out, name + '.png'), Buffer.from(res.data, 'base64'));
      console.log('saved', name);
    },
    close: () => b.close(),
  };
  return p;
}

const shots = {
  // The whole IDE: a graphics program running next to its source
  async overview() {
    const p = await page();
    await p.open('C:\\SAMPLES\\SPIRAL.BAS');
    await p.run(); await sleep(2500);
    await p.ev("RC.app.active.editor.setCursor(8, 0)");
    await p.shot('overview');
    await p.close();
  },
  // Paused inside a recursive FUNCTION: call stack, exec line, variables
  async debugger() {
    const p = await page();
    await p.open('C:\\SAMPLES\\FACTORL.BAS');
    await p.bp('C:\\SAMPLES\\FACTORL.BAS', /Factorial# = 1 /);
    await p.ev("RC.app.run()");
    await p.state('paused');
    await p.ev("RC.app.runner.resume(); RC.app.runner.kick()");
    await p.ev("(async () => { for (let i = 0; i < 6; i++) { await new Promise(r => setTimeout(r, 150)); if (RC.app.runner.state === 'paused') { RC.app.runner.resume(); RC.app.runner.kick(); } } })()");
    await sleep(1200);
    await p.state('paused');
    await p.ev("RC.app.panels.show('stack')");
    await sleep(300);
    await p.shot('debugger-callstack');
    await p.ev("RC.app.selectFrame(2); RC.app.panels.show('vars')");
    await sleep(300);
    await p.shot('debugger-frames');
    await p.close();
  },
  // Hover callout with a 2-D array unfolded, records and a watch
  async callout() {
    const p = await page();
    const prog = `TYPE Hero
  nm AS STRING * 8
  hp AS INTEGER
  x AS INTEGER
  y AS INTEGER
END TYPE
CONST ROWS = 3, COLS = 4
DIM board(1 TO ROWS, 1 TO COLS) AS INTEGER
DIM party(1 TO 2) AS Hero
party(1).nm = "ADA": party(1).hp = 42: party(1).x = 3
party(2).nm = "GRACE": party(2).hp = 37: party(2).y = 5
FOR r = 1 TO ROWS
    FOR c = 1 TO COLS
        board(r, c) = r * 10 + c
    NEXT c
NEXT r
score& = 0
FOR r = 1 TO ROWS: score& = score& + board(r, 2): NEXT r
PRINT "Score:"; score&
`;
    await p.ev(`(() => { const v = RC.app.vfs; v.writeFile('C:\\\\MYPROGS\\\\BOARD.BAS', RC.app.encodeText(${JSON.stringify(prog)}), {trusted: true}); RC.app.openFile('C:\\\\MYPROGS\\\\BOARD.BAS'); })()`);
    await sleep(300);
    await p.bp('C:\\MYPROGS\\BOARD.BAS', /^score& = 0/);
    await p.ev("RC.app.panels.addWatch('board(2, 3) + party(1).hp')");
    await p.run(); await p.state('paused');
    await p.ev("RC.app.panels.show('vars')");
    await sleep(200);
    // hover "board" on line 14
    const at = await p.ev("(() => { const e = RC.app.active.editor; const r = e.ta.getBoundingClientRect(); return [r.left + 8 + 9.5 * e.charWidth, r.top + 13.5 * e.lineHeight - e.ta.scrollTop]; })()");
    await p.b.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: at[0], y: at[1] });
    await sleep(600);
    await p.ev("(() => { const tw = [...document.querySelectorAll('.ed-callout .twisty')].filter(t => t.textContent === '▸'); if (tw[1]) tw[1].click(); })()");
    await sleep(200);
    const cr = await p.ev("(() => { const r = document.querySelector('.ed-callout').getBoundingClientRect(); return [r.left + 30, r.top + 10]; })()");
    await p.b.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: cr[0], y: cr[1] });
    await sleep(200);
    await p.shot('hover-callout');
    await p.ev("RC.app.callout.hide(); RC.app.panels.show('watch')");
    await sleep(200);
    await p.shot('watch');
    await p.close();
  },
  // Output screens in different modes (screen area only)
  async modes() {
    const list = [
      ['mode13-mandelbrot', 'MANDEL.BAS', 4000],
      ['mode12-hanoi', 'HANOI.BAS', 1500],
      ['mode12-turtle', 'TURTLE.BAS', 1200],
      ['mode0-colors', 'COLORS.BAS', 800],
      ['mode7-sprites', 'SPRITES.BAS', 1500],
      ['mode13-plasma', 'PLASMA.BAS', 3000],
    ];
    for (const [name, file, wait] of list) {
      if (only.length && !only.includes('modes') && !only.includes(name)) continue;
      const p = await page();
      await p.open('C:\\SAMPLES\\' + file);
      await p.run(); await sleep(wait);
      await p.shot(name, '#screenFrame');
      await p.close();
    }
    const libShots = [
      ['mode1-cga-artillery', 'CLASSIC\\ARTILLRY.BAS', 2500, '45\r70\r'],
      ['mode12-fern', 'FRACTALS\\FERN.BAS', 3500, ''],
      ['mode9-piechart', 'GRAPHICS\\PIECHART.BAS', 1200, ''],
      ['mode0-snake', 'GAMES\\SNAKE.BAS', 2500, ''],
    ];
    for (const [name, path, wait, keys] of libShots) {
      if (only.length && !only.includes('modes') && !only.includes(name)) continue;
      const p = await page();
      await p.lib(path);
      await p.run(); await sleep(800);
      if (keys) await p.type(keys);
      await sleep(wait);
      await p.shot(name, '#screenFrame');
      await p.close();
    }
  },
  // The classic GW-BASIC console: numbered lines, LIST, RUN
  async console() {
    const p = await page();
    await p.ev("RC.app.console.toggle(true)");
    await sleep(300);
    const lines = ['10 REM Fahrenheit to Celsius', '20 FOR F = 32 TO 212 STEP 30', '30 PRINT USING "###F = ###.#C"; F; (F - 32) * 5 / 9', '40 NEXT F', 'LIST', 'RUN'];
    for (const l of lines) { await p.ev(`(() => { for (const ch of ${JSON.stringify(l)}) RC.app.console.handleKey(ch); RC.app.console.handleKey('\\r'); })()`); await sleep(300); }
    await sleep(800);
    await p.shot('gw-console');
    await p.close();
  },
  async library() {
    const p = await page();
    await p.ev("void RC.Library.browse(RC.app, 'GAMES')");
    await sleep(1200);
    await p.shot('library');
    await p.close();
  },
  async lessons() {
    const p = await page();
    await p.ev("void RC.Lessons.browse(RC.app)");
    await sleep(800);
    await p.shot('learn');
    await p.ev("document.querySelectorAll('.modal-back').forEach(m => m.remove()); RC.Lessons.start(RC.app, RC.LESSONS.findIndex(l => l.id === 'for-next'))");
    await sleep(800);
    await p.ev("(() => { const n = document.querySelector('.tour-pop .btn.primary'); if (n) n.click(); })()");
    await sleep(700);
    await p.shot('lesson');
    await p.close();
  },
  async tour() {
    const p = await page();
    await p.ev("RC.Tours.start(RC.app, 'welcome')");
    await sleep(500);
    for (let i = 0; i < 6; i++) { await p.ev("document.querySelector('.tour-pop .btn.primary').click()"); await sleep(250); }
    await sleep(500);
    await p.shot('tour');
    await p.close();
  },
  async help() {
    const p = await page();
    await p.ev("RC.Help.open(RC.app, 'CIRCLE')");
    await sleep(600);
    await p.shot('help');
    await p.close();
  },
  async themes() {
    for (const th of ['dark', 'light', 'amber']) {
      if (only.length && !only.includes('themes') && !only.includes('theme-' + th)) continue;
      const p = await page({ settings: { theme: th } });
      await p.open('C:\\SAMPLES\\SNAKE.BAS');
      await p.ev("RC.app.active.editor.setCursor(18, 0)");
      await sleep(300);
      await p.shot('theme-' + th);
      await p.close();
    }
  },
  async mobile() {
    const p = await page({ w: 390, h: 844, mobile: true });
    await p.lib('GAMES\\BREAKOUT.BAS');
    await p.run(); await sleep(2500);
    await p.shot('phone-running');
    await p.ev("RC.app.setMobileView('editor')");
    await sleep(300);
    await p.shot('phone-code');
    await p.close();
    const t = await page({ w: 1024, h: 768, mobile: true });
    await t.open('C:\\SAMPLES\\CLOCK.BAS');
    await t.run(); await sleep(1500);
    await t.ev("RC.app.toggleDrawer(true)");
    await sleep(500);
    await t.shot('tablet-drawer');
    await t.close();
  },
  async share() {
    const p = await page();
    await p.open('C:\\SAMPLES\\MULTI\\MAIN.BAS');
    await p.ev("void RC.app.shareDialog('C:\\\\SAMPLES\\\\MULTI')");
    await sleep(800);
    await p.shot('share');
    await p.close();
  },
  async files() {
    const p = await page();
    await p.open('C:\\SAMPLES\\PHONEBK.BAS');
    await p.run(); await sleep(400);
    await p.type('2\nAda Lovelace\n555-1815\n2\nAlan Turing\n555-1912\n1\n');
    await sleep(1200);
    await p.ev("RC.app.expandedDirs.add('C:\\\\LIBRARY'); RC.app.renderExplorer()");
    await sleep(200);
    await p.shot('files');
    await p.close();
  },
  async errors() {
    const p = await page();
    const prog = "' A deliberate mistake: the loop divides by zero on its last pass\nFOR i = 5 TO 0 STEP -1\n    PRINT 100 / i\nNEXT i\n";
    await p.ev(`(() => { const v = RC.app.vfs; v.writeFile('C:\\\\MYPROGS\\\\OOPS.BAS', RC.app.encodeText(${JSON.stringify(prog)}), {trusted: true}); RC.app.openFile('C:\\\\MYPROGS\\\\OOPS.BAS'); })()`);
    await sleep(300);
    await p.run(); await p.state('error');
    await sleep(500);
    await p.ev("document.querySelectorAll('.toast').forEach(t => t.remove()); RC.app.panels.show('vars')");
    await sleep(200);
    await p.shot('runtime-error');
    await p.close();
  },
};

for (const [name, fn] of Object.entries(shots)) {
  if (only.length && !only.includes(name) && !(name === 'modes' && only.some((o) => /^mode/.test(o))) && !(name === 'themes' && only.some((o) => /^theme-/.test(o)))) continue;
  try { await fn(); } catch (e) { console.error('FAILED', name, e.message); }
}
