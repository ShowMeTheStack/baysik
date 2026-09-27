// Shared helpers for the GW-BASIC classic console specs (60-console-*.spec.mjs).
// Everything is driven with real key events on the focused #screen canvas.

/** Enter the console (via the app API) and give the screen canvas keyboard focus with a real click. */
export async function enter(p) {
  if (!(await p.ev('RC.app.console.active'))) await p.ev('RC.app.console.toggle(true)');
  await focus(p);
}
export async function focus(p) {
  await p.click('#screen');
  await p.wait("document.activeElement === document.getElementById('screen')", 3000);
}

/** Screen rows (25), right-trimmed, CP437 decoded. */
export async function rows(p) { return (await p.screen()).split('\n'); }
/** Text of one screen row (0-based). */
export async function row(p, r) { return (await rows(p))[r]; }
/** Text cursor position {row, col} (0-based). */
export const cur = (p) => p.fn(() => { const d = RC.app.runner.display; return { row: d.row, col: d.col }; });
/** The console's program text (the console document's editor contents). */
export const prog = (p) => p.ev('RC.app.console.text()');
/** Program lines without the trailing empty line. */
export async function progLines(p) { return (await prog(p)).split('\n').filter((l) => l !== ''); }

export async function idle(p, ms = 8000) {
  await p.wait("!['running','waiting'].includes(RC.app.runner.state)", ms);
}
/** Wait until the row just above the cursor reads "Ok" and the cursor is at column 0 (the Ok prompt). */
export async function waitOk(p, ms = 8000) {
  await p.wait("(() => { const d = RC.app.runner.display; const L = d.textLines(); return d.col === 0 && d.row > 0 && L[d.row - 1].trim() === 'Ok'; })()", ms);
}
/** Type a direct-mode line + Enter and wait for the command to finish with Ok. */
export async function cmd(p, line, ms) {
  await p.type(line + '\n');
  await idle(p, ms);
  await waitOk(p, ms);
}
/** Type a line + Enter without waiting for Ok (numbered lines, AUTO input). */
export async function line(p, text) { await p.type(text + '\n'); }

/** Lines printed after the LAST screen row equal to `echo`, up to (not including) the next "Ok". */
export async function out(p, echo) {
  const L = await rows(p);
  const i = L.lastIndexOf(echo);
  if (i < 0) throw new Error('echo row not found: ' + JSON.stringify(echo) + '\n' + L.join('\n'));
  const res = [];
  for (let j = i + 1; j < L.length - 1; j++) { if (L[j] === 'Ok') break; res.push(L[j]); }
  return res;
}
/** Clear the screen with Ctrl+Home (console key). */
export async function clear(p) { await p.key('Home', { ctrl: true }); }
/** Store several numbered program lines by typing them. */
export async function typeProgram(p, lines) {
  for (const l of lines) await line(p, l);
}
/** Attribute byte at a text cell */
export const attrAt = (p, r, c) => p.fn((r, c) => { const d = RC.app.runner.display; return d.pages[d.apage].attrs[r * d.textCols() + c]; }, r, c);
/** Index of the last screen row matching re */
export async function lastRow(p, re) {
  const L = await rows(p);
  for (let i = L.length - 1; i >= 0; i--) if (re.test(L[i])) return i;
  return -1;
}
/** Dispatch a paste event with `text` on the screen canvas (clipboard data like a real paste). */
export async function paste(p, text) {
  await p.fn((t) => {
    const dt = new DataTransfer();
    dt.setData('text/plain', t);
    document.getElementById('screen').dispatchEvent(new ClipboardEvent('paste', { clipboardData: dt, bubbles: true, cancelable: true }));
  }, text);
  await p.sleep(60);
}
/** Write a file on the virtual disk (setup only) */
export async function writeFile(p, path, text) {
  await p.fn((path, text) => RC.app.vfs.writeFile(path, RC.app.encodeText(text), { trusted: true }), path, text);
}
export const exists = (p, path) => p.fn((path) => RC.app.vfs.exists(path), path);
export const readFile = (p, path) => p.fn((path) => RC.app.decodeText(RC.app.vfs.readFile(path)), path);
/** Resolve a name relative to the current directory the way SAVE does */
export const resolveSave = (p, name) => p.fn((n) => RC.app.runner.resolveSaveName(n), name);
