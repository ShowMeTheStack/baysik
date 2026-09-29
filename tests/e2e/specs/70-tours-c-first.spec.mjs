// "Your First Program" tour: every step, its FIRST.BAS action, and each wait step done for real.
import { TOURS, pop, isOpen, start, btn, gotoStep, waitStep, waitHoleAround, waitHoleCentered, waitPopInside, waitPopCentered, clickEditorEnd, clickScreen, typeText } from './70-tours-lib.mjs';

const T = TOURS.first;
const N = T.steps.length;
const FIRST = 'C:\\MYPROGS\\FIRST.BAS';
const PHRASES = [
  /create a new empty file called FIRST\.BAS/,
  /PRINT "Hello, world!"/,
  /Now press F5 or click Run/,
  /There's your message on the output screen/,
  /INPUT "What is your name"; n\$[\s\S]*PRINT "Hi, "; n\$/,
  /type your name and press Enter/,
  /FOR i = 1 TO 10[\s\S]*NEXT i/,
  /add COLOR 14 before PRINT/,
];

/** Wait for the current wait step to show "✓ Done!" with the primary button relabelled. */
async function waitDone(p, ms = 8000) {
  await p.wait("(() => { const w = document.querySelector('.tour-pop .tour-wait'); return w && w.innerText === '✓ Done!'; })()", ms);
}

/** Advance from step idx to idx+1 by clicking the primary button ("Next" / "Skip step"). */
async function primary(p) { await p.click('.tour-pop .tour-foot button.primary'); }

