// Headless loader for the Compendium runtime (Node). Loads the same source files the
// browser build inlines, into an isolated context.
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const manifest = JSON.parse(readFileSync(join(root, 'src/manifest.json'), 'utf8'));

let cachedRC = null;
export function loadRC() {
  // Load into the main V8 context (fast globals); the sources only attach to globalThis.RC.
  if (cachedRC) return cachedRC;
  delete globalThis.RC;
  for (const f of manifest.core) {
    const code = readFileSync(join(root, 'src', f), 'utf8');
    vm.runInThisContext(code, { filename: f });
  }
  cachedRC = globalThis.RC;
  return cachedRC;
}

/**
 * Run a BASIC program headlessly.
 * @returns {{lines: string[], vm, display, printer: string[], error}}
 */
export function runBasic(RC, src, opts = {}) {
  const B = RC.Basic;
  const display = new RC.Display();
  const keyboard = new RC.Keyboard();
  const audio = new RC.Audio();
  audio.enabled = false;
  const vfs = opts.vfs || new RC.VFS();
  for (const [name, text] of Object.entries(opts.files || {})) vfs.writeText(name, text);
  const printer = [];
  const host = { display, keyboard, audio, vfs, printer: { printLine: (s) => printer.push(s) }, ...(opts.host || {}) };
  let prog;
  try {
    prog = B.compileProgram([{ name: 'MAIN.BAS', text: src }], { readInclude: (n) => (vfs.exists(n) ? vfs.readText(n) : null) });
  } catch (e) {
    if (e instanceof B.CompileError) return { compileError: e, lines: [], printer };
    throw e;
  }
  const m = new B.VM(prog, host);
  if (opts.input) keyboard.type(opts.input);
  m.start();
  const t0 = Date.now();
  const limit = opts.timeLimit || 5000;
  while (m.state === 'running' || m.state === 'waiting') {
    m.tick(50);
    if (m.state === 'waiting' && m.pending && !keyboard.buf.length && m.pending.needsKey !== false) {
      // allow timed waits to elapse
      if (Date.now() - t0 > limit) break;
    }
    if (Date.now() - t0 > limit) break;
  }
  const lines = display.textLines().map((l) => RC.fromCP437(l).replace(/\s+$/, ''));
  while (lines.length && lines[lines.length - 1] === '') lines.pop();
  return { lines, vm: m, display, printer, vfs, error: m.errorInfo || null, state: m.state };
}
