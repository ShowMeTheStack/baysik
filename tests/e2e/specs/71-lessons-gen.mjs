// Test generator for the tutorial: one test per lesson start, per step, per completion.
// Used by 71-lessons-*.spec.mjs. Not a spec itself.
import {
  LESSONS, TOURS, fileFor, header, tourInfo, htmlText, waitStep, tourButton, quizOption, quizFeedback, quizOptions,
  assertSpotlight, assertPopInView, stopIfActive, pressF5, answer, run, screenKey, edit, replace, insertBefore, insertAfter,
  append, clickGutter, bpLines, clearBps, catchStars, ensureStep, startFromDialog, sleep,
} from './71-lessons-lib.mjs';

const WAIT_TEXT = {
  run: 'Waiting for you to run the program (F5)…',
  codeHas: 'Waiting for your code change…',
  output: 'Waiting for the right output…',
  paused: 'Waiting for the program to pause…',
  breakpoint: 'Waiting for a breakpoint…',
};
const checkKind = (c) => ['run', 'codeHas', 'output', 'paused', 'breakpoint'].find((k) => c[k] !== undefined);

/** Real typing at the end of the editor */
async function typeAtEnd(p, typed, inserted) {
  await p.ev('(() => { const e = RC.app.active.editor; e.ta.focus(); const n = e.ta.value.length; e.ta.setSelectionRange(n, n); })()');
  await p.sleep(40);
  if (!(await p.code()).endsWith('\n')) await p.key('Enter');
  if (typed) await p.type(typed);
  if (inserted) await p.insertText(inserted);
}

/** Guess-the-number by binary search, reading the hints off the screen */
async function playGuess(p) {
  await stopIfActive(p);
  await pressF5(p);
  let lo = 1, hi = 100;
  for (let k = 0; k < 12; k++) {
    await p.waitState(['waiting', 'ended', 'error'], 8000);
    if ((await p.state()) !== 'waiting') break;
    const g = Math.floor((lo + hi) / 2);
    await p.ev(`RC.app.runner.keyboard.type(${JSON.stringify(g + '\n')}); RC.app.runner.kick()`);
    await p.wait(`(() => { const st = RC.app.runner.state; const ls = RC.app.runner.display.textLines().map((s) => RC.fromCP437(s, false).trim()).filter(Boolean); const last = ls[ls.length - 1] || ''; return st === 'ended' || (st === 'waiting' && RC.app.runner.keyboard.buf.length === 0 && /Your guess\\?$/.test(last) && /Too (low|high)/.test(ls[ls.length - 2] || '')); })()`, 8000);
    if ((await p.state()) === 'ended') break;
    const resp = await p.ev("(() => { const ls = RC.app.runner.display.textLines().map((s) => RC.fromCP437(s, false).trim()).filter(Boolean); return ls[ls.length - 2]; })()");
    if (/Too low/.test(resp)) lo = g + 1; else hi = g - 1;
  }
  await p.waitState('ended', 5000);
  p.assert.match(await p.screen(), /You got it in/);
}

/** Start a real-time program, wait for `ready` on screen, then press keys */
async function runKeys(p, ready, keys, until = ['ended', 'error']) {
  await stopIfActive(p);
  await pressF5(p);
  if (ready) await p.waitScreen(ready, 8000);
  for (const k of keys) {
    if (typeof k === 'number') await p.sleep(k);
    else await screenKey(p, k);
  }
  if (until) await p.waitState(until, 10000);
}

