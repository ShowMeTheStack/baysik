// Runs tests/cases/*.bas and compares the final screen text with *.out
import { readFileSync, readdirSync, existsSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { loadRC, runBasic } from './harness.mjs';

const dir = join(dirname(fileURLToPath(import.meta.url)), 'cases');
const RC = loadRC();
const only = process.argv[2];
const update = process.argv.includes('--update');
let pass = 0, fail = 0;
for (const f of readdirSync(dir).filter((x) => x.endsWith('.bas')).sort()) {
  const name = f.slice(0, -4);
  if (only && only !== '--update' && !name.includes(only)) continue;
  const src = readFileSync(join(dir, f), 'utf8');
  const inp = existsSync(join(dir, name + '.in')) ? readFileSync(join(dir, name + '.in'), 'utf8') : '';
  const r = runBasic(RC, src, { input: inp });
  let out = r.compileError ? `COMPILE ERROR: ${r.compileError.message} @${r.compileError.pos ? r.compileError.pos.line + 1 : '?'}` : r.lines.join('\n');
  if (r.error) out += `\nRUNTIME ERROR ${r.error.code}: ${r.error.message} @${r.error.pos ? r.error.pos.line + 1 : '?'}`;
  if (r.printer.length) out += '\n--- LPT1 ---\n' + r.printer.join('\n');
  const expFile = join(dir, name + '.out');
  if (update || !existsSync(expFile)) {
    writeFileSync(expFile, out + '\n');
    console.log(`WROTE ${name}`);
    continue;
  }
  const exp = readFileSync(expFile, 'utf8').replace(/\n$/, '');
  if (exp === out) { pass++; }
  else {
    fail++;
    console.log(`FAIL ${name}\n--- expected\n${exp}\n--- got\n${out}\n`);
  }
}
console.log(`${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
