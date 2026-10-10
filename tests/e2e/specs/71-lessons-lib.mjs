// Shared helpers for the tutorial specs (71-lessons-*.spec.mjs). Not a spec itself.
// Test enumeration (names, counts) comes from the lesson/tour source files loaded in Node;
// every assertion reads the live data from the page (RC.LESSONS / RC.Tours.TOURS).
import fs from 'node:fs';
import vm from 'node:vm';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');

function loadLessons() {
  const ctx = { RC: {} };
  vm.runInNewContext(fs.readFileSync(join(root, 'src/lang/basic/lessons-data.js'), 'utf8'), ctx);
  return JSON.parse(JSON.stringify(ctx.RC.LESSONS));
}
function loadTours() {
  const ctx = { RC: { UI: { h() {} }, escapeHtml: (s) => s }, window: {}, document: {} };
  vm.runInNewContext(fs.readFileSync(join(root, 'src/ide/tour.js'), 'utf8'), ctx);
  return ctx.RC.Tours.TOURS;
}
export const LESSONS = loadLessons();
export const TOURS = loadTours();

/** The practice file a lesson uses, per the engine's naming rule */
export const fileFor = (l) => 'C:\\LESSONS\\' + l.id.toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 8) + '.BAS';
export const header = (li) => 'Lesson ' + (li + 1) + ' · ' + LESSONS[li].unit;
export const plain = (html) => html.replace(/<br\s*\/?>/g, '\n').replace(/<[^>]+>/g, '');

// ---- page-side snapshots ------------------------------------------------------------------------
/** Snapshot of the tour popup */
export function tourInfo(p) {
  return p.ev(`(() => {
    const st = RC.Tours.active;
    if (!st) return null;
    const pop = st.pop;
    const h3 = pop.querySelector('h3');
    const btns = [...pop.querySelectorAll('.tour-foot button')].map((b) => ({ text: b.innerText.trim(), disabled: b.disabled }));
    const wait = pop.querySelector('.tour-wait');
    const hintP = [...pop.querySelectorAll('p.muted')].find((e) => e.innerText.includes('💡') || e.innerHTML.includes('💡'));
    const first = pop.firstElementChild;
    return {
      i: st.i, n: st.tour.steps.length, lessonTitle: st.tour.lessonTitle || null,
      header: first && first.tagName === 'DIV' && !first.classList.contains('tour-foot') ? first.innerText : null,
      title: h3 ? h3.innerText : null,
      body: h3 && h3.nextElementSibling ? h3.nextElementSibling.textContent : null,
      count: (pop.querySelector('.tour-foot .count') || {}).innerText || null,
      wait: wait ? wait.innerText : null,
      btns,
      hintHidden: hintP ? hintP.hidden : null,
      hintText: hintP ? hintP.textContent : null,
      inDom: document.body.contains(pop),
    };
  })()`);
}

/** Text of an HTML snippet as the browser renders it (entities decoded, tags dropped) */
export function htmlText(p, html) {
  return p.fn((s) => { const d = document.createElement('div'); d.innerHTML = s; return d.textContent; }, html);
}

/** Wait until the tour shows step `i` (0-based) with `title` */
export async function waitStep(p, i, title, ms = 6000) {
  await p.wait(`(() => { const st = RC.Tours.active; if (!st || st.i !== ${i}) return false; const h = st.pop.querySelector('h3'); return !!h && h.innerText === ${JSON.stringify(title)}; })()`, ms);
  await p.sleep(320); // the popup is re-placed 250ms after it is shown
}

/** Click a tour footer button whose label is exactly `label` (real mouse click) */
export async function tourButton(p, label) {
  const r = await p.fn((l) => {
    const norm = (t) => t.trim().replace(/\s+/g, ' ');
    const b = [...document.querySelectorAll('.tour-pop .tour-foot button')].find((x) => norm(x.innerText) === norm(l));
    if (!b) return null;
    const r = b.getBoundingClientRect();
    return [r.left + r.width / 2, r.top + r.height / 2];
  }, label);
  if (!r) throw new Error('tour button not found: ' + label);
  await p.clickAt(r[0], r[1]);
}

/** Click the n-th quiz option button */
export async function quizOption(p, idx) {
  const r = await p.fn((i) => {
    const h3 = document.querySelector('.tour-pop h3');
    const opts = h3.nextElementSibling.nextElementSibling;
    const b = opts.querySelectorAll('button')[i];
    const r = b.getBoundingClientRect();
    return [r.left + r.width / 2, r.top + r.height / 2];
  }, idx);
  await p.clickAt(r[0], r[1]);
}
export function quizFeedback(p) {
  return p.ev(`(() => { const h3 = document.querySelector('.tour-pop h3'); const fb = h3.nextElementSibling.nextElementSibling.nextElementSibling; return fb ? fb.textContent : null; })()`);
}
export function quizOptions(p) {
  return p.ev(`(() => { const h3 = document.querySelector('.tour-pop h3'); return [...h3.nextElementSibling.nextElementSibling.querySelectorAll('button')].map((b) => b.textContent); })()`);
}

