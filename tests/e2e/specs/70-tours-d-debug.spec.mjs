// "Debugging" tour: every step, the FACTORL.BAS action, the breakpoint/F5/F8 wait steps done for real.
import { TOURS, pop, start, btn, gotoStep, waitStep, waitHoleAround, waitHoleCentered, waitPopInside, waitPopCentered } from './70-tours-lib.mjs';

const T = TOURS.debug;
const N = T.steps.length;
const FACT = 'C:\\SAMPLES\\FACTORL.BAS';
const PHRASES = [
  /I'll open FACTORL\.BAS, which uses recursion/,
  /Find the line Factorial# = 1 \(marked with <--\)/,
  /Press F5\. The program will run and stop right before that line/,
  /Open the Call Stack tab/,
  /The Variables tab shows the selected frame's locals/,
  /Hover the mouse over a variable name/,
  /Press F8 a few times/,
  /In the Immediate tab type \? n% \* 100/,
  /Press F5 to continue/,
];

const activeTab = (p) => p.ev("(document.querySelector('#bottomTabs .tab.active') || {}).innerText");

async function waitDone(p, ms = 8000) {
  await p.wait("(() => { const w = document.querySelector('.tour-pop .tour-wait'); return w && w.innerText === '✓ Done!'; })()", ms);
}

/** Line index (0-based) in the active editor whose text matches re. */
const lineOf = (p, re) => p.fn((src) => RC.app.active.editor.getValue().split('\n').findIndex((l) => new RegExp(src).test(l)), re.source);

/** Real mouse click in the active editor's gutter on the given line. */
async function clickGutter(p, line) {
  const pt = await p.fn((ln) => {
    const ed = RC.app.active.editor;
    const g = ed.gutter.getBoundingClientRect();
    const m = ed.main.getBoundingClientRect();
    const y = m.top + ln * ed.lineHeight - ed.ta.scrollTop + ed.lineHeight / 2;
    const x = g.left + g.width / 2;
    return { x, y, hit: ed.gutter.contains(document.elementFromPoint(x, y)), inside: y > m.top && y < m.bottom };
  }, line);
  if (!pt.inside || !pt.hit) throw new Error('gutter line not clickable: ' + JSON.stringify(pt));
  await p.clickAt(pt.x, pt.y);
}

const bpLines = (p) => p.ev(`[...(RC.app.breakpoints.get(${JSON.stringify(FACT)}) || new Map()).keys()]`);