// Each solution performs exactly what the step asks (key: "<lesson id>:<step number>").
export const SOLUTIONS = {
  'hello-print:2': (p) => run(p),
  'hello-print:4': async (p) => { await replace(p, 'PRINT "Hello!"', 'PRINT "Hello, Sam!"'); await run(p); },
  'hello-print:5': async (p) => { await typeAtEnd(p, 'PRINT ', '"I like pizza"'); },
  'calculator:2': (p) => run(p),
  'calculator:3': async (p) => { await append(p, 'PRINT 123 * 45'); await run(p); },
  'calculator:5': (p) => run(p),
  'colors-comments:2': (p) => run(p),
  'colors-comments:4': async (p) => { await typeAtEnd(p, 'COLOR 13\n', 'PRINT "My cat"'); },
  'colors-comments:5': (p) => run(p),
  'variables:2': (p) => run(p),
  'variables:3': async (p) => { await replace(p, 'apples = 5', 'apples = 10'); await run(p); },
  'variables:5': (p) => run(p),
  'strings:2': (p) => run(p),
  'strings:3': async (p) => { await replace(p, '"Rex"', '"Tom"'); await replace(p, '"Woof"', '"Meow"'); await run(p); },
  'strings:5': (p) => run(p),
  'input:2': (p) => run(p, ['Sam', '10']),
  'input:4': (p) => insertAfter(p, 'INPUT "How old are you"; age', 'INPUT "Favorite color"; c$\nPRINT "I like "; c$; " too!"'),
  'input:5': (p) => run(p, ['Sam', '10', 'blue']),
  'data-types:2': (p) => run(p),
  'data-types:5': (p) => run(p),
  'arithmetic:3': (p) => run(p),
  'arithmetic:4': (p) => append(p, 'PRINT (80 + 90 + 70) / 3'),
  'arithmetic:6': (p) => run(p),
  'if-then:2': (p) => run(p, ['7']),
  'if-then:3': (p) => run(p, ['30']),
  'if-then:5': async (p) => { await insertBefore(p, 'PRINT "Thanks', 'IF age = 10 THEN PRINT "Double digits!"'); await run(p, ['10']); },
  'if-blocks:2': (p) => run(p, ['open sesame']),
  'if-blocks:4': (p) => run(p, ['95']),
  'if-blocks:5': (p) => replace(p, '\nELSE\n', '\nELSEIF score >= 25 THEN\n    PRINT "Not bad."\nELSE\n'),
  'logic:2': (p) => run(p, ['28', 'N']),
  'logic:4': async (p) => { await insertAfter(p, 'r$ = UCASE$(r$)', 'IF t < 0 AND r$ = "Y" THEN PRINT "Snowman weather!"'); await run(p, ['-5', 'Y']); },
  'select-case:2': (p) => run(p, ['6']),
  'select-case:4': (p) => run(p, ['Lion', '10']),
  'select-case:5': async (p) => { await insertBefore(p, '    CASE "dog"', '    CASE "parrot", "eagle"\n        PRINT "A bird!"'); await run(p, ['parrot', '10']); },
  'for-next:2': (p) => run(p),
  'for-next:3': async (p) => { await replace(p, 'FOR i = 1 TO 5', 'FOR i = 1 TO 10'); await run(p); },
  'for-next:5': (p) => run(p, ['7']),
  'for-step:2': (p) => run(p),
  'for-step:4': (p) => run(p),
  'for-step:5': async (p) => { await replace(p, 'FOR n = 1 TO 100', 'FOR n = 2 TO 100 STEP 2'); await run(p); },
  'for-step:7': (p) => run(p),
  'do-loop:2': (p) => run(p, ['burger', 'pizza']),
  'do-loop:4': (p) => run(p),
  'do-loop:6': (p) => run(p, ['5', '7', '0']),
  'nested-loops:2': (p) => run(p),
  'nested-loops:3': (p) => replace(p, 'FOR col = 1 TO row', 'FOR col = 1 TO 5'),
  'nested-loops:4': (p) => run(p),
  'nested-loops:6': (p) => run(p),
  'random:2': async (p) => { await run(p); await run(p); },
  'random:4': async (p) => { await append(p, 'IF RND < .5 THEN PRINT "Heads" ELSE PRINT "Tails"'); await run(p); },
  'random:6': (p) => run(p),
  'guess-game:2': (p) => run(p, ['50']),
  'guess-game:4': (p) => playGuess(p),
  'guess-game:5': (p) => append(p, 'IF tries <= 7 THEN PRINT "Super brain!"'),
  'guess-game:6': async (p) => {
    await replace(p, '        PRINT "Too low!"', '        COLOR 9\n        PRINT "Too low!"');
    await replace(p, '        PRINT "Too high!"', '        COLOR 12\n        PRINT "Too high!"');
  },
  'guess-game:7': (p) => playGuess(p),
  'string-basics:2': (p) => run(p),
  'string-basics:5': (p) => run(p, ['racecar']),
  'string-basics:6': (p) => append(p, 'PRINT "Letters:"; LEN(w$)'),
  'string-tools:2': (p) => run(p),
  'string-tools:5': (p) => run(p, ['hello']),
  'string-tools:6': async (p) => { await replace(p, 'shift = 3', 'shift = 23'); await run(p, ['KHOOR']); },
  'arrays:2': (p) => run(p, ['10', '20', '30', '40', '50']),
  'arrays:3': async (p) => {
    await insertAfter(p, 'best = score(1)', 'worst = score(1)');
    await insertAfter(p, '    IF score(i) > best', '    IF score(i) < worst THEN worst = score(i)');
    await append(p, 'PRINT "Worst:"; worst');
  },
  'arrays:4': (p) => run(p, ['10', '20', '5', '40', '50']),
  'data-read:2': (p) => run(p),
  'data-read:4': (p) => run(p),
  'data-read:5': async (p) => { await insertBefore(p, 'DATA END, 0', 'DATA Mango, 1.2'); await run(p); },
  'arrays-2d:2': (p) => run(p),
  'arrays-2d:3': (p) => insertAfter(p, 'board(1, 3) = "O"', 'board(3, 1) = "O"'),
  'arrays-2d:5': (p) => run(p, ['apple', 'pear, ripe', '']),
  'gosub:2': (p) => run(p),
  'gosub:4': async (p) => { await replace(p, 'STRING$(20, "=")', 'STRING$(30, "=")'); await run(p); },
  'gosub:6': (p) => run(p, ['no', 'yes']),
  'subs:2': (p) => run(p),
  'subs:3': async (p) => { await insertAfter(p, 'Banner "to my program"', 'Banner "by Sam"'); await run(p); },
  'subs:6': (p) => run(p),
  'functions:2': (p) => run(p),
  'functions:3': async (p) => {
    await insertAfter(p, 'DECLARE FUNCTION IsEven% (n)', 'DECLARE FUNCTION Cube (n)');
    await insertAfter(p, 'PRINT "Area of 3 x 4 ="; Area(3, 4)', 'PRINT "Cube of 3 ="; Cube(3)');
    await append(p, '\nFUNCTION Cube (n)\n    Cube = n * n * n\nEND FUNCTION');
    await run(p);
  },
  'functions:5': (p) => run(p),
  'byref-byval:2': (p) => run(p),
  'byref-byval:4': (p) => run(p),
  // the natural edit the step asks for: avg as the 4th parameter
  'byref-byval:5': (p) => edit(p, (c) => c.split('MinMax (a(), lo, hi)').join('MinMax (a(), lo, hi, avg)')),
  'scope:2': (p) => run(p),
  'scope:3': async (p) => { await replace(p, '    STATIC calls\n', ''); await run(p); },
  'recursion:2': (p) => run(p),
  'recursion:3': (p) => clickGutter(p, 'Fact# = 1'),
  'recursion:4': (p) => run(p, [], { until: 'paused' }),
  'recursion:6': async (p) => {
    await stopIfActive(p);
    await clearBps(p);
    await insertAfter(p, 'DECLARE SUB Countdown (n%)', 'DECLARE FUNCTION Fib& (n%)');
    await insertAfter(p, 'NEXT i%', 'PRINT "Fib(20) ="; Fib&(20)');
    await append(p, '\nFUNCTION Fib& (n%)\n    IF n% < 2 THEN\n        Fib& = n%\n    ELSE\n        Fib& = Fib&(n% - 1) + Fib&(n% - 2)\n    END IF\nEND FUNCTION');
    await run(p, [], { timeout: 30000 });
  },
  'type-records:2': (p) => run(p),
  'type-records:3': async (p) => { await insertAfter(p, '    power AS SINGLE', '    level AS INTEGER'); await insertAfter(p, 'DIM team(1 TO 3) AS Hero', 'team(1).level = 5'); },
  'type-records:5': (p) => run(p),
  'bug-hunt:2': (p) => run(p),
  'bug-hunt:3': (p) => clickGutter(p, 'total = total + marks(i)'),
  'bug-hunt:4': (p) => run(p, [], { until: 'paused' }),
  'bug-hunt:8': async (p) => {
    await p.key('F2', { ctrl: true });
    await p.waitState(['ended', 'error', 'idle', 'stopped'], 3000).catch(() => {});
    await replace(p, 'FOR i = 1 TO 4', 'FOR i = 1 TO 5');
    await clickGutter(p, 'total = total + marks(i)');
    p.assert.deepEqual(await bpLines(p), [], 'clicking the red dot again removes the breakpoint');
    await run(p);
  },
  'on-error:2': (p) => run(p, ['0', '1']),
  'on-error:5': (p) => run(p),
  'on-error:6': (p) => insertBefore(p, 'PRINT "High score holder', 'ERROR 53'),
  'text-screen:2': (p) => run(p),
  'text-screen:3': (p) => insertAfter(p, 'DrawBox 5, 20, 7, 40, 14', 'DrawBox 14, 5, 4, 20, 10'),
  'text-screen:4': (p) => run(p),
  'text-screen:6': (p) => run(p),
  'inkey-timer:2': (p) => runKeys(p, /Arrow keys move/, ['ArrowLeft', 'ArrowUp', 'ArrowRight', 'Escape']),
  'inkey-timer:5': (p) => runKeys(p, /^GO!/m, ['a']),
  'inkey-timer:7': (p) => append(p, 'IF (TIMER - start!) < .3 THEN PRINT "Lightning fast!"'),
  'print-using:2': (p) => run(p),
  'print-using:4': (p) => run(p),
  'print-using:5': async (p) => { await append(p, 'PRINT USING "Pi is about #.####"; 3.14159265'); await run(p); },
  'drawing:2': (p) => run(p),
  'drawing:4': (p) => append(p, 'LINE (220, 240)-(270, 290), 11, BF'),
  'drawing:5': (p) => append(p, 'LINE (520, 300)-(540, 400), 6, BF\nCIRCLE (530, 280), 40, 10\nPAINT (530, 280), 10, 10'),
  'drawing:6': (p) => run(p),
  'draw-turtle:2': (p) => run(p),
  'draw-turtle:3': (p) => append(p, 'DRAW "BM100,450 C10 E40 F40 L80"'),
  'draw-turtle:4': (p) => run(p),
  'window-view:2': (p) => run(p),
  'window-view:3': (p) => insertAfter(p, '    PSET (x, COS(x)), 11', '    PSET (x, SIN(2 * x) / 2), 12'),
  'window-view:4': (p) => run(p),
  'palettes:2': (p) => run(p),
  'palettes:3': (p) => replace(p, 'PALETTE i + 1, i\n', 'PALETTE i + 1, i * 65536\n'),
  'palettes:5': (p) => runKeys(p, null, [800, 'a']),
  'sprites:2': (p) => run(p, [], { timeout: 20000 }),
  'sprites:5': (p) => runKeys(p, /Any key stops/, [300, 'a']),
  'sprites:6': (p) => replace(p, 'dx = 3', 'dx = 6'),
  'sound-music:2': (p) => run(p, [], { timeout: 25000 }),
  'sound-music:4': (p) => append(p, 'PLAY "L4 CCGGAA L2 G L4 FFEEDD L2 C"'),
  'sound-music:5': (p) => run(p, [], { timeout: 40000 }),
  'sound-music:7': (p) => run(p, [], { timeout: 25000 }),
  'seq-files:2': (p) => run(p),
  'seq-files:5': (p) => run(p, ['Fido', 'dog', '4']),
  'seq-files:7': async (p) => {
    await insertAfter(p, '    INPUT #1, pet$, kind$, age', '    n = n + 1');
    await append(p, 'PRINT "Pets on file:"; n');
    await run(p, ['Rex2', 'dog', '2']);
  },
  'random-files:2': (p) => run(p, ['3']),
  'random-files:4': async (p) => { await insertBefore(p, 'INPUT "Which record', 'GET #1, 2, c: c.age = 42: PUT #1, 2, c'); await run(p, ['2']); },
  'random-files:6': (p) => run(p),
  'line-numbers:2': (p) => run(p, ['1', '6', '2', '3']),
  'line-numbers:4': async (p) => { await insertAfter(p, '10 REM', '15 TRON'); await run(p, ['3']); },
  'events:2': (p) => runKeys(p, /Level: 5/, ['ArrowUp', 'ArrowUp', 150, 'ArrowDown', 150, 'Escape']),
  'events:4': (p) => replace(p, 'ON TIMER(1)', 'ON TIMER(5)'),
  'multi-file:2': (p) => run(p),
  'multi-file:4': (p) => edit(p, (c) => "' $INCLUDE: 'MYLIB.BI'\n" + c.replace('\nFUNCTION Stars$ (n%)\n    Stars$ = STRING$(n%, "*")\nEND FUNCTION\n', '\n')),
  'multi-file:5': (p) => run(p),
  'memory-ports:2': (p) => run(p),
  'memory-ports:3': (p) => replace(p, 'POKE offset + 1, (i MOD 15) + 1', 'POKE offset + 1, 14 + 16 * 1'),
  'memory-ports:5': (p) => run(p),
  'star-1-field:2': (p) => runKeys(p, /STAR CATCHER/, ['ArrowLeft', 'ArrowRight', 'ArrowRight', 'Escape']),
  'star-1-field:5': async (p) => {
    await replace(p, 'IF k$ = CHR$(0) + "K" AND', 'IF (k$ = CHR$(0) + "K" OR k$ = "a") AND');
    await replace(p, 'IF k$ = CHR$(0) + "M" AND', 'IF (k$ = CHR$(0) + "M" OR k$ = "d") AND');
  },
  'star-1-field:6': async (p) => {
    await runKeys(p, /STAR CATCHER/, ['a', 'a', 150], null);
    const row = await p.ev("RC.fromCP437(RC.app.runner.display.textLines()[22], false)");
    p.assert.equal(row.indexOf('\\_/'), 33, 'two presses of A move the basket 4 columns left');
    await screenKey(p, 'd');
    await screenKey(p, 'Escape');
    await p.waitState(['ended', 'error'], 8000);
  },
  'star-2-falling:2': (p) => runKeys(p, /STAR CATCHER/, [300, 'Escape']),
  'star-2-falling:5': (p) => clickGutter(p, 'score = score + 10'),
  'star-2-falling:6': async (p) => {
    await stopIfActive(p);
    await pressF5(p);
    await p.waitScreen(/STAR CATCHER/, 8000);
    p.assert.ok(await catchStars(p, "RC.app.runner.state === 'paused'", 40000), 'a star was caught and the breakpoint paused the game');
  },
  'star-2-falling:8': async (p) => { await stopIfActive(p); await clearBps(p); await replace(p, 'delay! = .12', 'delay! = .07'); },
  'star-3-refactor:2': (p) => runKeys(p, /STAR CATCHER/, [300, 'Escape']),
  'star-3-refactor:5': (p) => clickGutter(p, 'stars(i).x = INT(RND * 76) + 3'),
  'star-3-refactor:6': (p) => run(p, [], { until: 'paused' }),
  'star-3-refactor:8': async (p) => {
    await stopIfActive(p);
    await clearBps(p);
    await insertAfter(p, '    IF RND < .15 THEN stars(i).kind = 2 ELSE stars(i).kind = 1', '    IF RND < .05 THEN stars(i).kind = 3');
  },
  'star-4-polish:2': (p) => runKeys(p, /Press any key to start/, ['a', 400, 'Escape'], null).then(() => p.waitScreen(/Play again/, 10000)),
  'star-4-polish:6': (p) => insertAfter(p, '    DrawField\n', '    PLAY "T180 O3 L16 CDEFGAB>C"'),
  'star-4-polish:7': (p) => runKeys(p, /Press any key to start/, ['a', 600, 'Escape'], null).then(() => p.waitScreen(/Play again/, 10000)),
};

