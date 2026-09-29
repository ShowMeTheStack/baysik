// "Graphics & Sound", "Files & Sharing" and "Classic GW-BASIC Console" tours, step by step and for real.
import { TOURS, pop, start, btn, gotoStep, waitStep, waitHoleAround, waitHoleCentered, waitPopInside, waitPopCentered, clickScreen } from './70-tours-lib.mjs';

const PHRASES = {
  graphics: [
    /Classic PCs had several graphics modes\. SCREEN picks one/,
    /SCREEN 12 is 640×480 with 16 colors/,
    /Change SCREEN 12 to SCREEN 13/,
    /MANDEL, PLASMA, SPRITES, TURTLE and MUSIC/,
  ],
  files: [
    /Drive C: is a virtual disk saved in your browser/,
    /import files from your computer, mount a real folder as D:/,
    /Sharing packs the current folder into a compressed link/,
    /Files autosave \(Options ▸ Autosave\)\. Ctrl\+S saves/,
  ],
  gw: [
    /you typed numbered lines straight onto the screen/,
    /10 PRINT "HELLO" \(Enter\)[\s\S]*20 GOTO 10 \(Enter\)[\s\S]*RUN \(Enter\)/,
    /An endless loop! Press Ctrl\+C/,
    /Type LIST\. Then move the cursor up onto line 10/,
    /Your numbered program also appears in the editor/,
  ],
};
const DRAWING = 'C:\\MYPROGS\\DRAWING.BAS';
const DRAWING_SRC = "' Graphics demo\nSCREEN 12\nFOR r = 10 TO 200 STEP 10\n    CIRCLE (320, 240), r, r MOD 15 + 1\nNEXT\nLINE (100, 100)-(540, 380), 14, B\nPLAY \"T180 O3 L8 CEG>C\"\n";

async function waitDone(p, ms = 8000) {
  await p.wait("(() => { const w = document.querySelector('.tour-pop .tour-wait'); return w && w.innerText === '✓ Done!'; })()", ms);
}