/** Assert the spotlight hole surrounds the visible element matching `sel` (4px padding) */
export async function assertSpotlight(p, sel) {
  await p.sleep(300);
  const r = await p.fn((s) => {
    const hole = document.querySelector('.tour-hole');
    if (!hole) return { err: 'no hole' };
    const els = [...document.querySelectorAll(s)].filter((e) => e.getClientRects().length && e.getBoundingClientRect().width > 0);
    if (!els.length) return { err: 'no visible element for ' + s };
    const e = els[0].getBoundingClientRect();
    const hs = hole.style;
    return { left: parseFloat(hs.left), top: parseFloat(hs.top), width: parseFloat(hs.width), height: parseFloat(hs.height),
      eLeft: e.left - 4, eTop: e.top - 4, eWidth: e.width + 8, eHeight: e.height + 8 };
  }, sel);
  if (r.err) throw new Error(r.err);
  const near = (a, b) => Math.abs(a - b) <= 2;
  p.assert.ok(near(r.left, r.eLeft) && near(r.top, r.eTop) && near(r.width, r.eWidth) && near(r.height, r.eHeight),
    `spotlight for ${sel} should cover it: hole ${JSON.stringify([r.left, r.top, r.width, r.height])} vs element ${JSON.stringify([r.eLeft, r.eTop, r.eWidth, r.eHeight])}`);
}

/** Assert the popup sits fully inside the viewport */
export async function assertPopInView(p) {
  const r = await p.rect('.tour-pop');
  const vw = await p.ev('innerWidth'), vh = await p.ev('innerHeight');
  p.assert.ok(r && r.x >= 0 && r.y >= 0 && r.right <= vw + 1 && r.bottom <= vh + 1, 'tour popup inside viewport: ' + JSON.stringify(r));
}

// ---- IDE actions --------------------------------------------------------------------------------
export async function stopIfActive(p) {
  const st = await p.state();
  if (st === 'running' || st === 'waiting' || st === 'paused') { await p.stopProgram(); await p.waitState(['ended', 'error', 'idle', 'stopped'], 3000).catch(() => {}); }
}

/** Press F5 (real key) to run the active program */
export async function pressF5(p) {
  const before = await p.ev('RC.app.runCount || 0');
  await p.key('F5');
  await p.wait(`(RC.app.runCount || 0) > ${before}`, 3000);
}

/** Type text into the running program's keyboard buffer once it waits for input */
export async function answer(p, text) {
  await p.waitState(['waiting', 'ended', 'error', 'paused'], 8000);
  await p.ev(`RC.app.runner.keyboard.type(${JSON.stringify(text + '\n')}); RC.app.runner.kick()`);
  await p.sleep(120);
}

/** Run with F5, feed INPUT answers, wait for the end */
export async function run(p, inputs = [], opts = {}) {
  await stopIfActive(p);
  await pressF5(p);
  for (const a of inputs) await answer(p, a);
  if (opts.wait !== false) await p.waitState(opts.until || ['ended', 'error', 'paused'], opts.timeout || 15000);
  return p.state();
}

/** Real key press while the output screen has focus */
export async function screenKey(p, k, mods) {
  await p.ev("document.getElementById('screen').focus()");
  await p.key(k, mods || {});
  await p.sleep(40);
}

/** Edit the active editor's text as if typed */
export async function edit(p, fn) {
  const code = await p.code();
  const next = fn(code);
  if (next === code) throw new Error('edit made no change');
  await p.setCode(next);
}

/** Replace `a` with `b` (must exist) in the editor */
export const replace = (p, a, b) => edit(p, (c) => { if (!c.includes(a)) throw new Error('text not found: ' + a); return c.replace(a, b); });
/** Insert `text` + newline before the line starting with `before` */
export const insertBefore = (p, before, text) => edit(p, (c) => { const i = c.indexOf(before); if (i < 0) throw new Error('not found: ' + before); return c.slice(0, i) + text + '\n' + c.slice(i); });
/** Insert a line after the line containing `after` */
export const insertAfter = (p, after, text) => edit(p, (c) => { const i = c.indexOf(after); if (i < 0) throw new Error('not found: ' + after); const e = c.indexOf('\n', i); return c.slice(0, e + 1) + text + '\n' + c.slice(e + 1); });
export const append = (p, text) => edit(p, (c) => (c.endsWith('\n') ? c : c + '\n') + text + '\n');