// Extra assertions after a step's check is done (key as above)
const AFTER = {
  'random:2': async (p) => { const n = ((await p.screen()).match(/You rolled a [1-6]\b/g) || []).length; p.assert.ok(n >= 5, 'five rolls are shown'); },
  'recursion:4': async (p) => {
    const line = await p.ev('RC.app.active.editor.marks.exec');
    p.assert.equal((await p.ev(`RC.app.active.editor.getLine(${line})`)).trim(), 'Fact# = 1', 'paused on the base case line');
  },
  'bug-hunt:4': async (p) => {
    const line = await p.ev('RC.app.active.editor.marks.exec');
    p.assert.equal((await p.ev(`RC.app.active.editor.getLine(${line})`)).trim(), 'total = total + marks(i)');
  },
  'star-3-refactor:6': async (p) => {
    const line = await p.ev('RC.app.active.editor.marks.exec');
    p.assert.equal((await p.ev(`RC.app.active.editor.getLine(${line})`)).trim(), 'stars(i).x = INT(RND * 76) + 3');
  },
  'events:2': async (p) => p.assert.match(await p.screen(), /Level: 6/),
  'line-numbers:2': async (p) => p.assert.match(await p.screen(), /6 squared is 36/),
  'line-numbers:4': async (p) => { const sc = await p.screen(); p.assert.match(sc, /\[40\]1\) Square a number/); p.assert.match(sc, /\[50\]Choice\? 3/); },
  'scope:3': async (p) => p.assert.doesNotMatch(await p.screen(), /called 2 time/),
  'seq-files:7': async (p) => p.assert.match(await p.screen(), /Pets on file: 5/),
  'multi-file:2': async (p) => p.assert.ok(await p.ev("RC.app.vfs.exists('C:\\\\LESSONS\\\\MYLIB.BI') && RC.app.vfs.exists('C:\\\\LESSONS\\\\LEVEL2.BAS')")),
  'multi-file:5': async (p) => p.assert.match(await p.screen(), /score so far: 1500/),
  'seq-files:2': async (p) => p.assert.ok(await p.ev("RC.app.vfs.exists('C:\\\\LESSONS\\\\PETS.TXT')"), 'PETS.TXT written next to the lesson'),
};

