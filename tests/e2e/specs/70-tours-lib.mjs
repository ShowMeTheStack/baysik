// Shared helpers for the 70-tours-* specs (not a spec file itself).

/** Expected tour data, written from src/ide/tour.js (sel = spotlight target, null = centered). */
export const TOURS = {
  welcome: {
    title: 'Welcome to the IDE',
    steps: [
      { sel: null, title: 'Welcome to Baysik!' },
      { sel: '#menubar', title: 'Menus' },
      { sel: '#tbRun', title: 'Run your program' },
      { sel: '#tbInto', title: 'Step through code' },
      { sel: '#tbSpeed', title: 'Speed' },
      { sel: '#editorArea', title: 'The editor' },
      { sel: '#screenArea', title: 'The output screen' },
      { sel: '#bottom', title: 'Panels' },
      { sel: '#explorer', title: 'Files' },
      { sel: '#tbExamples', title: 'Examples' },
      { sel: '#tbTour', title: 'More tours' },
    ],
  },
  first: {
    title: 'Your First Program',
    steps: [
      { sel: null, title: 'Your first program' },
      { sel: '#editorArea', title: 'Say hello', wait: 'Waiting for a PRINT line…' },
      { sel: '#tbRun', title: 'Run it!', wait: 'Waiting for the program to run…' },
      { sel: '#screenArea', title: 'It works!' },
      { sel: '#editorArea', title: 'Ask a question', wait: 'Waiting for an INPUT line…' },
      { sel: '#screenArea', title: 'Run and answer', wait: 'Waiting for the program to finish…' },
      { sel: '#editorArea', title: 'Loops', wait: 'Waiting for a FOR…NEXT loop to run…' },
      { sel: null, title: 'You are a programmer!' },
    ],
  },
  debug: {
    title: 'Debugging',
    steps: [
      { sel: null, title: 'Become a bug detective' },
      { sel: '.ed-gutter', title: 'Set a breakpoint', wait: 'Waiting for the breakpoint…' },
      { sel: '#tbRun', title: 'Run to the breakpoint', wait: 'Waiting for the pause…' },
      { sel: '#bottom', title: 'The call stack' },
      { sel: '#bottom', title: 'Variables' },
      { sel: '#editorArea', title: 'Hover to peek' },
      { sel: '#tbInto', title: 'Step', wait: 'Waiting for a step…' },
      { sel: '#bottom', title: 'Immediate window' },
      { sel: '#tbRun', title: 'Continue' },
    ],
  },
  graphics: {
    title: 'Graphics & Sound',
    steps: [
      { sel: null, title: 'Pixels and beeps' },
      { sel: '#editorArea', title: 'Graphics statements', wait: 'Waiting for you to run it…' },
      { sel: '#screenArea', title: 'Try other modes' },
      { sel: '#tbExamples', title: 'More' },
    ],
  },
  files: {
    title: 'Files & Sharing',
    steps: [
      { sel: '#explorer', title: 'Your disk' },
      { sel: '#explorerActions', title: 'Import and export' },
      { sel: '#explorerActions', title: 'Share a project' },
      { sel: '#menubar', title: 'Save' },
    ],
  },
  gw: {
    title: 'Classic GW-BASIC Console',
    steps: [
      { sel: null, title: 'Back to 1985' },
      { sel: '#screenArea', title: 'The console', wait: 'Waiting for RUN…' },
      { sel: '#screenArea', title: 'Break!', wait: 'Waiting for Ctrl+C…' },
      { sel: '#screenArea', title: 'LIST and edit' },
      { sel: '#editorArea', title: 'Same program, two views' },
    ],
  },
};

/** Snapshot of the tour popover. */
export function pop(p) {
  return p.fn(() => {
    const el = document.querySelector('.tour-pop');
    if (!el) return null;
    const r = el.getBoundingClientRect();
    const btns = [...el.querySelectorAll('.tour-foot button')].map((b) => ({ text: b.innerText.trim(), disabled: b.disabled, primary: b.classList.contains('primary') }));
    const w = el.querySelector('.tour-wait');
    return {
      title: (el.querySelector('h3') || {}).innerText || '',
      count: (el.querySelector('.tour-foot .count') || {}).innerText || '',
      text: el.innerText,
      buttons: btns,
      labels: btns.map((b) => b.text),
      wait: w ? w.innerText : null,
      rect: { x: r.left, y: r.top, right: r.right, bottom: r.bottom, w: r.width, h: r.height },
      vw: innerWidth, vh: innerHeight,
      overlays: document.querySelectorAll('.tour-pop').length + document.querySelectorAll('.tour-hole').length,
    };
  });
}

export const isOpen = (p) => p.ev("!!document.querySelector('.tour-pop') && !!document.querySelector('.tour-hole')");

/** Wait until the popover shows step i (1-based) of n. */
export async function waitStep(p, i, n, ms = 6000) {
  await p.wait(`(() => { const c = document.querySelector('.tour-pop .tour-foot .count'); return c && c.innerText.trim() === ${JSON.stringify(`${i} / ${n}`)}; })()`, ms);
}

