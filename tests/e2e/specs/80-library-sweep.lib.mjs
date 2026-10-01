// Shared helper for the library sweep specs (80-library-sweep-a..e).
// Loads the generated library catalog in Node so each program gets its own named test.
import fs from 'node:fs';
import vm from 'node:vm';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
let cache = null;
export function libraryItems() {
  if (cache) return cache;
  const src = fs.readFileSync(join(here, '..', '..', '..', 'src', 'lang', 'basic', 'library-data.js'), 'utf8');
  const RC = {};
  vm.runInNewContext(src, { RC });
  cache = JSON.parse(JSON.stringify(RC.LIBRARY.items.map((it) => ({ path: it.path, title: it.title, cat: it.cat }))));
  return cache;
}

export const SWEEP_CHUNK = 110;
export function sweepSlice(k) {
  const items = libraryItems();
  const start = k * SWEEP_CHUNK;
  // the last file takes everything that is left so no program is ever skipped
  return k === 4 ? items.slice(start) : items.slice(start, start + SWEEP_CHUNK);
}

/** Close every open document without prompts (sweep cleanup). */
export async function closeAllDocs(p) {
  await p.ev(`(() => { const a = RC.app; for (const d of a.docs.slice()) { if (d.dirty) { d.editor.setValue(d.savedText); d.dirty = false; } a.closeDoc(d); } })()`);
  await p.sleep(20);
}

/** Open a library program in the IDE, run ~400 ms with keys typed, and check it did not fail. */
export async function sweepOne(p, item) {
  const target = 'C:\\LIBRARY\\' + item.path;
  await p.ev('RC.app.stop()');
  await closeAllDocs(p);
  await p.ev(`RC.Library.open(RC.app, ${JSON.stringify(item.path)})`);
  await p.wait(`RC.app.active && RC.app.active.path === ${JSON.stringify(target)}`, 8000);
  p.assert.ok(await p.ev(`RC.app.vfs.exists(${JSON.stringify(target)})`), 'program installed on C:');
  const src = await p.code();
  p.assert.ok(src.length > 20, 'program text loaded');
  await p.ev('RC.app.run()');
  const st0 = await p.state();
  const status0 = await p.status();
  p.assert.doesNotMatch(status0, /^Syntax/, 'compile error: ' + status0);
  p.assert.notEqual(st0, 'error', 'error at start: ' + status0);
  const t0 = Date.now();
  await p.sleep(150);
  const keys = ['5', 'Enter', 'y', 'ArrowRight', ' ', 'Enter'];
  for (const k of keys) {
    if (await p.ev('RC.app.programHasKeys()')) await p.key(k, { after: 25 });
  }
  const left = 400 - (Date.now() - t0);
  if (left > 0) await p.sleep(left);
  const res = await p.fn(() => ({
    state: RC.app.runner.state,
    status: document.getElementById('statusbar').innerText,
    problems: (RC.app.panels.problems || []).map((x) => x.kind + ': ' + x.message),
    modal: !!document.querySelector('.modal-back'),
  }));
  await p.ev('RC.app.stop()');
  p.assert.deepEqual(res.problems, [], 'problems reported: ' + res.problems.join('; '));
  p.assert.doesNotMatch(res.status, /^(Syntax|Runtime error)/, 'status: ' + res.status);
  p.assert.notEqual(res.state, 'error', 'program ended in error: ' + res.status);
  p.assert.ok(['running', 'waiting', 'ended', 'paused', 'idle', 'chain'].includes(res.state), 'unexpected state ' + res.state);
  p.assert.equal(res.modal, false, 'no dialog popped up');
}

export function registerSweep(t, k) {
  const items = sweepSlice(k);
  t.test(`sweep chunk ${'abcde'[k]} covers ${items.length} programs (≤120)`, async (p) => {
    p.assert.ok(items.length > 0 && items.length <= 120, 'chunk size ' + items.length);
    const inPage = await p.ev('RC.LIBRARY.items.map((i) => i.path)');
    for (const it of items) p.assert.ok(inPage.includes(it.path), it.path + ' present in built page');
  });
  for (const it of items) {
    t.test(`library program runs: ${it.path} (${it.title})`, async (p) => { await sweepOne(p, it); }, { timeout: 20000 });
  }
}
