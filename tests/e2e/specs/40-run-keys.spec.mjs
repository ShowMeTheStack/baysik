// Running programs: keyboard routing to the output canvas (INPUT, LINE INPUT, INKEY$, KEY traps,
// INP(&H60)), focus rules, paste, full-size output and break keys.
import { startProgram, waitInput, focusScreen, stopAll } from './40-run-helpers.mjs';

const INKEY_PROG = 'DO: K$ = INKEY$: LOOP UNTIL LEN(K$)\nPRINT "CODES";: FOR i = 1 TO LEN(K$): PRINT ASC(MID$(K$, i, 1));: NEXT: PRINT';

/** Run the INKEY$ capture program, press a key, and return the ASCII codes the program read */
async function inkeyCodes(p, press) {
  await startProgram(p, INKEY_PROG);
  await p.wait("RC.app.runner.state === 'running'", 3000);
  await press();
  await p.waitState(['ended', 'error'], 4000);
  const line = (await p.screen()).split('\n').find((l) => l.startsWith('CODES')) || '';
  return line.replace('CODES', '').trim().split(/\s+/).filter(Boolean).map(Number);
}

/** Dispatch a raw keydown or keyup through CDP (no auto key-up) */
async function rawKey(p, type, code, key, vk) {
  await p.b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: vk, key, code });
  await p.sleep(80);
}

const INP_PROG = 'DO\nLOCATE 1, 1: PRINT "SCAN"; INP(&H60); "   "\nLOOP';
async function scanAfter(p) {
  await p.sleep(60);
  return p.wait("(() => { const l = RC.app.runner.display.textLines()[0]; const m = /SCAN\\s*(\\d+)/.exec(l); return m ? +m[1] : null; })()", 2000);
}