/** Click the editor gutter next to the first line whose trimmed text equals/starts with `lineText` */
export async function clickGutter(p, lineText) {
  const r = await p.fn((t) => {
    const d = RC.app.active;
    const ed = d.editor;
    const lines = ed.getValue().split('\n');
    let line = lines.findIndex((l) => l.trim() === t.trim());
    if (line < 0) line = lines.findIndex((l) => l.trim().startsWith(t.trim()));
    if (line < 0) return null;
    ed.revealLine(line);
    const m = ed.main.getBoundingClientRect();
    const g = ed.gutter.getBoundingClientRect();
    return { x: g.left + g.width / 2, y: m.top + (line + 0.5) * ed.lineHeight - ed.ta.scrollTop, line };
  }, lineText);
  if (!r) throw new Error('line not found: ' + lineText);
  await p.sleep(50);
  await p.clickAt(r.x, r.y);
  return r.line;
}
export function bpLines(p, path) {
  return p.ev(`[...((RC.app.breakpoints.get(${JSON.stringify(path || '')}) || (RC.app.active && RC.app.breakpoints.get(RC.app.active.path)) || new Map()).keys())]`);
}
export async function clearBps(p) { await p.ev('RC.app.clearBreakpoints()'); await p.sleep(50); }

/**
 * Star Catcher autopilot: steer the basket (\_/ on row 23) under the lowest falling star
 * using real arrow keys until `doneExpr` is true.
 */
export async function catchStars(p, doneExpr, ms = 30000) {
  const t0 = Date.now();
  await p.ev("document.getElementById('screen').focus()");
  while (Date.now() - t0 < ms) {
    if (await p.ev(doneExpr)) return true;
    const s = await p.fn(() => {
      const lines = RC.app.runner.display.textLines().map((x) => RC.fromCP437(x, false));
      const basket = lines[22] ? lines[22].indexOf('\\_/') : -1;
      let star = -1, row = -1;
      for (let r = 21; r >= 2; r--) { const c = lines[r] ? lines[r].search(/[*\u2666]/) : -1; if (c >= 0) { star = c; row = r; break; } }
      return { basket, star, row };
    });
    if (s.basket >= 0 && s.star >= 0) {
      if (s.star < s.basket) await p.key('ArrowLeft', { after: 10 });
      else if (s.star > s.basket + 2) await p.key('ArrowRight', { after: 10 });
      else await p.sleep(20);
    } else await p.sleep(30);
  }
  return p.ev(doneExpr);
}

// ---- getting to a step ----------------------------------------------------------------------------
/**
 * Make sure lesson `li` is on step `si`. Normally the previous test left it there; after a failure
 * (page recovered) restart the lesson and jump, loading the latest practice code first.
 */
export async function ensureStep(p, li, si) {
  const L = LESSONS[li];
  const ok = await p.ev(`(() => { const st = RC.Tours.active; return !!st && st.tour.lessonTitle === ${JSON.stringify(header(li))} && st.i === ${si}; })()`);
  if (ok) return;
  await p.closeModals();
  await stopIfActive(p);
  await p.fn(async (li, si) => {
    RC.Lessons.start(RC.app, li);
    await new Promise((r) => setTimeout(r, 50));
    const st = RC.Tours.active;
    const L = RC.LESSONS[li];
    let j = si;
    while (j >= 0 && L.steps[j].code === undefined) j--;
    if (j >= 0 && j !== si) { st.i = j; await RC.Tours.show(st); }
    st.i = si;
    await RC.Tours.show(st);
  }, li, si);
  await waitStep(p, si, L.steps[si].title);
}

/** Open the Learn dialog with the toolbar button (or the Help menu) and click lesson `li`'s row */
export async function startFromDialog(p, li, via = 'toolbar') {
  await p.closeModals();
  await stopIfActive(p);
  // close a running lesson first (its popup would sit on top of the dialog)
  if (await p.exists('.tour-pop')) await tourButton(p, 'Close');
  if (via === 'menu') await p.menu('Help', 'Learn BASIC (Tutorial)…');
  else await p.click('#tbLearn');
  const title = await p.waitModal();
  p.assert.equal(title, 'Learn BASIC — Tutorial');
  const xy = await p.fn((i) => {
    const rows = [...document.querySelectorAll('.modal-back:last-child .list-row.clickable')];
    const r = rows[i];
    r.scrollIntoView({ block: 'center' });
    const b = r.getBoundingClientRect();
    return [b.left + 40, b.top + b.height / 2];
  }, li);
  await p.clickAt(xy[0], xy[1]);
  try { await p.waitGone('.modal-back'); } catch (e) {
    throw new Error('dialog did not close; open modals: ' + JSON.stringify(await p.ev("[...document.querySelectorAll('.modal-back')].map((m) => m.innerText.slice(0, 200))")));
  }
}

export const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