export default (t) => {
  // no Tours.stop() here: the walkthrough tests continue one running tour across tests
  t.beforeEach(async (p) => {
    await p.closeModals();
    await p.closeMenus();
  });

  // ---- per-step layout (runner is still idle here, so no wait step can complete on its own) ----
  T.steps.forEach((step, i) => {
    t.test(`first step ${i + 1}/${N} "${step.title}": title, counter, text and buttons`, async (p) => {
      await gotoStep(p, 'first', i);
      const s = await pop(p);
      p.assert.equal(s.title, step.title);
      p.assert.equal(s.count, `${i + 1} / ${N}`);
      p.assert.match(s.text, PHRASES[i]);
      p.assert.equal(s.buttons[1].disabled, i === 0, 'Back disabled only on step 1');
      if (step.wait) {
        p.assert.equal(s.wait, step.wait);
        p.assert.deepEqual(s.labels, ['Close', 'Back', 'Skip step']);
      } else {
        p.assert.equal(s.wait, null);
        p.assert.deepEqual(s.labels, ['Close', 'Back', i === N - 1 ? 'Finish' : 'Next']);
      }
    });

    t.test(`first step ${i + 1}/${N} "${step.title}": spotlight ${step.sel ? 'surrounds ' + step.sel : 'is centred'}, popover on screen`, async (p) => {
      await gotoStep(p, 'first', i);
      if (step.sel) await waitHoleAround(p, step.sel);
      else { await waitHoleCentered(p); await waitPopCentered(p); }
      await waitPopInside(p);
    });
  });

  // ---- step 1 action ---------------------------------------------------------------------------
  t.test('step 1 creates C:\\MYPROGS\\FIRST.BAS, empty, and makes it the active file', async (p) => {
    await start(p, 'first');
    await p.wait(`RC.app.active && RC.app.active.path === ${JSON.stringify(FIRST)}`, 3000);
    p.assert.equal(await p.ev(`RC.app.vfs.exists(${JSON.stringify(FIRST)})`), true);
    p.assert.equal(await p.code(), '');
    p.assert.ok((await p.texts('#editorTabs .tab')).some((x) => /FIRST\.BAS/.test(x)), 'FIRST.BAS tab shown');
  });

  t.test('step 1 starts from an empty FIRST.BAS even if it had a program in it', async (p) => {
    await p.newFile(FIRST, 'PRINT "OLD STUFF"');
    p.assert.match(await p.code(), /OLD STUFF/);
    await start(p, 'first');
    await p.wait(`RC.app.active.path === ${JSON.stringify(FIRST)} && RC.app.active.editor.getValue() === ''`, 3000);
    p.assert.equal(await p.ev(`RC.app.decodeText(RC.app.vfs.readFile(${JSON.stringify(FIRST)}))`), '');
    p.assert.equal(await p.ev('RC.app.active.dirty'), false);
  });

  // ---- waiting behaviour without the real action -------------------------------------------------
  t.test('step 2 keeps waiting for a non-matching line (PRINT without a string)', async (p) => {
    await gotoStep(p, 'first', 1);
    await clickEditorEnd(p);
    await typeText(p, 'print 5');
    await p.sleep(1000);
    const s = await pop(p);
    p.assert.equal(s.count, `2 / ${N}`);
    p.assert.equal(s.wait, 'Waiting for a PRINT line…');
    p.assert.equal(s.labels[2], 'Skip step');
  });

  t.test('Skip step on step 2 advances without typing anything', async (p) => {
    await gotoStep(p, 'first', 1);
    await btn(p, 'Skip step');
    await waitStep(p, 3, N);
    p.assert.equal((await pop(p)).title, 'Run it!');
    p.assert.equal(await p.code(), '');
  });

  t.test('Back from a waiting step returns to step 1 and re-entering re-arms the wait', async (p) => {
    await gotoStep(p, 'first', 1);
    await btn(p, 'Back');
    await waitStep(p, 1, N);
    p.assert.equal((await pop(p)).wait, null);
    await btn(p, 'Next');
    await waitStep(p, 2, N);
    const s = await pop(p);
    p.assert.equal(s.wait, 'Waiting for a PRINT line…');
    p.assert.equal(s.labels[2], 'Skip step');
  });

  t.test('closing during a wait step stops watching: typing the answer later does nothing', async (p) => {
    await gotoStep(p, 'first', 1);
    await btn(p, 'Close');
    await p.waitGone('.tour-pop');
    await p.ev('RC.app.active.editor.focus()');
    await typeText(p, 'print "late"');
    await p.sleep(1200);
    p.assert.equal(await isOpen(p), false);
    p.assert.equal(await p.ev('RC.Tours.active'), null);
  });

  // ---- the real thing, from a fresh page ------------------------------------------------------------
  t.test('step 2: typing PRINT "Hello, world!" in the editor shows ✓ Done! and auto-advances', async (p) => {
    await p.click('#tbTour');
    await p.click('.menu-pop .menu-item', 'Tour: Your First Program');
    await waitStep(p, 1, N);
    await btn(p, 'Next');
    await waitStep(p, 2, N);
    await clickEditorEnd(p);
    await typeText(p, 'print "Hello, world!"');
    await waitDone(p);
    p.assert.equal((await pop(p)).labels[2], 'Next', 'Skip step becomes Next once done');
    await waitStep(p, 3, N, 4000);
    p.assert.equal((await pop(p)).title, 'Run it!');
    p.assert.match(await p.code(), /print "Hello, world!"/i);
  }, { fresh: true });

  t.test('step 3: pressing F5 runs FIRST.BAS, shows ✓ Done! and advances to "It works!"', async (p) => {
    p.assert.equal((await pop(p)).count, `3 / ${N}`);
    await p.ev('RC.app.active.editor.focus()');
    await p.key('F5');
    await waitDone(p);
    await waitStep(p, 4, N, 4000);
    p.assert.equal((await pop(p)).title, 'It works!');
    await p.waitScreen(/Hello, world!/);
    await waitHoleAround(p, '#screenArea');
  });

  t.test('step 5: typing the INPUT line in the editor completes "Ask a question"', async (p) => {
    await btn(p, 'Next');
    await waitStep(p, 5, N);
    p.assert.equal((await pop(p)).wait, 'Waiting for an INPUT line…');
    await clickEditorEnd(p);
    // write the PRINT line first so the step only completes when the whole INPUT line is in
    await typeText(p, '\nPRINT "Hi, "; n$');
    await p.key('Home');
    await p.key('Enter');
    await p.key('ArrowUp');
    await typeText(p, 'INPUT "What is your name"; n$');
    await waitDone(p);
    await waitStep(p, 6, N, 4000);
    p.assert.equal((await pop(p)).title, 'Run and answer');
    const code = await p.code();
    p.assert.match(code, /INPUT "What is your name"; n\$/i);
    p.assert.match(code, /PRINT "Hi, "; n\$/i);
  });

  t.test('step 6: running and answering the INPUT completes "Run and answer"', async (p) => {
    await gotoStep(p, 'first', 5); // skips 2, 3, 5: runner is idle, editor empty
    p.assert.equal((await pop(p)).wait, 'Waiting for the program to finish…');
    await clickEditorEnd(p);
    await typeText(p, 'input "What is your name"; n$\nprint "Hi, "; n$\n');
    await p.sleep(700);
    p.assert.equal((await pop(p)).count, `6 / ${N}`, 'still waiting before the run');
    await p.key('F5');
    await p.waitState('waiting');
    await p.waitScreen(/What is your name\?/);
    await clickScreen(p);
    await typeText(p, 'Ada\n');
    await p.waitScreen(/Hi, Ada/);
    await waitDone(p);
    await waitStep(p, 7, N, 4000);
    p.assert.equal((await pop(p)).title, 'Loops');
  }, { fresh: true });

  t.test('step 7: typing and running a FOR…NEXT loop completes "Loops"', async (p) => {
    await gotoStep(p, 'first', 6);
    p.assert.equal((await pop(p)).wait, 'Waiting for a FOR…NEXT loop to run…');
    await clickEditorEnd(p);
    await typeText(p, 'for i = 1 to 10\nprint i; "Hi!"\nnext i\n');
    await p.sleep(700);
    p.assert.equal((await pop(p)).count, `7 / ${N}`, 'still waiting before the run');
    await p.key('F5');
    await waitDone(p);
    await waitStep(p, 8, N, 4000);
    p.assert.match(await p.screen(), /10 Hi!/);
    const s = await pop(p);
    p.assert.equal(s.title, 'You are a programmer!');
    p.assert.equal(s.labels[2], 'Finish');
  }, { fresh: true });

  t.test('Finish on "You are a programmer!" ends the tour and keeps FIRST.BAS open', async (p) => {
    await btn(p, 'Finish');
    await p.waitGone('.tour-pop');
    p.assert.equal(await p.exists('.tour-hole'), false);
    p.assert.equal(await p.activePath(), FIRST);
    p.assert.match(await p.code(), /NEXT i/i);
  });

  t.test('Skip step works on every wait step of the tour', async (p) => {
    await start(p, 'first');
    const seen = [];
    for (let i = 0; i < N - 1; i++) {
      const s = await pop(p);
      if (T.steps[i].wait) { seen.push(s.title); await btn(p, 'Skip step'); } else await btn(p, 'Next');
      await waitStep(p, i + 2, N);
    }
    p.assert.deepEqual(seen, ['Say hello', 'Run it!', 'Ask a question', 'Run and answer', 'Loops']);
  }, { fresh: true });

  // ---- bugs ---------------------------------------------------------------------------------------
  t.test('step 3 "Run it!" waits for F5 even if an earlier program has already ended', async (p) => {
    await p.runProgram('PRINT "earlier"');
    await gotoStep(p, 'first', 1);
    await btn(p, 'Skip step');
    await waitStep(p, 3, N);
    await p.sleep(1500);
    p.assert.equal((await pop(p)).count, `3 / ${N}`, 'should still wait for the learner to run FIRST.BAS');
  }, { fresh: true });

  t.test('step 6 "Run and answer" waits for a new run instead of completing at once', async (p) => {
    await p.runProgram('PRINT "earlier"');
    await gotoStep(p, 'first', 4);
    await clickEditorEnd(p);
    await typeText(p, 'input "What is your name"; n$');
    await waitStep(p, 6, N, 4000);
    await p.sleep(1500);
    p.assert.equal((await pop(p)).count, `6 / ${N}`, 'should wait until the INPUT program is run and answered');
  }, { fresh: true });

  t.test('step 7 "Loops" waits for the loop to run, not just for NEXT to be typed', async (p) => {
    await p.runProgram('PRINT "earlier"');
    await gotoStep(p, 'first', 6);
    await clickEditorEnd(p);
    await typeText(p, 'for i = 1 to 3\nnext i');
    await p.sleep(1500);
    p.assert.equal((await pop(p)).count, `7 / ${N}`, 'should wait until the loop is run');
  }, { fresh: true });

  t.test('finishing a wait step does not steal focus from the editor while typing', async (p) => {
    await gotoStep(p, 'first', 4);
    await clickEditorEnd(p);
    await typeText(p, 'input "What is your name"; n$');
    await p.sleep(500); // a natural pause before pressing Enter for the next line
    p.assert.equal(await p.focusedId(), 'ed-ta', 'editor keeps keyboard focus when the step completes');
    await typeText(p, '\nprint "Hi, "; n$');
    p.assert.match(await p.code(), /print "Hi, "; n\$/i, 'the second line reaches the editor');
  }, { fresh: true });
};