export default (t) => {
  t.beforeEach(async (p) => { await stopAll(p); });

  // ---- INPUT / LINE INPUT through real key events ---------------------------------------------------------
  t.test('run focuses the output canvas', async (p) => {
    await startProgram(p, 'INPUT a$');
    await waitInput(p);
    p.assert.equal(await p.focusedId(), 'screen');
  });
  t.test('clicking the canvas marks the screen frame as focused', async (p) => {
    await startProgram(p, 'INPUT a$');
    await waitInput(p);
    await p.ev('RC.app.active.editor.ta.focus()');
    p.assert.equal(await p.ev("document.getElementById('screenFrame').classList.contains('focused')"), false);
    await p.click('#screen');
    await p.sleep(50);
    p.assert.equal(await p.ev("document.getElementById('screenFrame').classList.contains('focused')"), true);
  });
  t.test('INPUT reads a string typed on the focused canvas', async (p) => {
    await startProgram(p, 'INPUT "NAME"; N$: PRINT "HELLO, "; N$');
    await waitInput(p);
    p.assert.equal(await p.state(), 'waiting');
    await p.type('BOB\n');
    await p.waitState('ended');
    const lines = (await p.screen()).split('\n');
    p.assert.equal(lines[0], 'NAME? BOB');
    p.assert.equal(lines[1], 'HELLO, BOB');
  });
  t.test('typed characters are echoed before Enter is pressed', async (p) => {
    await startProgram(p, 'INPUT "X"; a$');
    await waitInput(p);
    await p.type('partial');
    p.assert.equal((await p.screen()).split('\n')[0], 'X? partial');
    p.assert.equal(await p.state(), 'waiting');
  });
  t.test('INPUT shows a blinking input cursor while waiting', async (p) => {
    await startProgram(p, 'INPUT a$');
    await waitInput(p);
    p.assert.ok(await p.ev('RC.app.runner.display.inputCursor'));
    await p.type('x\n');
    await p.waitState('ended');
    p.assert.ok(!(await p.ev('RC.app.runner.display.inputCursor')));
  });
  t.test('INPUT reads a number', async (p) => {
    await startProgram(p, 'INPUT n: PRINT n * 2');
    await waitInput(p);
    await p.type('21\n');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /\n 42\n/);
  });
  t.test('INPUT reads two comma-separated values', async (p) => {
    await startProgram(p, 'INPUT a, b: PRINT a + b');
    await waitInput(p);
    await p.type('3,4\n');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /\n 7\n/);
  });
  t.test('Backspace deletes the last typed character', async (p) => {
    await startProgram(p, 'INPUT a$: PRINT "[" + a$ + "]"');
    await waitInput(p);
    await p.type('BOX');
    await p.key('Backspace');
    await p.type('B\n');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /\[BOB\]/);
  });
  t.test('Backspace on the screen also erases the echoed character', async (p) => {
    await startProgram(p, 'INPUT a$');
    await waitInput(p);
    await p.type('ABC');
    await p.key('Backspace');
    await p.key('Backspace');
    p.assert.equal((await p.screen()).split('\n')[0], '? A');
  });
  t.test('Backspace at the start of the input does nothing', async (p) => {
    await startProgram(p, 'INPUT "P"; a$: PRINT "[" + a$ + "]"');
    await waitInput(p);
    await p.key('Backspace');
    await p.key('Backspace');
    await p.type('Z\n');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /^P\? Z\n\[Z\]/);
  });
  t.test('a non-numeric answer to a numeric INPUT prints Redo from start', async (p) => {
    await startProgram(p, 'INPUT "AGE"; a%: PRINT "AGE IS"; a%');
    await waitInput(p);
    await p.type('abc\n');
    await p.waitScreen(/Redo from start/);
    p.assert.equal(await p.state(), 'waiting');
    await p.type('12\n');
    await p.waitState('ended');
    const lines = (await p.screen()).split('\n');
    p.assert.equal(lines[0], 'AGE? abc');
    p.assert.equal(lines[1], 'Redo from start');
    p.assert.equal(lines[2], 'AGE? 12');
    p.assert.equal(lines[3], 'AGE IS 12');
  });
  t.test('too many values also gives Redo from start', async (p) => {
    await startProgram(p, 'INPUT a: PRINT "A="; a');
    await waitInput(p);
    await p.type('1,2\n');
    await p.waitScreen(/Redo from start/);
    await p.type('5\n');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /A= 5/);
  });
  t.test('Escape clears the line being typed', async (p) => {
    await startProgram(p, 'INPUT a$: PRINT "[" + a$ + "]"');
    await waitInput(p);
    await p.type('WRONG');
    await p.key('Escape');
    await p.type('RIGHT\n');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /\[RIGHT\]/);
  });
  t.test('Left arrow moves the cursor so typing inserts in the middle', async (p) => {
    await startProgram(p, 'INPUT a$: PRINT "[" + a$ + "]"');
    await waitInput(p);
    await p.type('AC');
    await p.key('ArrowLeft');
    await p.type('B\n');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /\[ABC\]/);
  });
  t.test('Home, Right and Delete edit the typed line', async (p) => {
    await startProgram(p, 'INPUT a$: PRINT "[" + a$ + "]"');
    await waitInput(p);
    await p.type('XABC');
    await p.key('Home');
    await p.key('Delete');
    await p.key('End');
    await p.type('D\n');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /\[ABCD\]/);
  });
  t.test('LINE INPUT keeps commas and quotes', async (p) => {
    await startProgram(p, 'LINE INPUT "> "; l$: PRINT "LEN"; LEN(l$): PRINT l$');
    await waitInput(p);
    await p.type('a, b; "c"\n');
    await p.waitState('ended');
    const lines = (await p.screen()).split('\n');
    p.assert.equal(lines[0], '> a, b; "c"');
    p.assert.equal(lines[1], 'LEN 9');
    p.assert.equal(lines[2], 'a, b; "c"');
  });
  t.test('LINE INPUT accepts an empty line', async (p) => {
    await startProgram(p, 'LINE INPUT l$: PRINT "LEN"; LEN(l$)');
    await waitInput(p);
    await p.key('Enter');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /LEN 0/);
  });
  t.test('INPUT; keeps the cursor on the same line after Enter', async (p) => {
    await startProgram(p, 'INPUT ; "Q"; a$: PRINT "!"');
    await waitInput(p);
    await p.type('yes\n');
    await p.waitState('ended');
    p.assert.equal((await p.screen()).split('\n')[0], 'Q? yes!');
  });
  t.test('INPUT with a comma after the prompt shows no question mark', async (p) => {
    await startProgram(p, 'INPUT "Enter: ", a$: PRINT a$');
    await waitInput(p);
    await p.type('ok\n');
    await p.waitState('ended');
    p.assert.equal((await p.screen()).split('\n')[0], 'Enter: ok');
  });
  t.test('INPUT$(3) reads three keys without needing Enter', async (p) => {
    await startProgram(p, 'k$ = INPUT$(3): PRINT "GOT "; k$');
    await p.wait("RC.app.runner.state === 'waiting'", 3000);
    await p.type('xyz');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /GOT xyz/);
  });
  t.test('two INPUTs in a row read two separate lines', async (p) => {
    await startProgram(p, 'INPUT a$: INPUT b$: PRINT a$ + "+" + b$');
    await waitInput(p);
    await p.type('one\n');
    await p.sleep(80);
    await p.type('two\n');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /one\+two/);
  });
  t.test('the Run button is disabled while INPUT waits', async (p) => {
    await startProgram(p, 'INPUT a$');
    await waitInput(p);
    p.assert.equal(await p.ev("document.getElementById('tbRun').disabled"), true);
    p.assert.equal(await p.ev("document.getElementById('tbStop').disabled"), false);
  });

  // ---- INKEY$ codes --------------------------------------------------------------------------------------------
  const EXT = [['ArrowUp', 72], ['ArrowDown', 80], ['ArrowLeft', 75], ['ArrowRight', 77], ['Home', 71], ['End', 79],
    ['PageUp', 73], ['PageDown', 81], ['Insert', 82], ['Delete', 83]];
  for (const [k, sc] of EXT) {
    t.test(`INKEY$ returns ${k} as CHR$(0) + CHR$(${sc})`, async (p) => {
      p.assert.deepEqual(await inkeyCodes(p, () => p.key(k)), [0, sc]);
    });
  }
  for (const [k, sc] of [['F1', 59], ['F2', 60], ['F3', 61], ['F6', 64], ['F9', 67], ['F10', 68], ['F11', 133], ['F12', 134]]) {
    t.test(`INKEY$ returns function key ${k} as CHR$(0) + CHR$(${sc})`, async (p) => {
      p.assert.deepEqual(await inkeyCodes(p, () => p.key(k)), [0, sc]);
    });
  }
  t.test('F5 while a program runs goes to the program instead of restarting it', async (p) => {
    const before = await p.ev('RC.app.runCount || 0');
    p.assert.deepEqual(await inkeyCodes(p, () => p.key('F5')), [0, 63]);
    p.assert.equal(await p.ev('RC.app.runCount'), before + 1);
  });
  t.test('F4 while a program runs goes to the program, not full-size view', async (p) => {
    p.assert.deepEqual(await inkeyCodes(p, () => p.key('F4')), [0, 62]);
    p.assert.equal(await p.ev("document.getElementById('app').classList.contains('screen-max')"), false);
  });
  t.test('F8 while a program runs goes to the program instead of stepping', async (p) => {
    p.assert.deepEqual(await inkeyCodes(p, () => p.key('F8')), [0, 66]);
  });
  t.test('Shift+F1 returns CHR$(0) + CHR$(84)', async (p) => {
    p.assert.deepEqual(await inkeyCodes(p, () => p.key('F1', { shift: true })), [0, 84]);
  });
  t.test('Ctrl+F1 returns CHR$(0) + CHR$(94)', async (p) => {
    p.assert.deepEqual(await inkeyCodes(p, () => p.key('F1', { ctrl: true })), [0, 94]);
  });
  t.test('Alt+F1 returns CHR$(0) + CHR$(104)', async (p) => {
    p.assert.deepEqual(await inkeyCodes(p, () => p.key('F1', { alt: true })), [0, 104]);
  });
  t.test('Ctrl+Left returns CHR$(0) + CHR$(115)', async (p) => {
    p.assert.deepEqual(await inkeyCodes(p, () => p.key('ArrowLeft', { ctrl: true })), [0, 115]);
  });
  t.test('Shift+Tab returns CHR$(0) + CHR$(15)', async (p) => {
    p.assert.deepEqual(await inkeyCodes(p, () => p.key('Tab', { shift: true })), [0, 15]);
  });
  for (const [l, code] of [['a', 1], ['b', 2], ['g', 7], ['z', 26]]) {
    t.test(`Ctrl+${l.toUpperCase()} returns CHR$(${code})`, async (p) => {
      p.assert.deepEqual(await inkeyCodes(p, () => p.key(l, { ctrl: true })), [code]);
    });
  }
  t.test('Alt+X returns CHR$(0) + its scan code 45', async (p) => {
    p.assert.deepEqual(await inkeyCodes(p, () => p.key('x', { alt: true })), [0, 45]);
  });
  t.test('Alt+1 returns CHR$(0) + CHR$(120)', async (p) => {
    p.assert.deepEqual(await inkeyCodes(p, () => p.key('1', { alt: true })), [0, 120]);
  });
  for (const [k, code] of [['Enter', 13], ['Escape', 27], ['Backspace', 8], ['Tab', 9], [' ', 32], ['a', 97], ['7', 55]]) {
    t.test(`INKEY$ returns ${JSON.stringify(k)} as CHR$(${code})`, async (p) => {
      p.assert.deepEqual(await inkeyCodes(p, () => p.key(k)), [code]);
    });
  }
  t.test('Shift+letter gives the uppercase character', async (p) => {
    p.assert.deepEqual(await inkeyCodes(p, () => p.key('q', { shift: true })), [81]);
  });
  t.test('INKEY$ returns an empty string when no key is waiting', async (p) => {
    await p.runProgram('n = 0: FOR i = 1 TO 200: IF INKEY$ = "" THEN n = n + 1\nNEXT: PRINT "EMPTY"; n');
    p.assert.match(await p.screen(), /EMPTY 200/);
  });
  t.test('keys typed while the program is busy are buffered in order', async (p) => {
    await startProgram(p, 't! = TIMER: DO WHILE TIMER - t! < 1: LOOP\nFOR i = 1 TO 3: k$ = k$ + INKEY$: NEXT: PRINT "BUF:"; k$');
    await p.type('abc');
    await p.waitState('ended', 5000);
    p.assert.match(await p.screen(), /BUF:abc/);
  });
  t.test('the key buffer holds at most 16 keys', async (p) => {
    await startProgram(p, 't! = TIMER: DO WHILE TIMER - t! < 1.5: LOOP\nDO: k$ = INKEY$: IF k$ = "" THEN EXIT DO\nn = n + 1: LOOP: PRINT "N="; n');
    await p.type('abcdefghijklmnopqrst');
    await p.waitState('ended', 6000);
    p.assert.match(await p.screen(), /N= 16/);
  });

  // ---- KEY(n) event trapping ------------------------------------------------------------------------------
  t.test('ON KEY(1) GOSUB runs the handler when F1 is pressed', async (p) => {
    await startProgram(p, 'ON KEY(1) GOSUB h: KEY(1) ON\nDO: LOOP UNTIL done\nPRINT "TRAPPED"; INKEY$ = "": END\nh: done = -1: RETURN');
    await p.wait("RC.app.runner.state === 'running'", 3000);
    await p.key('F1');
    await p.waitState('ended', 4000);
    p.assert.match(await p.screen(), /TRAPPED-1/);
  });
  t.test('ON KEY(11) traps the Up arrow', async (p) => {
    await startProgram(p, 'ON KEY(11) GOSUB h: KEY(11) ON\nDO: LOOP UNTIL n\nPRINT "UP"; n: END\nh: n = n + 1: RETURN');
    await p.wait("RC.app.runner.state === 'running'", 3000);
    await p.key('ArrowUp');
    await p.waitState('ended', 4000);
    p.assert.match(await p.screen(), /UP 1/);
  });
  for (const [n, k] of [[12, 'ArrowLeft'], [13, 'ArrowRight'], [14, 'ArrowDown'], [10, 'F10']]) {
    t.test(`ON KEY(${n}) traps ${k}`, async (p) => {
      await startProgram(p, `ON KEY(${n}) GOSUB h: KEY(${n}) ON\nDO: LOOP UNTIL n\nPRINT "HIT"; n: END\nh: n = ${n}: RETURN`);
      await p.wait("RC.app.runner.state === 'running'", 3000);
      await p.key(k);
      await p.waitState(['ended', 'paused'], 4000);
      p.assert.equal(await p.state(), 'ended');
      p.assert.match(await p.screen(), new RegExp('HIT ' + n));
    });
  }
  t.test('KEY(1) OFF leaves F1 in the INKEY$ buffer instead of trapping', async (p) => {
    await startProgram(p, 'ON KEY(1) GOSUB h: KEY(1) OFF\nDO: k$ = INKEY$: LOOP UNTIL LEN(k$)\nPRINT "KEY"; ASC(MID$(k$, 2)); "T"; t: END\nh: t = 1: RETURN');
    await p.wait("RC.app.runner.state === 'running'", 3000);
    await p.key('F1');
    await p.waitState('ended', 4000);
    p.assert.match(await p.screen(), /KEY 59 T 0/);
  });
  t.test('KEY(1) STOP defers the trap until KEY(1) ON', async (p) => {
    await startProgram(p, 'ON KEY(1) GOSUB h: KEY(1) STOP\nt! = TIMER: DO WHILE TIMER - t! < .8: LOOP\nPRINT "BEFORE"; c\nKEY(1) ON\nPRINT "AFTER"; c: END\nh: c = c + 1: RETURN');
    await p.wait("RC.app.runner.state === 'running'", 3000);
    await p.key('F1');
    await p.waitState('ended', 4000);
    const s = await p.screen();
    p.assert.match(s, /BEFORE 0/);
    p.assert.match(s, /AFTER 1/);
  });
  t.test('a user-defined KEY 15 traps a letter by scan code', async (p) => {
    await startProgram(p, 'KEY 15, CHR$(0) + CHR$(30): ON KEY(15) GOSUB h: KEY(15) ON\nDO: LOOP UNTIL n\nPRINT "A-TRAP"; n; "["; INKEY$; "]": END\nh: n = n + 1: RETURN');
    await p.wait("RC.app.runner.state === 'running'", 3000);
    await p.key('a');
    await p.waitState('ended', 4000);
    p.assert.match(await p.screen(), /A-TRAP 1 \[\]/);
  });
  t.test('a user-defined key with the Shift flag only traps Shift+key', async (p) => {
    await startProgram(p, 'KEY 15, CHR$(3) + CHR$(30): ON KEY(15) GOSUB h: KEY(15) ON\nDO: k$ = INKEY$: IF LEN(k$) THEN p$ = p$ + k$\nLOOP UNTIL n\nPRINT "SHIFT"; n; "["; p$; "]": END\nh: n = n + 1: RETURN');
    await p.wait("RC.app.runner.state === 'running'", 3000);
    await p.key('a');
    await p.sleep(150);
    p.assert.equal(await p.state(), 'running');
    await p.key('a', { shift: true });
    await p.waitState('ended', 4000);
    p.assert.match(await p.screen(), /SHIFT 1 \[a\]/);
  });
  t.test('ON KEY handler runs for each press', async (p) => {
    await startProgram(p, 'ON KEY(2) GOSUB h: KEY(2) ON\nDO: LOOP UNTIL n >= 3\nPRINT "COUNT"; n: END\nh: n = n + 1: RETURN');
    await p.wait("RC.app.runner.state === 'running'", 3000);
    for (let i = 0; i < 3; i++) { await p.key('F2'); await p.sleep(60); }
    await p.waitState('ended', 4000);
    p.assert.match(await p.screen(), /COUNT 3/);
  });

  // ---- INP(&H60) scan codes ----------------------------------------------------------------------------------
  t.test('INP(&H60) reports the make code on keydown and break code on keyup', async (p) => {
    await startProgram(p, INP_PROG);
    await rawKey(p, 'rawKeyDown', 'KeyA', 'a', 65);
    p.assert.equal(await scanAfter(p), 30);
    await rawKey(p, 'keyUp', 'KeyA', 'a', 65);
    p.assert.equal(await scanAfter(p), 30 + 128);
  });
  for (const [code, key, vk, sc] of [['ArrowUp', 'ArrowUp', 38, 72], ['Escape', 'Escape', 27, 1], ['Space', ' ', 32, 57], ['Enter', 'Enter', 13, 28], ['ControlLeft', 'Control', 17, 29], ['KeyZ', 'z', 90, 44]]) {
    t.test(`INP(&H60) gives scan code ${sc} for ${code}`, async (p) => {
      await startProgram(p, INP_PROG);
      await rawKey(p, 'rawKeyDown', code, key, vk);
      p.assert.equal(await scanAfter(p), sc);
      await rawKey(p, 'keyUp', code, key, vk);
      p.assert.equal(await scanAfter(p), sc | 0x80);
    });
  }
  t.test('a game loop polling INP(&H60) sees the arrow held down', async (p) => {
    await startProgram(p, 'x = 0\nDO\nIF INP(&H60) = 77 THEN x = x + 1\nIF INP(&H60) = 1 THEN EXIT DO\nLOOP\nPRINT "MOVED"; x > 0');
    await rawKey(p, 'rawKeyDown', 'ArrowRight', 'ArrowRight', 39);
    await p.sleep(150);
    await rawKey(p, 'keyUp', 'ArrowRight', 'ArrowRight', 39);
    await rawKey(p, 'rawKeyDown', 'Escape', 'Escape', 27);
    await rawKey(p, 'keyUp', 'Escape', 'Escape', 27);
    await p.waitState('ended', 4000);
    p.assert.match(await p.screen(), /MOVED-1/);
  });

  // ---- focus routing ------------------------------------------------------------------------------------------
  t.test('keys are NOT delivered to the program when the editor has focus', async (p) => {
    await startProgram(p, INKEY_PROG);
    await p.ev('RC.app.active.editor.ta.focus()');
    await p.key('q');
    await p.sleep(150);
    p.assert.equal(await p.state(), 'running');
    p.assert.equal(await p.ev('RC.app.runner.keyboard.buf.length'), 0);
  });
  t.test('clicking the canvas gives keys back to the program', async (p) => {
    await startProgram(p, INKEY_PROG);
    await p.ev('RC.app.active.editor.ta.focus()');
    await p.click('#screen');
    await p.sleep(50);
    p.assert.equal(await p.focusedId(), 'screen');
    await p.key('k');
    await p.waitState('ended', 3000);
    p.assert.match(await p.screen(), /CODES 107/);
  });
  t.test('the screen hint appears when the canvas loses focus while running', async (p) => {
    await startProgram(p, INKEY_PROG);
    p.assert.equal(await p.ev("document.getElementById('screenHint').classList.contains('show')"), false);
    await p.ev('RC.app.active.editor.ta.focus()');
    await p.sleep(50);
    p.assert.equal(await p.ev("document.getElementById('screenHint').classList.contains('show')"), true);
    p.assert.match(await p.text('#screenHint'), /Click the screen/);
    p.assert.equal(await p.ev("document.getElementById('screenFrame').classList.contains('focused')"), false);
  });
  t.test('the screen hint hides again when the canvas is focused', async (p) => {
    await startProgram(p, INKEY_PROG);
    await p.ev('RC.app.active.editor.ta.focus()');
    await p.sleep(50);
    await p.click('#screen');
    await p.sleep(50);
    p.assert.equal(await p.ev("document.getElementById('screenHint').classList.contains('show')"), false);
  });
  t.test('the screen hint is not shown when no program is running', async (p) => {
    await p.runProgram('PRINT 1');
    await focusScreen(p);
    await p.ev('RC.app.active.editor.ta.focus()');
    await p.sleep(50);
    p.assert.equal(await p.ev("document.getElementById('screenHint').classList.contains('show')"), false);
  });
  t.test('typing in the editor while a program runs does not end an INPUT', async (p) => {
    await startProgram(p, 'INPUT a$: PRINT "DONE"');
    await waitInput(p);
    await p.ev('RC.app.active.editor.ta.focus()');
    await p.key('Enter');
    await p.sleep(150);
    p.assert.equal(await p.state(), 'waiting');
    await stopAll(p);
    await p.ev('RC.app.active.editor.undo && RC.app.active.editor.undo()');
  });
  t.test('after the program ends, keys on the canvas drive the IDE (F5 runs again)', async (p) => {
    await p.runProgram('PRINT "RUN"; RND >= 0');
    await focusScreen(p);
    const before = await p.ev('RC.app.runCount');
    await p.key('F5');
    await p.waitState('ended');
    p.assert.equal(await p.ev('RC.app.runCount'), before + 1);
  });

  // ---- paste ------------------------------------------------------------------------------------------
  const paste = (p, text) => p.ev(`(() => { const dt = new DataTransfer(); dt.setData('text/plain', ${JSON.stringify(text)}); const e = new ClipboardEvent('paste', { clipboardData: dt, bubbles: true, cancelable: true }); document.getElementById('screen').dispatchEvent(e); return e.defaultPrevented; })()`);
  t.test('pasting into the canvas types the text into INPUT', async (p) => {
    await startProgram(p, 'INPUT a$: PRINT "[" + a$ + "]"');
    await waitInput(p);
    p.assert.equal(await paste(p, 'pasted'), true);
    await p.sleep(80);
    p.assert.equal(await p.state(), 'waiting');
    await p.key('Enter');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /\[pasted\]/);
  });
  t.test('pasting text with a newline submits the INPUT', async (p) => {
    await startProgram(p, 'INPUT a, b: PRINT "SUM"; a + b');
    await waitInput(p);
    await paste(p, '10,32\n');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /SUM 42/);
  });
  t.test('pasting multiple lines answers successive INPUTs', async (p) => {
    await startProgram(p, 'LINE INPUT a$: LINE INPUT b$: PRINT a$; "|"; b$');
    await waitInput(p);
    await paste(p, 'first\r\nsecond\n');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /first\|second/);
  });
  t.test('pasting into the canvas with no program running is ignored', async (p) => {
    await p.runProgram('PRINT "X"');
    p.assert.equal(await paste(p, 'junk'), false);
    p.assert.equal(await p.ev('RC.app.runner.keyboard.buf.length'), 0);
  });

  // ---- full-size output -----------------------------------------------------------------------------------
  t.test('F4 shows the output full size and Escape returns', async (p) => {
    await p.runProgram('PRINT "BIG"');
    await p.ev('RC.app.active.editor.ta.focus()');
    await p.key('F4');
    p.assert.equal(await p.ev("document.getElementById('app').classList.contains('screen-max')"), true);
    const r = await p.rect('#screenArea');
    p.assert.ok(r.w >= 1390 && r.h >= 890, JSON.stringify(r));
    p.assert.equal(await p.focusedId(), 'screen');
    await p.key('Escape');
    p.assert.equal(await p.ev("document.getElementById('app').classList.contains('screen-max')"), false);
  });
  t.test('full-size view shows a banner explaining how to return', async (p) => {
    await p.runProgram('PRINT 1');
    await p.key('F4');
    p.assert.match(await p.text('.screen-banner'), /Press F4 or Esc/);
    await p.wait("!document.querySelector('.screen-banner')", 4000);
    await p.key('F4');
    p.assert.equal(await p.ev("document.getElementById('app').classList.contains('screen-max')"), false);
  });
  t.test('the Full size output button toggles the full-size view', async (p) => {
    await p.click('#screenActions button[title^="Full size output"]');
    p.assert.equal(await p.ev("document.getElementById('app').classList.contains('screen-max')"), true);
    await p.key('Escape');
    p.assert.equal(await p.ev("document.getElementById('app').classList.contains('screen-max')"), false);
  });
  t.test('View menu Output Screen Full Size toggles the view', async (p) => {
    await p.menu('View', 'Output Screen Full Size');
    p.assert.equal(await p.ev("document.getElementById('app').classList.contains('screen-max')"), true);
    await p.key('Escape');
    p.assert.equal(await p.ev("document.getElementById('app').classList.contains('screen-max')"), false);
  });
  t.test('Escape in full-size view goes to a running program and does not exit', async (p) => {
    await startProgram(p, INKEY_PROG);
    await p.ev("document.getElementById('app').classList.add('screen-max')");
    await p.key('Escape');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /CODES 27/);
    p.assert.equal(await p.ev("document.getElementById('app').classList.contains('screen-max')"), true);
  });
  t.test('in full-size view keys reach the program even if the canvas lost focus', async (p) => {
    await startProgram(p, INKEY_PROG);
    await p.ev("document.getElementById('app').classList.add('screen-max'); document.activeElement.blur(); RC.app.active.editor.ta.focus()");
    await p.key('m');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /CODES 109/);
  });

  // ---- break keys ----------------------------------------------------------------------------------------------
  t.test('Ctrl+Break pauses a running program', async (p) => {
    await startProgram(p, 'DO: i = i + 1: LOOP');
    await p.key('Pause', { ctrl: true });
    await p.waitState('paused', 3000);
    p.assert.match(await p.status(), /^Break/);
    p.assert.equal(await p.ev("document.getElementById('tbPause').disabled"), true);
  });
  t.test('Ctrl+Break works even when the editor has focus', async (p) => {
    await startProgram(p, 'DO: i = i + 1: LOOP');
    await p.ev('RC.app.active.editor.ta.focus()');
    await p.key('Pause', { ctrl: true });
    await p.waitState('paused', 3000);
  });
  t.test('Ctrl+C on the canvas pauses the program', async (p) => {
    await startProgram(p, 'DO: i = i + 1: LOOP');
    await p.key('c', { ctrl: true });
    await p.waitState('paused', 3000);
    p.assert.match(await p.status(), /Break/);
  });
  t.test('Ctrl+C in the editor does not pause the program', async (p) => {
    await startProgram(p, 'DO: i = i + 1: LOOP');
    await p.ev('RC.app.active.editor.ta.focus()');
    await p.key('c', { ctrl: true });
    await p.sleep(200);
    p.assert.equal(await p.state(), 'running');
  });
  t.test('Ctrl+Break during INPUT pauses the program', async (p) => {
    await startProgram(p, 'INPUT a$');
    await waitInput(p);
    await p.key('Pause', { ctrl: true });
    await p.waitState('paused', 3000);
  });
  t.test('after Ctrl+Break, F5 continues the program', async (p) => {
    await startProgram(p, 'DO: i = i + 1: LOOP UNTIL INKEY$ = "q": PRINT "QUIT"');
    await p.key('Pause', { ctrl: true });
    await p.waitState('paused', 3000);
    await p.ev('RC.app.active.editor.ta.focus()');
    await p.key('F5');
    await p.waitState('running', 3000);
    p.assert.equal(await p.focusedId(), 'screen');
    await p.key('q');
    await p.waitState('ended', 3000);
    p.assert.match(await p.screen(), /QUIT/);
  });
  t.test('Break shows the execution line in the editor', async (p) => {
    await startProgram(p, 'PRINT "A"\nDO\ni = i + 1\nLOOP');
    await p.key('Pause', { ctrl: true });
    await p.waitState('paused', 3000);
    const line = await p.ev('RC.app.active.editor.marks.exec');
    p.assert.ok(line === 2 || line === 3 || line === 1, 'exec line ' + line);
  });
  t.test('the Pause toolbar button pauses a running program', async (p) => {
    await startProgram(p, 'DO: LOOP');
    await p.click('#tbPause');
    await p.waitState('paused', 3000);
  });
};
