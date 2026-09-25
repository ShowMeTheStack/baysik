// Touch devices: on-screen keypad, soft keyboard bridge, tap-to-inspect while paused.
import { box, touchHold, touchAt, hasAppClass, mview } from './95-responsive-helpers.mjs';

const PHONE_T = { width: 390, height: 844, mobile: true, touch: true };
const LAND_T = { width: 844, height: 390, mobile: true, touch: true };

const KEYPROG = [
  'PRINT "READY"',
  'DO',
  '  K$ = INKEY$',
  '  IF K$ <> "" THEN',
  '    IF LEN(K$) = 2 THEN PRINT "EXT"; ASC(MID$(K$, 2, 1)) ELSE PRINT "KEY"; ASC(K$)',
  '  END IF',
  'LOOP',
].join('\n');

async function ensureVp(p, o) {
  const ok = await p.ev(`innerWidth === ${o.width} && innerHeight === ${o.height} && document.getElementById('app').classList.contains('touch') === ${!!o.touch}`);
  if (!ok) await p.fresh(o);
}
async function startKeys(p) {
  if (['running', 'waiting', 'paused'].includes(await p.state())) await p.stopProgram();
  await p.runProgram(KEYPROG, { wait: false });
  await p.waitScreen(/READY/);
  await p.wait("getComputedStyle(document.getElementById('keypad')).display === 'flex'", 3000);
}
const countOf = async (p, re) => ((await p.screen()).match(new RegExp(re.source, 'g')) || []).length;
const kp = (label) => `#keypad button[aria-label="${label}"]`;