/** Start a tour through the internals (setup) and wait for its first step. */
export async function start(p, id) {
  await p.ev(`RC.Tours.start(RC.app, ${JSON.stringify(id)})`);
  await waitStep(p, 1, TOURS[id].steps.length);
}

/** Click a popover footer button by its label (real mouse click). */
export async function btn(p, label) {
  await p.click('.tour-pop .tour-foot button', label);
}

/** Start tour `id` and advance with real clicks on the primary button to step idx (0-based). */
export async function gotoStep(p, id, idx) {
  const n = TOURS[id].steps.length;
  await start(p, id);
  for (let k = 0; k < idx; k++) {
    await p.click('.tour-pop .tour-foot button.primary');
    await waitStep(p, k + 2, n);
  }
  await p.sleep(80);
}

/** Wait until the spotlight hole surrounds `sel` (target rect grown by 4px on every side). */
export async function waitHoleAround(p, sel, ms = 3000) {
  return p.wait(`(() => {
    const h = document.querySelector('.tour-hole'), t = document.querySelector(${JSON.stringify(sel)});
    if (!h || !t) return false;
    const a = h.getBoundingClientRect(), b = t.getBoundingClientRect();
    if (b.width === 0 || b.height === 0) return false;
    const near = (x, y) => Math.abs(x - y) <= 1.5;
    return near(a.left, b.left - 4) && near(a.top, b.top - 4) && near(a.right, b.right + 4) && near(a.bottom, b.bottom + 4);
  })()`, ms);
}

/** Wait until the hole is a zero-size point at the viewport centre (no target). */
export async function waitHoleCentered(p, ms = 3000) {
  return p.wait(`(() => {
    const h = document.querySelector('.tour-hole'); if (!h) return false;
    const a = h.getBoundingClientRect();
    return a.width === 0 && a.height === 0 && Math.abs(a.left - innerWidth / 2) <= 1 && Math.abs(a.top - innerHeight / 2) <= 1;
  })()`, ms);
}

/** Wait until the popover lies fully inside the viewport. */
export async function waitPopInside(p, ms = 3000) {
  return p.wait(`(() => {
    const e = document.querySelector('.tour-pop'); if (!e) return false;
    const r = e.getBoundingClientRect();
    return r.width > 0 && r.height > 0 && r.left >= 0 && r.top >= 0 && r.right <= innerWidth && r.bottom <= innerHeight;
  })()`, ms);
}

/** Wait until the popover is horizontally centred in the viewport. */
export async function waitPopCentered(p, ms = 3000) {
  return p.wait(`(() => {
    const e = document.querySelector('.tour-pop'); if (!e) return false;
    const r = e.getBoundingClientRect();
    return Math.abs((r.left + r.right) / 2 - innerWidth / 2) <= 2 && Math.abs((r.top + r.bottom) / 2 - innerHeight / 2) <= 2;
  })()`, ms);
}

/** Pick a point inside the element (CSS selector, or a JS expression when `isExpr`) that is not covered
 * by the tour popover and actually hit-tests to that element; returns [x, y]. */
export async function freePoint(p, sel, isExpr = false) {
  const getter = isExpr ? sel : `document.querySelector(${JSON.stringify(sel)})`;
  const r = await p.ev(`(() => {
    const el = ${getter};
    if (!el) return null;
    const t = el.getBoundingClientRect();
    const pp = document.querySelector('.tour-pop');
    const q = pp ? pp.getBoundingClientRect() : { left: -9, right: -9, top: -9, bottom: -9 };
    const pts = [];
    for (let fy = 0.05; fy <= 0.95; fy += 0.05) for (let fx = 0.1; fx <= 0.9; fx += 0.1) pts.push([t.left + t.width * fx, t.top + t.height * fy]);
    const cx = t.left + t.width / 2, cy = t.top + t.height / 2;
    pts.sort((a, b) => Math.hypot(a[0] - cx, a[1] - cy) - Math.hypot(b[0] - cx, b[1] - cy));
    return pts.find(([x, y]) => !(x >= q.left - 2 && x <= q.right + 2 && y >= q.top - 2 && y <= q.bottom + 2) && el.contains(document.elementFromPoint(x, y))) || null;
  })()`);
  if (!r) throw new Error('no uncovered point in ' + sel);
  return r;
}

/** Real click into the active editor at a point not covered by the popover, then Ctrl+End. */
export async function clickEditorEnd(p) {
  const [x, y] = await freePoint(p, 'RC.app.active.editor.ta', true);
  await p.clickAt(x, y);
  await p.key('End', { ctrl: true });
}

/** Real click on the output screen canvas at a point not covered by the popover. */
export async function clickScreen(p) {
  const [x, y] = await freePoint(p, '#screen');
  await p.clickAt(x, y);
}

/** Type text with real key events; punctuation that collides with navigation key codes in the harness
 * (e.g. "$" = VK 36 = Home) is entered with Input.insertText instead. */
export async function typeText(p, s) {
  for (const ch of s) {
    if (ch === '\n') await p.key('Enter', { after: 5 });
    else if (/[A-Za-z0-9 ]/.test(ch)) await p.key(ch, { after: 5 });
    else await p.insertText(ch);
  }
  await p.sleep(40);
}
