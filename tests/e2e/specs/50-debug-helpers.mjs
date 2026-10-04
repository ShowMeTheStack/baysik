// Shared helpers for the 50-debug-* specs (debugger and bottom panels). Not a spec file itself.
export const PATH = 'C:\\MYPROGS\\E2E.BAS';

/** Reset debugger state between tests: stop program, clear breakpoints/watches, close popups. */
export async function reset(p) {
  await p.fn(() => {
    const app = RC.app;
    document.querySelectorAll('.modal-back').forEach((m) => m.remove());
    RC.UI.closeMenus();
    if (app.runner.vm && ['running', 'waiting', 'paused'].includes(app.runner.state)) app.stop();
    app.callout.hide();
    app.clearBreakpoints();
    app.panels.watches.length = 0;
    app.panels.saveWatches();
    app.panels.refreshWatch();
    if (app.runner.animate) app.setAnimate(false);
    if (app.settings.speed !== 0) app.setSpeed(0);
    app.selFrame = null;
    if (app.panels.varsFilter) app.panels.varsFilter.value = '';
    if (app.panels.varTree) { app.panels.varTree.state.expanded.clear(); app.panels.varTree.state.pages.clear(); }
    app.callout.state.expanded.clear(); app.callout.state.pages.clear();
  });
  await p.sleep(30);
}

/** Open `code` in the scratch file without running it. */
export async function load(p, code, path = PATH) {
  await p.newFile(path, code);
  await p.fn(() => RC.app.active.editor.render());
}

/** 0-based line index of the first line containing `needle` in the active editor */
export async function lineOf(p, needle, nth = 0) {
  return p.fn((n, k) => { const ls = RC.app.active.editor.lines(); let c = 0; for (let i = 0; i < ls.length; i++) if (ls[i].includes(n)) { if (c++ === k) return i; } return -1; }, needle, nth);
}

/** Load code, set breakpoints on lines containing the given needles (or numeric line indexes), run until paused. */
export async function debug(p, code, bps = [], opts = {}) {
  await load(p, code, opts.path || PATH);
  for (const b of bps) {
    const line = typeof b === 'number' ? b : await lineOf(p, b);
    if (line < 0) throw new Error('no line for breakpoint ' + b);
    await p.fn((path, l) => RC.app.toggleBreakpoint(path, l), opts.path || PATH, line);
  }
  await p.ev('RC.app.run()');
  if (opts.input) { await p.sleep(80); await p.ev(`RC.app.runner.keyboard.type(${JSON.stringify(opts.input)}); RC.app.runner.kick()`); }
  await p.waitState(opts.until || 'paused', opts.timeout || 8000);
  await p.sleep(40);
}

/** Line (0-based) of the paused top frame */
export const pausedLine = (p) => p.ev('(RC.app.runner.vm.framePos() || {}).line');
/** Exec marker line in the active editor model */
export const execMark = (p) => p.ev('RC.app.active.editor.marks.exec');
/** Index of gutter line drawn with a given class in the visible editor (after rendering) */
export async function gutterIndex(p, cls) {
  await p.fn(() => RC.app.active.editor.render());
  return p.fn((c) => [...RC.app.active.editor.inner.children].findIndex((e) => e.classList.contains(c)), cls);
}
export async function gutterClasses(p, line) {
  await p.fn(() => RC.app.active.editor.render());
  return p.fn((l) => { const e = RC.app.active.editor.inner.children[l]; return e ? e.className : null; }, line);
}
export async function lineClasses(p, line) {
  await p.fn(() => RC.app.active.editor.render());
  return p.fn((l) => { const e = RC.app.active.editor.hl.children[l]; return e ? e.className : null; }, line);
}

/** Breakpoint lines (sorted) for a path */
export const bpLines = (p, path = PATH) => p.fn((pa) => [...(RC.app.breakpoints.get(pa) || new Map()).keys()].sort((a, b) => a - b), path);
export const bpOf = (p, line, path = PATH) => p.fn((pa, l) => { const m = RC.app.breakpoints.get(pa); const b = m && m.get(l); return b ? { cond: b.cond, disabled: b.disabled } : null; }, path, line);

/** Real mouse click on the gutter number of a line in the active editor */
export async function gutterPoint(p, line) {
  return p.fn((l) => {
    const ed = RC.app.active.editor;
    ed.revealLine(l);
    const el = ed.inner.children[l];
    const r = el.getBoundingClientRect();
    return [r.left + r.width / 2, r.top + r.height / 2];
  }, line);
}
export async function clickGutter(p, line, opts = {}) {
  const [x, y] = await gutterPoint(p, line);
  await p.clickAt(x, y, opts);
  await p.sleep(40);
}

/** Put the editor cursor on a line */
export async function cursorTo(p, line, col = 0) {
  await p.fn((l, c) => RC.app.active.editor.setCursor(l, c), line, col);
  await p.sleep(20);
}

