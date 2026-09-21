// Shared helpers for the 40-run-* specs (running programs, output screen, hardware emulation).
// Not a spec file itself (no .spec.mjs suffix).

/** Wait for two animation frames so the render loop has painted the canvas. */
export async function frame(p) {
  await p.ev('new Promise(r => requestAnimationFrame(() => requestAnimationFrame(() => r(true))))');
}

/** Read the RGB of a canvas pixel (device pixels of the emulated screen). */
export async function rgb(p, x, y) {
  await frame(p);
  return p.ev(`(() => { const c = document.getElementById('screen'); const d = c.getContext('2d').getImageData(${x}, ${y}, 1, 1).data; return [d[0], d[1], d[2]]; })()`);
}

/** Hex string of a canvas pixel, e.g. '#aa0000'. */
export async function hex(p, x, y) {
  const [r, g, b] = await rgb(p, x, y);
  return '#' + [r, g, b].map((v) => v.toString(16).padStart(2, '0')).join('');
}

/** Count canvas pixels in a rect that equal the given [r,g,b]. */
export async function countColor(p, x, y, w, h, col) {
  await frame(p);
  return p.ev(`(() => { const c = document.getElementById('screen'); const d = c.getContext('2d').getImageData(${x}, ${y}, ${w}, ${h}).data; let n = 0; for (let i = 0; i < d.length; i += 4) if (d[i] === ${col[0]} && d[i + 1] === ${col[1]} && d[i + 2] === ${col[2]}) n++; return n; })()`);
}

/** Canvas width/height. */
export const canvasSize = (p) => p.ev("(() => { const c = document.getElementById('screen'); return [c.width, c.height]; })()");

/** Run a program and wait until it is waiting (blocked on INPUT/INKEY$ loop etc.) or running. */
export async function startProgram(p, text, path) {
  await p.newFile(path || 'C:\\MYPROGS\\E2E.BAS', text);
  await p.ev('RC.app.run()');
  await p.waitState(['running', 'waiting', 'ended', 'error', 'paused']);
}

/** Wait until the program blocks waiting for keyboard input (INPUT / LINE INPUT). */
export async function waitInput(p, ms = 5000) {
  await p.wait("RC.app.runner.state === 'waiting' || !!RC.app.runner.display.inputCursor", ms);
  await p.sleep(30);
}

/** Make sure the output canvas has focus (as a click would) */
export async function focusScreen(p) {
  await p.ev("document.getElementById('screen').focus()");
  await p.sleep(20);
}

/** Stop any running program so the next test starts clean. */
export async function stopAll(p) {
  await p.ev("(() => { if (RC.app.runner.isActive()) RC.app.stop(); document.getElementById('app').classList.remove('screen-max'); })()");
  await p.closeModals();
  await p.sleep(20);
}

/** Install a capture of downloads (UI.download -> anchor click) and return nothing; read with downloads(p). */
export async function captureDownloads(p) {
  await p.ev(`(() => {
    if (window.__dl) { window.__dl.length = 0; return; }
    window.__dl = [];
    const orig = URL.createObjectURL.bind(URL);
    const blobs = new Map();
    URL.createObjectURL = (b) => { const u = orig(b); blobs.set(u, b); return u; };
    const click = HTMLAnchorElement.prototype.click;
    HTMLAnchorElement.prototype.click = function () {
      if (this.hasAttribute('download')) {
        const b = blobs.get(this.href);
        const rec = { name: this.getAttribute('download'), type: b ? b.type : null, size: b ? b.size : -1, text: null, head: null };
        window.__dl.push(rec);
        if (b) { b.arrayBuffer().then((ab) => { const u = new Uint8Array(ab); rec.head = Array.from(u.slice(0, 8)); rec.text = new TextDecoder('latin1').decode(u.slice(0, 20000)); if (b.type === 'image/png') { createImageBitmap(b).then((bm) => { rec.w = bm.width; rec.h = bm.height; rec.done = true; }); } else rec.done = true; }); }
        return;
      }
      return click.call(this);
    };
  })()`);
}
export const downloads = (p) => p.ev('window.__dl || []');
