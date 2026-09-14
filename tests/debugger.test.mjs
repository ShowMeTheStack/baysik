// Debugger API tests: breakpoints, stepping, frames, evaluation, variable edits, RENUM
import assert from 'node:assert/strict';
import { loadRC } from './harness.mjs';
const RC = loadRC();
const B = RC.Basic;

function mk(src) {
  const display = new RC.Display(), keyboard = new RC.Keyboard(), audio = new RC.Audio();
  audio.enabled = false;
  const prog = B.compileProgram([{ name: 'MAIN.BAS', text: src }]);
  const vm = new B.VM(prog, { display, keyboard, audio, vfs: new RC.VFS() });
  return { vm, prog, display };
}
function runUntilPause(vm) { let n = 0; while ((vm.state === 'running' || vm.state === 'waiting') && n++ < 1000) vm.tick(20); }
let tests = 0;
function test(name, fn) { fn(); tests++; console.log('ok -', name); }

const SRC = `DECLARE FUNCTION Fact& (n%)
total = 0
FOR i% = 1 TO 5
  total = total + i%
NEXT
r& = Fact&(5)
PRINT total; r&
END
FUNCTION Fact& (n%)
  IF n% <= 1 THEN
    Fact& = 1
  ELSE
    Fact& = n% * Fact&(n% - 1)
  END IF
END FUNCTION
`;

test('breakpoint + evaluate + modify', () => {
  const { vm, prog, display } = mk(SRC);
  const bp = B.Debug.stmtAtLine(prog, 'MAIN.BAS', 3); // total = total + i%
  vm.setBreakpoints(new Set([bp]));
  vm.start();
  runUntilPause(vm);
  assert.equal(vm.state, 'paused');
  assert.equal(vm.currentStmt().pos.line, 3);
  assert.equal(B.Debug.evaluate(vm, 'i% * 10').value, 10);
  // modify loop variable to skip ahead
  const vars = B.Debug.variables(vm);
  const iv = vars.globals.find((v) => v.name === 'i%');
  B.Debug.assign(vm, iv, '4');
  vm.setBreakpoints(new Set());
  vm.resume();
  runUntilPause(vm);
  assert.equal(vm.state, 'ended');
  // total = 4 + 5 = 9
  assert.match(display.textLines()[0], /^ 9 {2}120/);
});

test('step into recursion, call stack depth, frame-relative evaluation', () => {
  const { vm, prog } = mk(SRC);
  const bp = B.Debug.stmtAtLine(prog, 'MAIN.BAS', 10); // Fact& = 1 (base case)
  vm.setBreakpoints(new Set([bp]));
  vm.start();
  runUntilPause(vm);
  assert.equal(vm.state, 'paused');
  const cs = vm.callStack();
  assert.equal(cs.length, 6); // 5 Fact frames + main
  assert.equal(cs[0].name, 'FUNCTION Fact&');
  // n% differs per frame
  assert.equal(B.Debug.evaluate(vm, 'n%', vm.frames.length - 1).value, 1);
  assert.equal(B.Debug.evaluate(vm, 'n%', 1).value, 5);
  assert.equal(B.Debug.evaluate(vm, 'n% * 2', 2).value, 8);
  // change n% in an outer frame: result changes
  const v = B.Debug.variables(vm, 1).locals.find((x) => x.name === 'n%');
  assert.ok(v.param);
  vm.setBreakpoints(new Set());
  vm.resume('out');
  runUntilPause(vm);
  assert.equal(vm.state, 'paused');
  assert.equal(vm.frames.length, 5);
  vm.resume();
  runUntilPause(vm);
  assert.equal(vm.state, 'ended');
});

test('step over / into / out', () => {
  const { vm } = mk(SRC);
  vm.stepMode = 'into'; vm.updateDbgFlag();
  vm.start();
  runUntilPause(vm);
  assert.equal(vm.currentStmt().pos.line, 1);
  const lines = [];
  for (let k = 0; k < 14; k++) { vm.resume('over'); runUntilPause(vm); if (vm.state !== 'paused') break; lines.push(vm.currentStmt().pos.line); }
  assert.deepEqual(lines.slice(0, 6), [2, 3, 4, 3, 4, 3]);
});

test('immediate statements', () => {
  const { vm, display } = mk('x = 5\nSTOP\nPRINT x');
  vm.start();
  runUntilPause(vm);
  assert.equal(vm.state, 'paused');
  B.Debug.execute(vm, 'x = x * 3: PRINT "imm"; x');
  vm.resume();
  runUntilPause(vm);
  assert.deepEqual([...display.textLines().slice(0, 2).map((s) => s.trimEnd())], ['imm 15', ' 15']);
});

test('records and arrays children + edit element', () => {
  const { vm } = mk('TYPE T\n a AS INTEGER\n s AS STRING * 3\nEND TYPE\nDIM r AS T\nDIM arr(2, 1)\narr(1, 1) = 7\nr.a = 2\nSTOP\nPRINT arr(1, 1)');
  vm.start(); runUntilPause(vm);
  const g = B.Debug.variables(vm).globals;
  const arr = g.find((x) => x.name === 'arr');
  const rows = B.Debug.children(arr);          // first dimension: (0, …) (1, …) (2, …)
  assert.equal(rows.total, 3);
  assert.ok(rows.items[1].isGroup);
  const kids = B.Debug.children(rows.items[1]); // (1, 0) (1, 1)
  assert.equal(kids.total, 2);
  const el = kids.items.find((k) => k.name === '(1, 1)');
  assert.equal(el.value, 7);
  B.Debug.assign(vm, el, '42');
  const r = g.find((x) => x.name === 'r');
  const f = B.Debug.children(r).items;
  assert.equal(f[0].value, 2);
  B.Debug.assign(vm, f[1], 'hello');
  assert.equal(r.value.S, 'hel');
  assert.equal(B.Debug.evaluate(vm, 'arr(1,1) + r.a').value, 44);
  // constants are listed read-only and cannot be assigned

});

test('watch errors are reported, not fatal', () => {
  const { vm } = mk('x = 1\nSTOP\nPRINT x');
  vm.start(); runUntilPause(vm);
  assert.throws(() => B.Debug.evaluate(vm, '1 / 0'), /Division by zero/);
  assert.throws(() => B.Debug.evaluate(vm, 'nosuch$ +'), /Expected/);
  assert.equal(vm.state, 'paused');
  vm.resume(); runUntilPause(vm);
  assert.equal(vm.state, 'ended');
});

test('RENUM updates references', () => {
  const src = '5 ON X GOTO 20, 30\n7 IF A THEN 30 ELSE 20\n20 GOSUB 30: RESTORE 30\n30 PRINT ERL = 20\n';
  const r = B.GW.renum(src, 100, null, 10);
  assert.equal(r.text, '100 ON X GOTO 120, 130\n110 IF A THEN 130 ELSE 120\n120 GOSUB 130: RESTORE 130\n130 PRINT ERL = 120\n');
  const s = B.GW.setLine(r.text, 115, 'PRINT "hi"').text;
  assert.match(s.split('\n')[2], /^115 PRINT "hi"/);
  assert.equal(B.GW.setLine(s, 115, '').text, r.text);
});

console.log(`${tests} debugger tests passed`);
