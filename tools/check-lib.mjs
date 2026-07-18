// Validate BASIC programs headlessly: compile + run with scripted keyboard input.
// usage: node tools/check-lib.mjs <dir-or-file>... [--inputs inputs.json] [--time 2500] [--verbose]
//   inputs.json: { "FILE.BAS": "text typed, \n = Enter" }
// Reports COMPILE/RUNTIME errors; programs still running or waiting for keys at the time limit are OK.
import { readFileSync, readdirSync, statSync, existsSync } from 'node:fs';
import { join, basename } from 'node:path';
import { loadRC, runBasic } from '../tests/harness.mjs';
const args = process.argv.slice(2);
const opt = (n, d) => { const i = args.indexOf(n); if (i < 0) return d; const v = args[i + 1]; args.splice(i, 2); return v; };
const inputsFile = opt('--inputs', null);
const time = +opt('--time', 2500);
const verbose = args.includes('--verbose'); if (verbose) args.splice(args.indexOf('--verbose'), 1);
const inputs = inputsFile && existsSync(inputsFile) ? JSON.parse(readFileSync(inputsFile, 'utf8')) : {};
const RC = loadRC();
const files = [];
const walk = (p) => { if (statSync(p).isDirectory()) for (const f of readdirSync(p).sort()) walk(join(p, f)); else if (/\.BAS$/i.test(p)) files.push(p); };
for (const a of args) walk(a);
let bad = 0;
for (const f of files) {
  const src = readFileSync(f, 'utf8');
  const name = basename(f).toUpperCase();
  const dflt = '5\n3\n2\n1\nY\nN\n10\n7\n4\n9\nQ\n0\n';
  const r = runBasic(RC, src, { input: (inputs[name] !== undefined ? inputs[name] : dflt) + '   \x1b q Q\n', timeLimit: time });
  let s;
  if (r.compileError) { s = `COMPILE ERROR: ${r.compileError.message} (line ${r.compileError.pos ? r.compileError.pos.line + 1 : '?'})`; bad++; }
  else if (r.error) { s = `RUNTIME ERROR ${r.error.code}: ${r.error.message} (line ${r.error.pos ? r.error.pos.line + 1 : '?'})`; bad++; }
  else s = `ok [${r.state}, ${r.vm.statementsExecuted} stmts, SCREEN ${r.display.mode}]`;
  console.log(`${f}: ${s}`);
  if (verbose) console.log(r.lines.slice(0, 25).join('\n') + '\n---');
}
console.log(`${files.length - bad}/${files.length} ok`);
process.exit(bad ? 1 : 0);
