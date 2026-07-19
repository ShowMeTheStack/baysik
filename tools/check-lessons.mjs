// Validate src/lang/basic/lessons-data.js: structure + every code snippet compiles/runs.
import { readFileSync } from 'node:fs';
import vm from 'node:vm';
import { loadRC, runBasic } from '../tests/harness.mjs';
const RC = loadRC();
vm.runInContext(readFileSync(new URL('../src/lang/basic/lessons-data.js', import.meta.url), 'utf8'), vm.createContext(Object.assign(Object.create(null), { RC })));
const L = RC.LESSONS;
let bad = 0;
const ids = new Set();
const TOURS = ['welcome', 'first', 'debug', 'graphics', 'files', 'gw'];
const CHECKS = ['run', 'codeHas', 'output', 'paused', 'breakpoint'];
const err = (m) => { console.log('  ERROR ' + m); bad++; };
for (const l of L) {
  console.log(`${l.unit} :: ${l.title}`);
  if (!l.id || ids.has(l.id)) err('missing/duplicate id ' + l.id); ids.add(l.id);
  for (const k of ['unit', 'title', 'level', 'summary']) if (!l[k]) err('missing ' + k);
  if (l.tour) { if (!TOURS.includes(l.tour)) err('unknown tour ' + l.tour); continue; }
  if (!Array.isArray(l.steps) || !l.steps.length) { err('no steps'); continue; }
  l.steps.forEach((s, i) => {
    if (!s.title) err(`step ${i} no title`);
    if (s.quiz) { if (!(s.quiz.options && s.quiz.options.length > 1 && s.quiz.answer >= 0 && s.quiz.answer < s.quiz.options.length)) err(`step ${i} bad quiz`); return; }
    if (!s.text) err(`step ${i} no text`);
    if (s.check) { const k = Object.keys(s.check)[0]; if (!CHECKS.includes(k)) err(`step ${i} bad check ${k}`); if (s.check.codeHas) try { new RegExp(s.check.codeHas, 'i'); } catch (e) { err('bad regex'); } if (s.check.output) try { new RegExp(s.check.output, 'i'); } catch (e) { err('bad regex'); } }
    if (s.code !== undefined) {
      const r = runBasic(RC, s.code, { input: 'Sam\n7\n5\n3\nY\nN\n2\n1\n   \x1b', timeLimit: 1500 });
      if (r.compileError) err(`step ${i} code COMPILE ERROR ${r.compileError.message} line ${r.compileError.pos ? r.compileError.pos.line + 1 : '?'}`);
      else if (r.error) err(`step ${i} code RUNTIME ERROR ${r.error.message}`);
    }
  });
}
console.log(`${L.length} lessons, ${bad} problems`);
process.exit(bad ? 1 : 0);
