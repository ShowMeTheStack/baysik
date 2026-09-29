// The "Welcome to the IDE" tour, step by step: popover, counter, spotlight, placement and navigation.
import { TOURS, pop, isOpen, start, btn, gotoStep, waitStep, waitHoleAround, waitHoleCentered, waitPopInside, waitPopCentered } from './70-tours-lib.mjs';

const T = TOURS.welcome;
const N = T.steps.length;
const PHRASES = [
  /complete BASIC programming studio in your browser/,
  /Alt\+F for File, Alt\+R for Run/,
  /Press this button or F5 to run the program/,
  /one statement at a time \(F8\)/,
  /Pick a vintage speed here/,
  /Keywords turn UPPERCASE automatically/,
  /F4 makes it full size/,
  /The Immediate window runs single statements instantly/,
  /Examples are in C:\\SAMPLES/,
  /Games, graphics, music, files and recursion demos/,
  /Start another tour here any time\. Have fun!/,
];

const overlaps = (a, b) => a.x < b.right && a.right > b.x && a.y < b.bottom && a.bottom > b.y;

export default (t) => {
  t.beforeEach(async (p) => {
    await p.ev('RC.Tours.stop()');
    await p.closeModals();
    await p.closeMenus();
  });

  T.steps.forEach((step, i) => {
    t.test(`welcome step ${i + 1}/${N} "${step.title}": title, counter, text and buttons`, async (p) => {
      await gotoStep(p, 'welcome', i);
      const s = await pop(p);
      p.assert.equal(s.title, step.title);
      p.assert.equal(s.count, `${i + 1} / ${N}`);
      p.assert.match(s.text, PHRASES[i]);
      p.assert.deepEqual(s.labels, ['Close', 'Back', i === N - 1 ? 'Finish' : 'Next']);
      p.assert.equal(s.buttons[1].disabled, i === 0, 'Back disabled only on step 1');
      p.assert.equal(s.buttons[2].primary, true);
      p.assert.equal(s.wait, null, 'no waiting text on welcome tour steps');
    });

    t.test(`welcome step ${i + 1}/${N} "${step.title}": spotlight ${step.sel ? 'surrounds ' + step.sel : 'is centred'} and popover is on screen`, async (p) => {
      await gotoStep(p, 'welcome', i);
      if (step.sel) {
        await waitHoleAround(p, step.sel);
        await waitPopInside(p);
        const pr = (await pop(p)).rect;
        const tr = await p.rect(step.sel);
        p.assert.ok(!overlaps(pr, tr), `popover ${JSON.stringify(pr)} does not cover ${step.sel} ${JSON.stringify(tr)}`);
      } else {
        await waitHoleCentered(p);
        await waitPopCentered(p);
        await waitPopInside(p);
      }
    });
  });

  t.test('welcome popover is an aria-live dialog and the spotlight dims the rest of the page', async (p) => {
    await start(p, 'welcome');
    p.assert.equal(await p.attr('.tour-pop', 'role'), 'dialog');
    p.assert.equal(await p.attr('.tour-pop', 'aria-live'), 'polite');
    const cs = await p.ev("(() => { const c = getComputedStyle(document.querySelector('.tour-hole')); return { pe: c.pointerEvents, shadow: c.boxShadow, pos: c.position }; })()");
    p.assert.equal(cs.pe, 'none');
    p.assert.equal(cs.pos, 'fixed');
    p.assert.match(cs.shadow, /9999px/);
  });

  t.test('Back on step 1 is disabled and clicking it keeps step 1', async (p) => {
    await start(p, 'welcome');
    await btn(p, 'Back');
    await p.sleep(150);
    const s = await pop(p);
    p.assert.equal(s.count, `1 / ${N}`);
    p.assert.equal(s.title, 'Welcome to Baysik!');
  });

  t.test('Next then Back returns to the previous step and moves the spotlight back', async (p) => {
    await gotoStep(p, 'welcome', 2);
    await waitHoleAround(p, '#tbRun');
    await btn(p, 'Back');
    await waitStep(p, 2, N);
    p.assert.equal((await pop(p)).title, 'Menus');
    await waitHoleAround(p, '#menubar');
    await btn(p, 'Back');
    await waitStep(p, 1, N);
    await waitHoleCentered(p);
  });

  t.test('Next walks through all 11 steps in order with real clicks', async (p) => {
    await start(p, 'welcome');
    const titles = [];
    for (let i = 0; i < N; i++) {
      titles.push((await pop(p)).title);
      if (i < N - 1) { await btn(p, 'Next'); await waitStep(p, i + 2, N); }
    }
    p.assert.deepEqual(titles, T.steps.map((s) => s.title));
  });

  t.test('Finish on the last step removes popover and spotlight', async (p) => {
    await gotoStep(p, 'welcome', N - 1);
    await btn(p, 'Finish');
    await p.waitGone('.tour-pop');
    p.assert.equal(await p.exists('.tour-hole'), false);
    p.assert.equal(await p.ev('RC.Tours.active'), null);
  });

  t.test('Close on step 1 removes the overlay', async (p) => {
    await start(p, 'welcome');
    await btn(p, 'Close');
    await p.waitGone('.tour-pop');
    p.assert.equal(await isOpen(p), false);
    p.assert.equal(await p.ev('RC.Tours.active'), null);
  });

  t.test('Close in the middle (step 6) removes the overlay', async (p) => {
    await gotoStep(p, 'welcome', 5);
    await btn(p, 'Close');
    await p.waitGone('.tour-pop');
    p.assert.equal(await p.exists('.tour-hole'), false);
    p.assert.equal(await p.ev('RC.Tours.active'), null);
  });

  t.test('after Close, a window resize does not bring the spotlight back', async (p) => {
    await gotoStep(p, 'welcome', 3);
    await btn(p, 'Close');
    await p.viewport(1200, 800);
    await p.viewport(1400, 900);
    p.assert.equal(await isOpen(p), false);
  });

  t.test('spotlight does not block the app: clicking the highlighted Run button runs the program', async (p) => {
    await gotoStep(p, 'welcome', 2);
    await waitHoleAround(p, '#tbRun');
    await p.click('#tbRun');
    await p.waitState(['ended', 'error', 'running', 'waiting', 'paused']);
    p.assert.equal((await pop(p)).count, `3 / ${N}`, 'tour stays on its step');
    await p.stopProgram();
  });

  t.test('keys still reach the IDE during the tour: F5 runs the program', async (p) => {
    await p.newFile('C:\\MYPROGS\\TOURKEY.BAS', 'PRINT "TOUR KEY OK"');
    await start(p, 'welcome');
    await p.ev('RC.app.active.editor.focus()');
    await p.key('F5');
    await p.waitScreen(/TOUR KEY OK/);
    p.assert.equal(await isOpen(p), true);
  });

  t.test('starting the welcome tour twice keeps a single popover and spotlight', async (p) => {
    await gotoStep(p, 'welcome', 4);
    await start(p, 'welcome');
    p.assert.equal(await p.count('.tour-pop'), 1);
    p.assert.equal(await p.count('.tour-hole'), 1);
    p.assert.equal((await pop(p)).count, `1 / ${N}`);
  });

  t.test('the welcome tour never changes the open file or runs anything by itself', async (p) => {
    const before = await p.activePath();
    const st = await p.state();
    await gotoStep(p, 'welcome', N - 1);
    p.assert.equal(await p.activePath(), before);
    p.assert.equal(await p.state(), st);
  });
};