/** Screen coordinates of a character in the active editor textarea */
export async function charPoint(p, line, col) {
  return p.fn((l, c) => {
    const ed = RC.app.active.editor;
    ed.revealLine(l);
    const r = ed.ta.getBoundingClientRect();
    const lh = ed.lineHeight, cw = ed.charWidth;
    return [r.left + 8 + (c + 0.5) * cw - ed.ta.scrollLeft, r.top + (l + 0.5) * lh - ed.ta.scrollTop];
  }, line, col);
}
/** Hover the n-th occurrence of `word` on `line` (col offset inside the word) and wait for the callout */
export async function hoverWord(p, line, word, opts = {}) {
  const col = await p.fn((l, w, nth) => { const t = RC.app.active.editor.getLine(l); let i = -1; for (let k = 0; k <= nth; k++) i = t.indexOf(w, i + 1); return i; }, line, word, opts.nth || 0);
  if (col < 0) throw new Error(`word ${word} not on line ${line}`);
  const [x, y] = await charPoint(p, line, col + (opts.offset || 0));
  // move a little first so mousemove fires even if the pointer is already there
  await p.mouse('mouseMoved', x + 1, y);
  await p.mouse('mouseMoved', x, y);
  if (opts.expectNone) { await p.sleep(600); return [x, y]; }
  await p.wait("!!document.querySelector('.ed-callout')", 3000);
  await p.sleep(30);
  return [x, y];
}

/** Mark an element (found in page by fn source returning element) with data-e2e and return the selector */
export async function mark(p, findSrc, tag = 'x') {
  const ok = await p.ev(`(() => { document.querySelectorAll('[data-e2e="${tag}"]').forEach(e => e.removeAttribute('data-e2e')); const el = (${findSrc})(); if (!el) return false; el.setAttribute('data-e2e', '${tag}'); return true; })()`);
  if (!ok) throw new Error('mark: element not found: ' + findSrc);
  return `[data-e2e="${tag}"]`;
}

/** Variable rows in a container: [{name, type, value, changed, editable}] */
export async function varRows(p, container = '.bpanel.active') {
  return p.fn((c) => [...document.querySelectorAll(c + ' .vrow:not(.pager)')].map((r) => ({
    name: r.querySelector('.vn > span:not(.twisty):not(.vbadge)') ? r.querySelector('.vn > span:not(.twisty):not(.vbadge)').innerText : '',
    badges: [...r.querySelectorAll('.vbadge')].map((b) => b.innerText),
    type: r.querySelector('.vt').innerText,
    value: r.querySelector('.vv').textContent,
    changed: r.querySelector('.vv').classList.contains('changed'),
    editable: r.querySelector('.vv').classList.contains('editable'),
    twisty: r.querySelector('.twisty').innerText,
  })), container);
}
export async function varVal(p, name, container = '.bpanel.active') {
  const rows = await varRows(p, container);
  const r = rows.find((x) => x.name === name);
  return r ? r.value : undefined;
}
/** Selector for the n-th row with a given variable name */
export async function rowSel(p, name, part = '.vv', container = '.bpanel.active', nth = 0) {
  return mark(p, `() => [...document.querySelectorAll(${JSON.stringify(container + ' .vrow')})].filter(r => { const s = r.querySelector('.vn > span:not(.twisty):not(.vbadge)'); return s && s.innerText === ${JSON.stringify(name)}; })[${nth}]?.querySelector(${JSON.stringify(part)})`, 'row');
}
/** Click a variable's value, type new text, press Enter (or other key) */
export async function editVar(p, name, text, opts = {}) {
  const container = opts.container || '.bpanel.active';
  const sel = await rowSel(p, name, '.vv', container, opts.nth || 0);
  await p.click(sel);
  await p.wait(`!!document.querySelector(${JSON.stringify(container + ' .vv input')})`, 2000);
  await p.fn((c, t) => { const i = document.querySelector(c + ' .vv input'); i.value = t; }, container, text);
  await p.key(opts.key || 'Enter');
  await p.sleep(60);
}
/** Click the twisty of a row (expand/collapse) */
export async function toggleRow(p, name, container = '.bpanel.active', nth = 0) {
  const sel = await rowSel(p, name, '.twisty', container, nth);
  await p.click(sel);
  await p.sleep(40);
}
export async function vsecTitles(p, container = '.bpanel.active') {
  return p.texts(container + ' .vsec');
}

/** Stack rows: [{depth, name, loc, sel}] */
export async function stackRows(p) {
  await p.ev("RC.app.panels.show('stack')");
  return p.fn(() => [...document.querySelectorAll('.bpanel.active .frame-row')].map((r) => ({
    depth: r.children[0].innerText, name: r.children[1].innerText, loc: r.children[2].innerText, sel: r.classList.contains('sel'),
  })));
}

/** Type into the Immediate window */
export async function imm(p, text) {
  await p.ev("RC.app.panels.show('immediate')");
  await p.sleep(20);
  await p.click('.bpanel.active .imm-input input');
  await p.fn((t) => { const i = document.querySelector('.bpanel.active .imm-input input'); i.value = t; }, text);
  await p.key('Enter');
  await p.sleep(40);
}
export async function immLog(p) { return p.fn(() => [...document.querySelectorAll('.imm-log > div')].map((d) => ({ cls: d.className, text: d.innerText }))); }
export async function immLast(p) { const l = await immLog(p); return l[l.length - 1]; }

/** Press a debug key with focus on the editor (not the program screen) */
export async function dkey(p, k, mods = {}) {
  await p.key(k, mods);
  await p.sleep(30);
}
/** Step and wait for pause (or other state) */
export async function step(p, k = 'F8', mods = {}, until = 'paused') {
  const n0 = await p.ev('RC.app.runner.vm ? RC.app.runner.vm.statementsExecuted : 0');
  await p.key(k, mods);
  await p.waitState(until);
  await p.sleep(30);
  return n0;
}