export default (t) => {
  t.test('touch device: the app is flagged as touch and the keypad is hidden while idle', async (p) => {
    p.assert.ok(await hasAppClass(p, 'touch'));
    p.assert.equal(await p.visible('#keypad'), false);
    p.assert.equal(await p.ev("getComputedStyle(document.getElementById('keypad')).display"), 'none');
  }, { fresh: PHONE_T });

  t.test('touch device: the keypad appears under the screen while a program runs', async (p) => {
    await ensureVp(p, PHONE_T);
    await startKeys(p);
    p.assert.equal(await mview(p), 'screen');
    p.assert.ok(await p.visible('#keypad'));
    const k = await box(p, '#keypad'), w = await box(p, '#screenWrap');
    p.assert.ok(k.y >= w.bottom - 1, 'keypad below the screen in portrait');
    p.assert.ok(k.right <= 391 && k.x >= -1);
    p.assert.equal(await p.count('#keypad button'), 9);
  });

  for (const [label, scan] of [['Up', 72], ['Left', 75], ['Down', 80], ['Right', 77]]) {
    t.test(`keypad ${label} arrow delivers CHR$(0)+CHR$(${scan}) to INKEY$`, async (p) => {
      await ensureVp(p, PHONE_T);
      await startKeys(p);
      await p.tap(kp(label));
      await p.waitScreen(new RegExp('EXT ' + scan));
      p.assert.equal(await countOf(p, /KEY\s+\d+/), 0, 'no plain key for an arrow');
    });
  }

  for (const [label, code] of [['Space', 32], ['Enter', 13], ['Esc', 27]]) {
    t.test(`keypad ${label} delivers ASCII ${code} to INKEY$`, async (p) => {
      await ensureVp(p, PHONE_T);
      await startKeys(p);
      await p.tap(kp(label));
      await p.waitScreen(new RegExp('KEY ' + code + '\\b'));
      p.assert.equal(await countOf(p, /EXT/), 0);
    });
  }

  t.test('keypad: holding an arrow auto-repeats, releasing stops the repeat', async (p) => {
    await ensureVp(p, PHONE_T);
    await startKeys(p);
    await touchHold(p, kp('Right'), 800);
    await p.sleep(150);
    const n = await countOf(p, /EXT 77/);
    p.assert.ok(n >= 4, `expected several repeats, got ${n}`);
    await p.sleep(400);
    p.assert.equal(await countOf(p, /EXT 77/), n, 'repeat continued after release');
  });

  t.test('keypad: holding Space does not auto-repeat', async (p) => {
    await ensureVp(p, PHONE_T);
    await startKeys(p);
    await touchHold(p, kp('Space'), 800);
    await p.sleep(200);
    p.assert.equal(await countOf(p, /KEY 32/), 1);
  });

  t.test('keypad: a held button shows the pressed state until released', async (p) => {
    await ensureVp(p, PHONE_T);
    await startKeys(p);
    const [x, y] = await p.center(kp('Down'));
    await p.b.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y }] });
    await p.sleep(60);
    p.assert.equal(await p.ev(`document.querySelector('${kp('Down')}').classList.contains('down')`), true);
    p.assert.ok(await p.ev('RC.app.runner.keyboard.down.has(80)'), 'scan code held down');
    await p.b.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
    await p.sleep(60);
    p.assert.equal(await p.ev(`document.querySelector('${kp('Down')}').classList.contains('down')`), false);
    p.assert.equal(await p.ev('RC.app.runner.keyboard.down.has(80)'), false, 'scan code released');
  });

  t.test('keypad: an arrow fires an ON KEY(11) trap', async (p) => {
    await ensureVp(p, PHONE_T);
    await p.stopProgram();
    await p.runProgram('ON KEY(11) GOSUB UpH\nKEY(11) ON\nPRINT "READY"\nDO: LOOP UNTIL DONE%\nPRINT "TRAPPED"\nEND\nUpH: DONE% = 1: RETURN', { wait: false });
    await p.waitScreen(/READY/);
    await p.tap(kp('Up'));
    await p.waitState('ended');
    p.assert.match(await p.screen(), /TRAPPED/);
  });

  t.test('keypad: Break pauses the running program and Run continues it', async (p) => {
    await ensureVp(p, PHONE_T);
    await startKeys(p);
    await p.tap(kp('Break (Ctrl+Break)'));
    await p.waitState('paused');
    p.assert.match(await p.status(), /Break/);
    p.assert.ok(await p.visible('#keypad'), 'keypad stays while paused');
    await p.click('#tbRun');
    await p.waitState(['running', 'waiting']);
    await p.tap(kp('Space'));
    await p.waitScreen(/KEY 32/);
  });

  t.test('keypad hides again when the program ends', async (p) => {
    await ensureVp(p, PHONE_T);
    await p.stopProgram();
    await p.runProgram('PRINT "DONE"');
    p.assert.equal(await p.state(), 'ended');
    await p.wait("getComputedStyle(document.getElementById('keypad')).display === 'none'", 2000);
  });

  t.test('ABC focuses the soft keyboard input', async (p) => {
    await ensureVp(p, PHONE_T);
    await startKeys(p);
    await p.tap(kp('Show keyboard'));
    p.assert.equal(await p.ev("document.activeElement.classList.contains('softkb')"), true);
    p.assert.equal(await p.ev('document.activeElement.value'), '');
  });

  t.test('soft keyboard: typed text and Enter reach INPUT', async (p) => {
    await ensureVp(p, PHONE_T);
    await p.stopProgram();
    await p.runProgram('INPUT "NAME"; N$\nPRINT "HI "; N$; "!"', { wait: false });
    await p.waitScreen(/NAME\?/);
    await p.tap(kp('Show keyboard'));
    await p.insertText('Bob');
    p.assert.equal(await p.ev("document.querySelector('.softkb').value"), '', 'bridge input is cleared after each keystroke');
    await p.key('Enter');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /HI Bob!/);
  });

  t.test('soft keyboard: Backspace edits the INPUT line', async (p) => {
    await ensureVp(p, PHONE_T);
    await p.runProgram('INPUT "AGE"; A$\nPRINT "["; A$; "]"', { wait: false });
    await p.waitScreen(/AGE\?/);
    await p.tap(kp('Show keyboard'));
    await p.insertText('427');
    await p.key('Backspace');
    await p.key('Enter');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /\[42\]/);
  });

  t.test('soft keyboard: characters reach INKEY$ one by one', async (p) => {
    await ensureVp(p, PHONE_T);
    await startKeys(p);
    await p.tap(kp('Show keyboard'));
    await p.insertText('aZ');
    await p.waitScreen(/KEY 97[\s\S]*KEY 90/);
  });

  t.test('tapping the canvas while a program runs focuses the soft keyboard (and keeps it)', async (p) => {
    await ensureVp(p, PHONE_T);
    await startKeys(p);
    await p.ev('document.activeElement && document.activeElement.blur()');
    const s = await box(p, '#screen');
    await touchAt(p, s.x + s.w / 2, s.y + s.h / 2);
    await p.sleep(100);
    p.assert.equal(await p.ev("document.activeElement.classList.contains('softkb')"), true, 'focused: ' + await p.focusedId());
    await p.insertText('x');
    await p.waitScreen(/KEY 120/);
  });

  t.test('tapping the canvas when no program runs does not open the soft keyboard', async (p) => {
    await ensureVp(p, PHONE_T);
    await p.stopProgram();
    await p.runProgram('PRINT "IDLE"');
    await p.ev('document.activeElement && document.activeElement.blur()');
    const s = await box(p, '#screen');
    await touchAt(p, s.x + s.w / 2, s.y + s.h / 2);
    await p.sleep(100);
    p.assert.equal(await p.ev("document.activeElement.classList.contains('softkb')"), false);
  });

  t.test('a mouse click on the canvas gives it focus without the soft keyboard', async (p) => {
    await ensureVp(p, PHONE_T);
    await startKeys(p);
    await p.click('#screen');
    await p.sleep(50);
    p.assert.equal(await p.focusedId(), 'screen');
  });

  t.test('keypad buttons are at least 44x34 px touch targets', async (p) => {
    await ensureVp(p, PHONE_T);
    await startKeys(p);
    const sizes = await p.ev("[...document.querySelectorAll('#keypad button')].map(b => { const r = b.getBoundingClientRect(); return [b.getAttribute('aria-label'), r.width, r.height]; })");
    for (const [l, w, h] of sizes) p.assert.ok(w >= 43.5 && h >= 34, `${l} is ${w}x${h}`);
    await p.stopProgram();
  });

  // ---------------------------------------------------------------- tap a variable while paused
  t.test('tapping a variable in the editor while paused opens the debug callout', async (p) => {
    await ensureVp(p, PHONE_T);
    await p.stopProgram();
    await p.runProgram('SCORE% = 1234\nSTOP\nPRINT SCORE%');
    p.assert.equal(await p.state(), 'paused');
    await p.click('#mobileTabs button', 'Code');
    const pt = await p.ev(`(() => { const e = RC.app.active.editor; const r = e.ta.getBoundingClientRect(); return [r.left + 8 + 2.5 * e.charWidth - e.ta.scrollLeft, r.top + e.lineHeight * 0.5 - e.ta.scrollTop]; })()`);
    await touchAt(p, pt[0], pt[1]);
    await p.wait("!!document.querySelector('.ed-callout')", 3000);
    p.assert.match(await p.text('.ed-callout'), /SCORE%?[\s\S]*1234/);
    p.assert.ok(await p.visible('.ed-callout'));
    const c = await box(p, '.ed-callout');
    p.assert.ok(c.x >= 0 && c.right <= 390 && c.bottom <= 844, 'callout fits on the phone screen');
    await p.sleep(900);
    p.assert.ok(await p.exists('.ed-callout'), 'callout stays open after the tap');
  });

  t.test('tapping elsewhere closes the debug callout', async (p) => {
    await ensureVp(p, PHONE_T);
    if (!(await p.exists('.ed-callout'))) {
      await p.runProgram('SCORE% = 1234\nSTOP\nPRINT SCORE%');
      await p.click('#mobileTabs button', 'Code');
      const pt = await p.ev(`(() => { const e = RC.app.active.editor; const r = e.ta.getBoundingClientRect(); return [r.left + 8 + 2.5 * e.charWidth, r.top + e.lineHeight * 0.5]; })()`);
      await touchAt(p, pt[0], pt[1]);
      await p.wait("!!document.querySelector('.ed-callout')", 3000);
    }
    await p.tap('#statusbar');
    await p.waitGone('.ed-callout', 2000);
  });

  t.test('tapping a keyword while paused does not open a callout', async (p) => {
    await ensureVp(p, PHONE_T);
    if (await p.state() !== 'paused') { await p.runProgram('SCORE% = 1234\nSTOP\nPRINT SCORE%'); await p.click('#mobileTabs button', 'Code'); }
    const pt = await p.ev(`(() => { const e = RC.app.active.editor; const r = e.ta.getBoundingClientRect(); return [r.left + 8 + 1.5 * e.charWidth, r.top + e.lineHeight * 2.5]; })()`);
    await touchAt(p, pt[0], pt[1]);
    await p.sleep(500);
    p.assert.equal(await p.exists('.ed-callout'), false);
    await p.stopProgram();
  });

  t.test('tapping a variable when not paused does not open a callout', async (p) => {
    await ensureVp(p, PHONE_T);
    await p.runProgram('SCORE% = 1234\nPRINT SCORE%');
    await p.click('#mobileTabs button', 'Code');
    const pt = await p.ev(`(() => { const e = RC.app.active.editor; const r = e.ta.getBoundingClientRect(); return [r.left + 8 + 2.5 * e.charWidth, r.top + e.lineHeight * 0.5]; })()`);
    await touchAt(p, pt[0], pt[1]);
    await p.sleep(500);
    p.assert.equal(await p.exists('.ed-callout'), false);
  });

  // ---------------------------------------------------------------- GW console on touch
  t.test('GW-BASIC console on touch: keypad is shown and soft keyboard + Enter run a command', async (p) => {
    await ensureVp(p, PHONE_T);
    await p.ev('RC.app.console.toggle(true)');
    await p.wait("document.getElementById('app').classList.contains('console')", 2000);
    if (await mview(p) !== 'screen') await p.click('#mobileTabs button', 'Screen');
    await p.wait("getComputedStyle(document.getElementById('keypad')).display === 'flex'", 2000);
    await p.tap(kp('Show keyboard'));
    await p.insertText('PRINT 6*7');
    await p.tap(kp('Enter'));
    await p.waitScreen(/^ 42\s*$/m);
    await p.ev('RC.app.console.toggle(false)');
  });

  // ---------------------------------------------------------------- other sizes
  t.test('landscape phone: keypad sits beside the screen, not below it', async (p) => {
    await startKeys(p);
    const k = await box(p, '#keypad'), w = await box(p, '#screenWrap');
    p.assert.ok(k.x >= w.right - 1, `keypad x=${k.x} should be right of screen (right=${w.right})`);
    p.assert.ok(k.y < w.bottom && k.bottom > w.y, 'keypad vertically overlaps the screen');
    p.assert.ok(k.right <= 845 && k.bottom <= 391, 'keypad inside the viewport');
    p.assert.ok(await p.noHScroll());
  }, { fresh: LAND_T });

  t.test('landscape phone: arrow keys from the side keypad reach the program', async (p) => {
    await ensureVp(p, LAND_T);
    await startKeys(p);
    await p.tap(kp('Left'));
    await p.waitScreen(/EXT 75/);
    await p.stopProgram();
  });

  t.test('small phone 320x568: keypad fits without horizontal scrolling', async (p) => {
    await startKeys(p);
    p.assert.ok(await p.noHScroll());
    const all = await p.ev("[...document.querySelectorAll('#keypad button')].every(b => { const r = b.getBoundingClientRect(); return r.left >= 0 && r.right <= innerWidth && r.bottom <= innerHeight; })");
    p.assert.ok(all, 'some keypad buttons are off-screen');
    const { frame } = await (await import('./95-responsive-helpers.mjs')).fittedFrame(p);
    p.assert.ok(frame.w > 200, 'screen still usable above the keypad');
    await p.stopProgram();
  }, { fresh: { width: 320, height: 568, mobile: true, touch: true } });

  t.test('touch tablet 1024x768: keypad shows inside the screen pane while running', async (p) => {
    await startKeys(p);
    const k = await box(p, '#keypad'), sa = await box(p, '#screenArea');
    p.assert.ok(k.x >= sa.x - 1 && k.right <= sa.right + 1 && k.bottom <= sa.bottom + 1);
    await p.tap(kp('Enter'));
    await p.waitScreen(/KEY 13/);
    p.assert.ok(await p.visible('#editorArea'), 'editor still visible beside');
    await p.stopProgram();
  }, { fresh: { width: 1024, height: 768, mobile: true, touch: true } });

  t.test('non-touch desktop: no touch class and no keypad while running', async (p) => {
    p.assert.equal(await hasAppClass(p, 'touch'), false);
    await p.runProgram(KEYPROG, { wait: false });
    await p.waitScreen(/READY/);
    p.assert.ok(await hasAppClass(p, 'running'));
    p.assert.equal(await p.ev("getComputedStyle(document.getElementById('keypad')).display"), 'none');
    await p.stopProgram();
  }, { fresh: { width: 1400, height: 900 } });

  t.test('non-touch phone-sized window: no keypad while running', async (p) => {
    await p.runProgram(KEYPROG, { wait: false });
    await p.waitScreen(/READY/);
    p.assert.equal(await mview(p), 'screen');
    p.assert.equal(await p.ev("getComputedStyle(document.getElementById('keypad')).display"), 'none');
    await p.stopProgram();
  }, { fresh: { width: 390, height: 844 } });
};
