// Shared helpers for the 95-responsive / 96-touch / 97-a11y specs (not a spec file itself).

/** Layout mode the CSS media queries select for a viewport. */
export function modeOf(w, h) {
  if (w <= 820 || h <= 480) return 'phone';
  if (w <= 1199) return 'tablet';
  return 'desktop';
}

/** Rect + display info for a selector, evaluated in the page. */
export async function box(p, sel) {
  return p.ev(`(() => { const e = document.querySelector(${JSON.stringify(sel)}); if (!e) return null; const r = e.getBoundingClientRect(); const cs = getComputedStyle(e);
    return { x: r.left, y: r.top, w: r.width, h: r.height, right: r.right, bottom: r.bottom, display: cs.display, overflowX: cs.overflowX, sw: e.scrollWidth, cw: e.clientWidth }; })()`);
}

/** True when element has a non-zero box fully inside the viewport (1px tolerance). */
export async function fullyInViewport(p, sel) {
  return p.ev(`(() => { const e = document.querySelector(${JSON.stringify(sel)}); if (!e) return false; const r = e.getBoundingClientRect();
    return r.width > 0 && r.height > 0 && r.left >= -1 && r.top >= -1 && r.right <= innerWidth + 1 && r.bottom <= innerHeight + 1; })()`);
}

/** Wait until the output screen frame has been fitted (non-zero, 4:3) and return frame + wrap rects. */
export async function fittedFrame(p, ms = 4000) {
  await p.wait(`(() => { const f = document.getElementById('screenFrame').getBoundingClientRect(); const w = document.getElementById('screenWrap').getBoundingClientRect();
    return f.width > 20 && f.height > 20 && Math.abs(f.width / f.height - 4 / 3) < 0.02 && f.width <= w.width + 1 && f.height <= w.height + 1; })()`, ms);
  return { frame: await box(p, '#screenFrame'), wrap: await box(p, '#screenWrap') };
}

/** Drag with real mouse events from (x0,y0) to (x1,y1) in a few steps. */
export async function drag(p, x0, y0, x1, y1, steps = 6) {
  await p.mouse('mouseMoved', x0, y0);
  await p.mouse('mousePressed', x0, y0);
  for (let i = 1; i <= steps; i++) {
    await p.mouse('mouseMoved', x0 + ((x1 - x0) * i) / steps, y0 + ((y1 - y0) * i) / steps);
  }
  await p.mouse('mouseReleased', x1, y1);
  await p.sleep(80);
}

/** Touch press/hold/release at the centre of an element (real touch events). */
export async function touchHold(p, sel, ms) {
  const [x, y] = await p.center(sel);
  await p.b.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y }] });
  await p.sleep(ms);
  await p.b.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
  await p.sleep(60);
}
export async function touchAt(p, x, y) {
  await p.b.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y }] });
  await p.b.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
  await p.sleep(80);
}

export const appClass = (p) => p.ev("document.getElementById('app').className");
export const hasAppClass = (p, c) => p.ev(`document.getElementById('app').classList.contains(${JSON.stringify(c)})`);
export const mview = (p) => p.ev("document.getElementById('app').dataset.mview");
export const activeMobileTab = (p) => p.ev("[...document.querySelectorAll('#mobileTabs button.active')].map(b => b.dataset.view).join(',')");