export default (t) => {
  t.beforeEach(async (p) => {
    await p.closeModals();
    await p.closeMenus();
  });

  // ---- per-step layout (no program has run; no breakpoints) ----------------------------------------
  T.steps.forEach((step, i) => {
    t.test(`debug step ${i + 1}/${N} "${step.title}": title, counter, text and buttons`, async (p) => {
      await gotoStep(p, 'debug', i);
      const s = await pop(p);
      p.assert.equal(s.title, step.title);
      p.assert.equal(s.count, `${i + 1} / ${N}`);
      p.assert.match(s.text, PHRASES[i]);
      p.assert.equal(s.buttons[1].disabled, i === 0);
      if (step.wait) {
        p.assert.equal(s.wait, step.wait);
        p.assert.deepEqual(s.labels, ['Close', 'Back', 'Skip step']);
      } else {
        p.assert.equal(s.wait, null);
        p.assert.deepEqual(s.labels, ['Close', 'Back', i === N - 1 ? 'Finish' : 'Next']);
      }
    });

    t.test(`debug step ${i + 1}/${N} "${step.title}": spotlight ${step.sel ? 'surrounds ' + step.sel : 'is centred'}, popover on screen`, async (p) => {
      await gotoStep(p, 'debug', i);
      if (/ed-gutter/.test(step.sel || '')) {
        // the gutter of the editor you can see (FACTORL.BAS), not of a hidden editor
        await p.wait(`(() => { const h = document.querySelector('.tour-hole').getBoundingClientRect(); const g = RC.app.active.editor.gutter.getBoundingClientRect();
          return g.width > 0 && Math.abs(h.left - (g.left - 4)) <= 1.5 && Math.abs(h.top - (g.top - 4)) <= 1.5 && Math.abs(h.width - (g.width + 8)) <= 1.5 && Math.abs(h.height - (g.height + 8)) <= 1.5; })()`, 3000);
      } else if (step.sel) await waitHoleAround(p, step.sel);
      else { await waitHoleCentered(p); await waitPopCentered(p); }
      await waitPopInside(p);
    });
  });

  // ---- actions -------------------------------------------------------------------------------------
  t.test('step 1 opens C:\\SAMPLES\\FACTORL.BAS in the editor', async (p) => {
    await start(p, 'debug');
    await p.wait(`RC.app.active && RC.app.active.path === ${JSON.stringify(FACT)}`, 3000);
    p.assert.match(await p.code(), /FUNCTION Factorial# \(n%\)/);
    p.assert.ok((await p.texts('#editorTabs .tab')).some((x) => /FACTORL\.BAS/.test(x)));
  });

  t.test('step 4 "The call stack" switches the bottom panel to Call Stack', async (p) => {
    await p.ev("RC.app.panels.show('immediate')");
    await gotoStep(p, 'debug', 3);
    await p.wait("RC.app.panels.active === 'stack'", 2000);
    p.assert.equal(await activeTab(p), 'Call Stack');
  });

  t.test('step 5 "Variables" switches the bottom panel to Variables', async (p) => {
    await gotoStep(p, 'debug', 4);
    await p.wait("RC.app.panels.active === 'vars'", 2000);
    p.assert.equal(await activeTab(p), 'Variables');
  });

  t.test('step 8 "Immediate window" switches the bottom panel to Immediate', async (p) => {
    await gotoStep(p, 'debug', 7);
    await p.wait("RC.app.panels.active === 'immediate'", 2000);
    p.assert.equal(await activeTab(p), 'Immediate');
  });

  t.test('Back from step 5 to step 4 shows Call Stack again', async (p) => {
    await gotoStep(p, 'debug', 4);
    await p.wait("RC.app.panels.active === 'vars'", 2000);
    await btn(p, 'Back');
    await waitStep(p, 4, N);
    await p.wait("RC.app.panels.active === 'stack'", 2000);
    p.assert.equal((await pop(p)).title, 'The call stack');
  });

  // ---- the real thing ----------------------------------------------------------------------------------
  t.test('step 2: a breakpoint on another line keeps the step waiting', async (p) => {
    await p.menu('Help', 'Tour: Debugging');
    await waitStep(p, 1, N);
    await btn(p, 'Next');
    await waitStep(p, 2, N);
    const wrong = await lineOf(p, /Factorial# = n% \* Factorial#/);
    p.assert.ok(wrong > 0);
    await clickGutter(p, wrong);
    await p.wait(`${JSON.stringify(wrong)} === ([...(RC.app.breakpoints.get(${JSON.stringify(FACT)}) || new Map()).keys()][0])`, 2000);
    await p.sleep(900);
    const s = await pop(p);
    p.assert.equal(s.count, `2 / ${N}`);
    p.assert.equal(s.wait, 'Waiting for the breakpoint…');
    await clickGutter(p, wrong); // remove it again
    await p.wait(`(RC.app.breakpoints.get(${JSON.stringify(FACT)}) || new Map()).size === 0`, 2000);
  }, { fresh: true });

  t.test('step 2: clicking the gutter on "Factorial# = 1" shows ✓ Done! and advances', async (p) => {
    const line = await lineOf(p, /Factorial# = 1\b/);
    await clickGutter(p, line);
    await waitDone(p);
    p.assert.deepEqual(await bpLines(p), [line]);
    await waitStep(p, 3, N, 4000);
    p.assert.equal((await pop(p)).title, 'Run to the breakpoint');
  });

  t.test('step 3: F5 runs FACTORL.BAS to the breakpoint, shows ✓ Done! and opens the call stack', async (p) => {
    await p.ev('RC.app.active.editor.focus()');
    await p.key('F5');
    await p.waitState('paused');
    await waitDone(p);
    await waitStep(p, 4, N, 4000);
    p.assert.equal((await pop(p)).title, 'The call stack');
    await p.wait("RC.app.panels.active === 'stack'", 2000);
    p.assert.match(await p.panelText(), /Factorial/);
    const line = await lineOf(p, /Factorial# = 1\b/);
    p.assert.equal(await p.ev('RC.app.active.editor.marks.exec'), line, 'paused on the breakpoint line');
  });

  t.test('step 5: the Variables tab shows the paused frame\'s n%', async (p) => {
    await btn(p, 'Next');
    await waitStep(p, 5, N);
    await p.wait("RC.app.panels.active === 'vars'", 2000);
    p.assert.match(await p.panelText(), /n%/i);
    await waitHoleAround(p, '#bottom');
  });

  t.test('step 7: pressing F8 a few times steps, shows ✓ Done! and advances', async (p) => {
    await btn(p, 'Next');
    await waitStep(p, 6, N);
    await btn(p, 'Next');
    await waitStep(p, 7, N);
    p.assert.equal((await pop(p)).wait, 'Waiting for a step…');
    for (let k = 0; k < 8; k++) {
      if ((await pop(p)).count !== `7 / ${N}` || (await pop(p)).wait === '✓ Done!') break;
      await p.key('F8');
      await p.wait("RC.app.runner.state === 'paused'", 3000);
      await p.sleep(150);
    }
    await waitDone(p).catch(() => {});
    await waitStep(p, 8, N, 4000);
    p.assert.equal(await p.ev('RC.app.runner.vm.pauseReason'), 'step');
    p.assert.equal((await pop(p)).title, 'Immediate window');
    await p.wait("RC.app.panels.active === 'immediate'", 2000);
  });

  t.test('step 9: F5 continues and the program stops at the breakpoint again', async (p) => {
    await btn(p, 'Next');
    await waitStep(p, 9, N);
    const s = await pop(p);
    p.assert.equal(s.title, 'Continue');
    p.assert.equal(s.labels[2], 'Finish');
    const line = await lineOf(p, /Factorial# = 1\b/);
    await p.ev('RC.app.active.editor.focus()');
    await p.key('F5');
    await p.wait(`RC.app.runner.state === 'paused' && RC.app.runner.vm.pauseReason !== 'step' && RC.app.active.editor.marks.exec === ${line}`, 5000);
    p.assert.equal((await pop(p)).count, `9 / ${N}`, 'last step has no wait and stays');
  });

  t.test('Finish ends the debugging tour; the program stays paused', async (p) => {
    await btn(p, 'Finish');
    await p.waitGone('.tour-pop');
    p.assert.equal(await p.exists('.tour-hole'), false);
    p.assert.equal(await p.state(), 'paused');
    await p.stopProgram();
  });

  t.test('step 2 also completes when the breakpoint is set with F9 on that line', async (p) => {
    await gotoStep(p, 'debug', 1);
    const line = await lineOf(p, /Factorial# = 1\b/);
    await p.fn((ln) => { const ed = RC.app.active.editor; ed.focus(); ed.setCursor(ln, 4); }, line);
    await p.key('F9');
    await waitDone(p);
    await waitStep(p, 3, N, 4000);
  }, { fresh: true });

  t.test('Skip step on "Run to the breakpoint" moves on without running', async (p) => {
    await gotoStep(p, 'debug', 2);
    await btn(p, 'Skip step');
    await waitStep(p, 4, N);
    p.assert.equal(await p.state(), 'idle');
  }, { fresh: true });

  t.test('Close during "Step" (waiting) removes the overlay and stops watching', async (p) => {
    await gotoStep(p, 'debug', 6);
    await btn(p, 'Close');
    await p.waitGone('.tour-pop');
    p.assert.equal(await p.exists('.tour-hole'), false);
    await p.sleep(400);
    p.assert.equal(await p.ev('RC.Tours.active'), null);
  });
};