export default (t) => {
  t.beforeEach(async (p) => {
    await p.closeModals();
    await p.closeMenus();
  });

  // ---- per-step layout for the three tours (nothing has run yet in this page) ------------------------
  for (const id of ['graphics', 'files', 'gw']) {
    const T = TOURS[id];
    const N = T.steps.length;
    T.steps.forEach((step, i) => {
      t.test(`${id} step ${i + 1}/${N} "${step.title}": title, counter, text and buttons`, async (p) => {
        await gotoStep(p, id, i);
        const s = await pop(p);
        p.assert.equal(s.title, step.title);
        p.assert.equal(s.count, `${i + 1} / ${N}`);
        p.assert.match(s.text, PHRASES[id][i]);
        p.assert.equal(s.buttons[1].disabled, i === 0);
        if (step.wait) {
          p.assert.equal(s.wait, step.wait);
          p.assert.deepEqual(s.labels, ['Close', 'Back', 'Skip step']);
        } else {
          p.assert.equal(s.wait, null);
          p.assert.deepEqual(s.labels, ['Close', 'Back', i === N - 1 ? 'Finish' : 'Next']);
        }
      });
      t.test(`${id} step ${i + 1}/${N} "${step.title}": spotlight ${step.sel ? 'surrounds ' + step.sel : 'is centred'}, popover on screen`, async (p) => {
        await gotoStep(p, id, i);
        if (step.sel) await waitHoleAround(p, step.sel);
        else { await waitHoleCentered(p); await waitPopCentered(p); }
        await waitPopInside(p);
      });
    });
    t.test(`${id} tour: Finish on the last step closes it`, async (p) => {
      await gotoStep(p, id, N - 1);
      await btn(p, 'Finish');
      await p.waitGone('.tour-pop');
      p.assert.equal(await p.exists('.tour-hole'), false);
      p.assert.equal(await p.ev('RC.Tours.active'), null);
    });
  }
  t.test('gw layout tests leave the console on; switch it off for the next tests', async (p) => {
    p.assert.equal(await p.ev('RC.app.console.active'), true);
    await p.ev('RC.app.console.toggle(false)');
    p.assert.equal(await p.ev('RC.app.console.active'), false);
  });

  // ---- graphics -------------------------------------------------------------------------------------
  t.test('graphics step 1 writes the demo into C:\\MYPROGS\\DRAWING.BAS and opens it', async (p) => {
    await start(p, 'graphics');
    await p.wait(`RC.app.active && RC.app.active.path === ${JSON.stringify(DRAWING)}`, 3000);
    p.assert.equal(await p.code(), DRAWING_SRC);
    p.assert.equal(await p.ev(`RC.app.decodeText(RC.app.vfs.readFile(${JSON.stringify(DRAWING)}))`), DRAWING_SRC);
    p.assert.equal(await p.ev('RC.app.active.dirty'), false);
  });

  t.test('graphics step 2: F5 draws circles and a box in SCREEN 12, ✓ Done! and advances', async (p) => {
    await p.menu('Help', 'Tour: Graphics & Sound');
    await waitStep(p, 1, 4);
    await btn(p, 'Next');
    await waitStep(p, 2, 4);
    await p.sleep(700);
    p.assert.equal((await pop(p)).count, '2 / 4', 'waits before the run');
    await p.ev('RC.app.active.editor.focus()');
    await p.key('F5');
    await waitDone(p);
    await waitStep(p, 3, 4, 4000);
    p.assert.equal((await pop(p)).title, 'Try other modes');
    await p.waitState(['ended', 'waiting']);
    p.assert.equal(await p.ev('RC.app.runner.display.mode'), 12);
    p.assert.equal(await p.pixel(330, 240), 11, 'r=10 circle in colour 11');
    p.assert.equal(await p.pixel(100, 240), 14, 'yellow box edge');
    await waitHoleAround(p, '#screenArea');
  }, { fresh: true });

  t.test('graphics step 2: Skip step moves on without running', async (p) => {
    await gotoStep(p, 'graphics', 1);
    await btn(p, 'Skip step');
    await waitStep(p, 3, 4);
    p.assert.equal(await p.state(), 'idle');
  }, { fresh: true });

  t.test('graphics step 2 waits for DRAWING.BAS to run even if an earlier program ended', async (p) => {
    await p.runProgram('PRINT "earlier"');
    await gotoStep(p, 'graphics', 1);
    await p.sleep(1500);
    p.assert.equal((await pop(p)).count, '2 / 4', 'should wait for F5');
  }, { fresh: true });

  // ---- files ------------------------------------------------------------------------------------------
  t.test('files tour does not change the open file or the disk', async (p) => {
    const before = await p.activePath();
    const n = await p.ev("JSON.stringify(RC.app.vfs.list('C:\\\\MYPROGS').map(e => e.name || e))");
    p.assert.match(n, /HELLO\.BAS/);
    await gotoStep(p, 'files', 3);
    p.assert.equal(await p.activePath(), before);
    p.assert.equal(await p.ev("JSON.stringify(RC.app.vfs.list('C:\\\\MYPROGS').map(e => e.name || e))"), n);
  }, { fresh: true });

  t.test('files tour: Back from "Share a project" to "Import and export" keeps the spotlight on the actions', async (p) => {
    await gotoStep(p, 'files', 2);
    await btn(p, 'Back');
    await waitStep(p, 2, 4);
    p.assert.equal((await pop(p)).title, 'Import and export');
    await waitHoleAround(p, '#explorerActions');
  });

  t.test('files tour: the explorer action buttons stay clickable under the spotlight', async (p) => {
    await gotoStep(p, 'files', 1);
    await waitHoleAround(p, '#explorerActions');
    const hit = await p.fn(() => {
      const a = document.getElementById('explorerActions');
      const b = a.querySelector('button') || a.firstElementChild;
      const r = b.getBoundingClientRect();
      return a.contains(document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2));
    });
    p.assert.equal(hit, true);
  });

  // ---- GW-BASIC console ----------------------------------------------------------------------------------
  t.test('gw step 1 does not switch the console on yet', async (p) => {
    await start(p, 'gw');
    p.assert.equal(await p.ev('RC.app.console.active'), false);
  }, { fresh: true });

  t.test('gw step 2 turns the GW-BASIC console on (text mode, soft-key line)', async (p) => {
    await btn(p, 'Next');
    await waitStep(p, 2, 5);
    await p.wait('RC.app.console.active === true', 2000);
    p.assert.equal(await p.ev('RC.app.runner.display.mode'), 0);
    const lines = (await p.screen()).split('\n');
    p.assert.match(lines[lines.length - 1], /LIST.*RUN/, 'function-key line at the bottom');
    p.assert.doesNotMatch(await p.screen(), /B {3}A {3}Y/, 'welcome screen cleared');
  });

  t.test('gw step 2: typing 10 PRINT "HELLO" / 20 GOTO 10 / RUN on the screen shows ✓ Done! and advances', async (p) => {
    await clickScreen(p);
    await p.type('10 PRINT "HELLO"\n20 GOTO 10\n');
    await p.sleep(500);
    p.assert.equal((await pop(p)).count, '2 / 5', 'numbered lines alone do not complete the step');
    await p.type('RUN\n');
    await waitDone(p);
    await waitStep(p, 3, 5, 4000);
    p.assert.equal((await pop(p)).title, 'Break!');
    p.assert.ok(['running', 'waiting'].includes(await p.state()));
    await p.waitScreen(/HELLO\s*\n\s*HELLO/);
  });

  t.test('gw step 3: Ctrl+C on the screen breaks the loop, ✓ Done! and advances', async (p) => {
    p.assert.equal((await pop(p)).wait, 'Waiting for Ctrl+C…');
    await clickScreen(p);
    await p.key('c', { ctrl: true });
    await p.waitState(['paused', 'ended']);
    await waitDone(p);
    await waitStep(p, 4, 5, 4000);
    p.assert.equal((await pop(p)).title, 'LIST and edit');
    await p.waitScreen(/Break/i);
  });

  t.test('gw step 5: the numbered program is shown in the editor under the spotlight', async (p) => {
    await btn(p, 'Next');
    await waitStep(p, 5, 5);
    await waitHoleAround(p, '#editorArea');
    const code = await p.code();
    p.assert.match(code, /10 PRINT "HELLO"/);
    p.assert.match(code, /20 GOTO 10/);
    p.assert.equal((await pop(p)).labels[2], 'Finish');
    await btn(p, 'Finish');
    await p.waitGone('.tour-pop');
    await p.stopProgram();
  });

  t.test('gw step 2: Skip step leaves the console on and moves to "Break!"', async (p) => {
    await gotoStep(p, 'gw', 1);
    await btn(p, 'Skip step');
    await waitStep(p, 3, 5);
    p.assert.equal(await p.ev('RC.app.console.active'), true);
    p.assert.equal((await pop(p)).wait, 'Waiting for Ctrl+C…');
  }, { fresh: true });
};