// Per-step extra assertions on panels/state for non-check steps
const STEP_EXTRA = {
  'recursion:5': async (p) => { p.assert.match(await p.panelText(), /FACT#/i); p.assert.equal(await p.state(), 'paused'); },
  'bug-hunt:5': async (p) => { const t = await p.panelText(); p.assert.match(t, /total/i); p.assert.match(t, /marks/i); },
  'bug-hunt:7': async (p) => p.assert.ok(await p.exists('.bpanel.active input'), 'watch panel has an expression input'),
  'star-2-falling:7': async (p) => p.assert.match(await p.panelText(), /lives/i),
  'star-3-refactor:7': async (p) => p.assert.match(await p.panelText(), /RESETSTAR/i),
};

/** Steps that spotlight the editor gutter while several editors (tabs) are open; checked separately */
export const GUTTER_STEPS = new Set(['recursion:3', 'bug-hunt:3', 'star-2-falling:5', 'star-3-refactor:5']);

const pageLesson = (p, li) => p.fn((i) => JSON.parse(JSON.stringify(RC.LESSONS[i])), li);

async function assertPracticeFile(p, L, s) {
  const file = fileFor(L);
  if (s.code !== undefined) {
    await p.wait(`RC.app.active && RC.app.active.path === ${JSON.stringify(file)} && RC.app.active.editor.getValue() === ${JSON.stringify(s.code)}`, 4000)
      .catch(() => {});
    p.assert.equal(await p.activePath(), file, 'practice file is opened');
    p.assert.equal(await p.code(), s.code, 'editor shows the step code');
    p.assert.equal(await p.ev(`RC.app.decodeText(RC.app.vfs.readFile(${JSON.stringify(file)}))`), s.code, 'practice file saved on C:');
    p.assert.equal(await p.ev('RC.app.active.dirty'), false, 'practice file is not dirty');
    const err = await p.fn((path, text) => {
      try { RC.Basic.compileProgram([{ name: path, text }], { readInclude: () => "DECLARE FUNCTION Stars$ (n%)\nFUNCTION Stars$ (n%)\nStars$ = \"*\"\nEND FUNCTION\n" }); return null; } catch (e) { return String(e.message || e); }
    }, file, s.code);
    p.assert.equal(err, null, 'step code compiles');
  }
}

async function assertStepUI(p, li, si, L) {
  const s = L.steps[si];
  const info = await tourInfo(p);
  p.assert.ok(info, 'tour is active');
  p.assert.equal(info.header, 'Lesson ' + (li + 1) + ' · ' + L.unit);
  p.assert.equal(info.title, s.title);
  p.assert.equal(info.count, `${si + 1} / ${L.steps.length}`);
  const back = info.btns.find((b) => b.text === 'Back');
  p.assert.equal(back.disabled, si === 0, 'Back disabled only on the first step');
  p.assert.ok(info.btns.some((b) => b.text === 'Close'), 'Close button');
  if (!s.quiz) p.assert.equal(info.body, await htmlText(p, s.text), 'step text');
  let spotErr = null;
  if (s.sel && !GUTTER_STEPS.has(L.id + ':' + (si + 1))) { try { await assertSpotlight(p, s.sel); } catch (e) { spotErr = e; } } else if (!s.sel) {
    const hs = await p.ev("(() => { const s = document.querySelector('.tour-hole').style; return [parseFloat(s.width), parseFloat(s.height)]; })()");
    p.assert.deepEqual(hs, [0, 0], 'no spotlight when the step has no target');
  }
  await assertPopInView(p);
  if (s.panel) {
    p.assert.equal(await p.ev('RC.app.panels.active'), s.panel, 'requested panel opened');
    p.assert.ok(await p.visible('.bpanel.active'), 'panel visible');
  }
  // hint
  if (s.hint) {
    p.assert.equal(info.hintHidden, true, 'hint hidden at first');
    await tourButton(p, 'Hint');
    const after = await tourInfo(p);
    p.assert.equal(after.hintHidden, false, 'hint revealed');
    p.assert.equal(after.hintText, '💡 ' + (await htmlText(p, s.hint)));
  } else {
    p.assert.ok(!info.btns.some((b) => b.text === 'Hint'), 'no Hint button without a hint');
  }
  info.spotErr = spotErr;
  return info;
}

async function doQuiz(p, s, info, isLast, finishLabel) {
  const qz = s.quiz;
  p.assert.equal(info.body, await htmlText(p, qz.q), 'quiz question');
  p.assert.deepEqual(await quizOptions(p), await Promise.all(qz.options.map((o) => htmlText(p, o))), 'quiz options');
  const nextLabel = isLast ? finishLabel : 'Next';
  const nb = () => tourInfo(p).then((i) => i.btns.find((b) => b.text.replace(/\s+/g, ' ') === nextLabel.replace(/\s+/g, ' ')));
  p.assert.equal((await nb()).disabled, true, 'Next disabled before answering');
  p.assert.equal(await quizFeedback(p), '', 'no feedback yet');
  const explain = qz.explain || '';
  for (let k = 0; k < qz.options.length; k++) {
    if (k === qz.answer) continue;
    await quizOption(p, k);
    p.assert.equal(await quizFeedback(p), '✗ Not quite. ' + explain);
    p.assert.equal((await nb()).disabled, true, 'Next stays disabled after a wrong answer');
  }
  await quizOption(p, qz.answer);
  p.assert.equal(await quizFeedback(p), '✓ Correct! ' + explain);
  p.assert.equal((await nb()).disabled, false, 'Next enabled after the right answer');
}

async function doCheck(p, key, s, si, isLast) {
  const kind = checkKind(s.check);
  const info = await tourInfo(p);
  p.assert.equal(info.wait, WAIT_TEXT[kind], 'waiting text');
  p.assert.ok(info.btns.some((b) => b.text === 'Skip step'), 'Next reads "Skip step" while waiting');
  await sleep(700);
  p.assert.equal((await tourInfo(p)).wait, WAIT_TEXT[kind], 'check is not satisfied before the learner acts');
  const sol = SOLUTIONS[key];
  if (!sol) throw new Error('no solution for ' + key);
  await sol(p);
  await p.wait("(() => { const w = document.querySelector('.tour-pop .tour-wait'); return w && w.innerText === '✓ Done!'; })() || (RC.Tours.active && RC.Tours.active.i > " + si + ')', 8000);
  if (AFTER[key]) await AFTER[key](p);
}

async function stepTest(p, li, si) {
  await ensureStep(p, li, si);
  const L = await pageLesson(p, li);
  const s = L.steps[si];
  const key = L.id + ':' + (si + 1);
  const isLast = si === L.steps.length - 1;
  const finishLabel = li + 1 < LESSONS.length ? 'Complete ✓  Next lesson ▶' : 'Complete ✓';
  await assertPracticeFile(p, L, s);
  if (s.code === undefined && await p.ev(`RC.app.vfs.exists(${JSON.stringify(fileFor(L))})`)) {
    p.assert.ok(await p.ev(`!!RC.app.docByPath(${JSON.stringify(fileFor(L))})`), 'practice file stays open');
  }
  const info = await assertStepUI(p, li, si, L);
  if (STEP_EXTRA[key]) await STEP_EXTRA[key](p);
  if (s.quiz) await doQuiz(p, s, info, isLast, finishLabel);
  if (s.check) {
    await doCheck(p, key, s, si, isLast);
    if (!isLast) { await waitStep(p, si + 1, L.steps[si + 1].title, 4000); if (info.spotErr) throw info.spotErr; return; }
  }
  if (!s.check && !s.quiz) p.assert.equal(info.wait, null, 'no waiting text on an info step');
  if (!isLast) {
    await tourButton(p, 'Next');
    await waitStep(p, si + 1, L.steps[si + 1].title);
  }
  if (info.spotErr) throw info.spotErr;
}

// ---- tour-based lessons -----------------------------------------------------------------------------
const TOUR_SOL = {
  'first:2': async (p) => { await p.ev('(() => { const e = RC.app.active.editor; e.ta.focus(); e.ta.setSelectionRange(0, 0); })()'); await p.type('PRINT '); await p.insertText('"Hello, world!"'); },
  'first:3': async (p) => { await stopIfActive(p); await pressF5(p); await p.waitState('ended'); },
  'first:5': (p) => append(p, 'INPUT "What is your name"; n$\nPRINT "Hi, "; n$'),
  'first:6': (p) => run(p, ['Sam']),
  'first:7': async (p) => { await append(p, 'FOR i = 1 TO 10\n    PRINT i; "Hi!"\nNEXT i'); await run(p, ['Sam']); },
  'debug:2': (p) => clickGutter(p, 'Factorial# = 1'),
  'debug:3': (p) => run(p, [], { until: 'paused' }),
  'debug:7': async (p) => { for (let k = 0; k < 5; k++) { await p.key('F8'); await p.waitState('paused', 4000); } },
  'graphics:2': (p) => run(p, [], { timeout: 20000 }),
  'gw:2': async (p) => {
    await p.ev("document.getElementById('screen').focus()");
    await p.type('10 PRINT ');
    await p.insertText('"HELLO"');
    await p.key('Enter');
    await p.type('20 GOTO 10\nRUN\n');
  },
  'gw:3': async (p) => { await screenKey(p, 'c', { ctrl: true }); },
};
// Tour steps whose wait condition should not already be true before the learner acts

const tourPage = (p, id) => p.fn((id) => RC.Tours.TOURS[id].steps.map((s) => ({ title: s.title, text: s.text, sel: s.sel || null, wait: !!s.wait, waitText: s.waitText || null })), id);

async function tourStepTest(p, li, si) {
  const L = LESSONS[li];
  const ok = await p.ev(`(() => { const st = RC.Tours.active; return !!st && st.tour.lessonTitle === ${JSON.stringify(header(li))} && st.i === ${si}; })()`);
  if (!ok) {
    await stopIfActive(p);
    await p.fn(async (li, si) => { RC.Lessons.start(RC.app, li); const st = RC.Tours.active; for (let k = 1; k <= si; k++) { st.i = k; await RC.Tours.show(st); } }, li, si);
  }
  const steps = await tourPage(p, L.tour);
  const s = steps[si];
  await waitStep(p, si, s.title);
  const info = await tourInfo(p);
  p.assert.equal(info.header, header(li));
  p.assert.equal(info.title, s.title);
  p.assert.equal(info.count, `${si + 1} / ${steps.length}`);
  p.assert.equal(info.body, await htmlText(p, s.text));
  let spotErr = null;
  if (s.sel) { try { await assertSpotlight(p, s.sel); } catch (e) { spotErr = e; } }
  await assertPopInView(p);
  const key = L.tour + ':' + (si + 1);
  const isLast = si === steps.length - 1;
  if (L.tour === 'first' && si === 0) p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\FIRST.BAS');
  if (L.tour === 'debug' && si === 0) p.assert.equal(await p.activePath(), 'C:\\SAMPLES\\FACTORL.BAS');
  if (L.tour === 'graphics' && si === 0) { p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\DRAWING.BAS'); p.assert.match(await p.code(), /SCREEN 12/); }
  if (L.tour === 'debug' && si === 3) p.assert.equal(await p.ev('RC.app.panels.active'), 'stack');
  if (L.tour === 'debug' && si === 4) p.assert.equal(await p.ev('RC.app.panels.active'), 'vars');
  if (L.tour === 'debug' && si === 7) p.assert.equal(await p.ev('RC.app.panels.active'), 'immediate');
  if (L.tour === 'gw' && si === 1) p.assert.equal(await p.ev('!!(RC.app.console && RC.app.console.active)'), true, 'console switched on');
  if (s.wait) {
    p.assert.equal(info.wait, s.waitText);
    p.assert.ok(info.btns.some((b) => b.text === 'Skip step'));
    await sleep(700);
    p.assert.equal((await tourInfo(p)).wait, s.waitText, 'tour step waits for the learner');
    await TOUR_SOL[key](p);
    await p.wait("(() => { const w = document.querySelector('.tour-pop .tour-wait'); return w && w.innerText === '✓ Done!'; })() || (RC.Tours.active && RC.Tours.active.i > " + si + ')', 10000);
    if (!isLast) await waitStep(p, si + 1, steps[si + 1].title, 4000);
    if (spotErr) throw spotErr;
    return;
  }
  p.assert.equal(info.wait, null);
  if (!isLast) {
    await tourButton(p, 'Next');
    await waitStep(p, si + 1, steps[si + 1].title);
  }
  if (spotErr) throw spotErr;
}

/** On failure: add the output screen to the message and leave no dirty docs (so the page can reload) */
const guard = (fn) => async (p) => {
  try { await fn(p); } catch (e) {
    try {
      const scr = (await p.screen()).split('\n').filter((l) => l.trim()).slice(-8).join(' | ');
      e.message += '\n    [screen] ' + scr + '\n    [state] ' + (await p.state());
      await p.ev('RC.app.stop(); RC.app.docs.forEach((d) => { d.dirty = false; }); document.querySelectorAll(".modal-back").forEach((m) => m.remove())');
    } catch (e2) { /* ignore */ }
    throw e;
  }
};

// ---- registration -----------------------------------------------------------------------------------
/** Register tests for lessons [from, to) (0-based indexes) */
export function registerLessons(t, from, to) {
  for (let li = from; li < to; li++) {
    const L = LESSONS[li];
    const n = li + 1;
    const via = li % 2 ? 'menu' : 'toolbar';
    t.test(`lesson ${n} (${L.id}): starts from the Learn dialog (${via === 'menu' ? 'Help menu' : 'toolbar'}) with its header`, async (p) => {
      await startFromDialog(p, li, via);
      await p.wait('!!RC.Tours.active', 4000);
      const PL = await pageLesson(p, li);
      const first = PL.tour ? (await tourPage(p, PL.tour))[0] : PL.steps[0];
      await waitStep(p, 0, first.title);
      const info = await tourInfo(p);
      p.assert.equal(info.header, `Lesson ${n} · ${PL.unit}`);
      p.assert.equal(info.title, first.title);
      p.assert.equal(info.count, `1 / ${PL.tour ? (await tourPage(p, PL.tour)).length : PL.steps.length}`);
      p.assert.equal(await p.ev("RC.UI.storage.get('lessonLast', null)"), PL.id, 'lessonLast remembers the lesson');
      if (!PL.tour) {
        p.assert.equal(fileFor(PL), 'C:\\LESSONS\\' + PL.id.toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 8) + '.BAS');
        if (PL.steps[0].code !== undefined) {
          p.assert.equal(await p.activePath(), fileFor(PL));
          p.assert.equal(await p.code(), PL.steps[0].code);
          p.assert.ok(await p.ev(`[...document.querySelectorAll('#editorTabs .tab')].some((t) => t.innerText.includes(${JSON.stringify(fileFor(PL).split('\\').pop())}))`), 'practice file has an editor tab');
        }
      }
    }, { timeout: 20000 });
    if (L.tour) {
      const steps = TOURS[L.tour].steps;
      steps.forEach((s, si) => {
        t.test(`lesson ${n} (${L.id}) tour step ${si + 1}/${steps.length}: ${s.title}`, guard((p) => tourStepTest(p, li, si)), { timeout: 40000 });
      });
    } else {
      L.steps.forEach((s, si) => {
        const kind = s.quiz ? 'quiz' : s.check ? 'check ' + checkKind(s.check) : 'info';
        if (GUTTER_STEPS.has(L.id + ':' + (si + 1))) {
          t.test(`lesson ${n} (${L.id}) step ${si + 1}/${L.steps.length}: spotlight surrounds the visible editor gutter`, guard(async (p) => {
            await ensureStep(p, li, si);
            p.assert.equal(s.sel, '.ed-gutter');
            p.assert.ok(await p.ev("[...document.querySelectorAll('#editorArea .ed-gutter')].some((e) => e.getClientRects().length && e.getBoundingClientRect().width > 0)"), 'an editor gutter is visible');
            p.assert.ok(await p.ev("document.querySelectorAll('#editorArea .ed-gutter').length > 1"), 'several editors are open (the hidden ones keep their gutters)');
            await assertSpotlight(p, s.sel);
          }), { timeout: 30000 });
        }
        t.test(`lesson ${n} (${L.id}) step ${si + 1}/${L.steps.length} [${kind}]: ${s.title}`, guard((p) => stepTest(p, li, si)), { timeout: 60000 });
      });
    }
    t.test(`lesson ${n} (${L.id}): Complete marks it done and ${n < LESSONS.length ? 'starts lesson ' + (n + 1) : 'shows the finish toast'}`, async (p) => {
      const PL = await pageLesson(p, li);
      const nSteps = PL.tour ? (await tourPage(p, PL.tour)).length : PL.steps.length;
      const last = nSteps - 1;
      const there = await p.ev(`(() => { const st = RC.Tours.active; return !!st && st.tour.lessonTitle === ${JSON.stringify(header(li))} && st.i === ${last}; })()`);
      if (!there) {
        await stopIfActive(p);
        await p.fn(async (li, last) => { RC.Lessons.start(RC.app, li); const st = RC.Tours.active; st.i = last; await RC.Tours.show(st); }, li, last);
        await p.sleep(200);
      }
      const ls = PL.tour ? null : PL.steps[last];
      if (ls && ls.quiz) {
        const fb = await quizFeedback(p);
        if (!/Correct/.test(fb || '')) await quizOption(p, ls.quiz.answer);
      }
      await stopIfActive(p);
      p.assert.equal(await p.ev("RC.UI.storage.get('lessonsDone', []).includes(" + JSON.stringify(PL.id) + ')'), false, 'not done before Complete');
      const label = n < LESSONS.length ? 'Complete ✓ Next lesson ▶' : 'Complete ✓';
      await tourButton(p, label);
      await p.wait("RC.UI.storage.get('lessonsDone', []).includes(" + JSON.stringify(PL.id) + ')', 3000);
      if (n < LESSONS.length) {
        const NL = await pageLesson(p, li + 1);
        const firstTitle = NL.tour ? (await tourPage(p, NL.tour))[0].title : NL.steps[0].title;
        await p.wait(`RC.Tours.active && RC.Tours.active.tour.lessonTitle === ${JSON.stringify('Lesson ' + (n + 1) + ' · ' + NL.unit)}`, 4000);
        await waitStep(p, 0, firstTitle);
        p.assert.equal(await p.ev("RC.UI.storage.get('lessonLast', null)"), NL.id);
      } else {
        await p.waitToast(/You finished the whole tutorial/);
        p.assert.equal(await p.ev('RC.Tours.active'), null, 'tour closed');
      }
      if (PL.tour === 'gw' && await p.ev('!!(RC.app.console && RC.app.console.active)')) {
        // leave the console as the tour says (SYSTEM)
        await stopIfActive(p);
        await p.ev("document.getElementById('screen').focus()");
        await p.type('SYSTEM\n');
        await p.wait('!RC.app.console.active', 3000);
      }
      if (PL.tour === 'debug') await clearBps(p);
    }, { timeout: 20000 });
  }
}
