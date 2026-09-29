// Tours in general: replacing a running tour, window resizes, and tours at phone sizes.
import { TOURS, pop, start, btn, gotoStep, waitStep, waitHoleAround, waitHoleCentered, waitPopInside, clickEditorEnd, typeText } from './70-tours-lib.mjs';

const mview = (p) => p.ev("document.getElementById('app').dataset.mview");
const PHONE = { width: 390, height: 844, mobile: true, touch: true };

/** Hole rect fully inside the viewport (with the 4px pad allowed to stick out by 4px). */
async function waitHoleOnScreen(p, ms = 3000) {
  return p.wait(`(() => { const r = document.querySelector('.tour-hole').getBoundingClientRect();
    return r.width > 8 && r.left >= -4.5 && r.top >= -4.5 && r.right <= innerWidth + 4.5 && r.bottom <= innerHeight + 4.5; })()`, ms);
}

export default (t) => {
  t.beforeEach(async (p) => {
    await p.closeModals();
    await p.closeMenus();
  });

  // ---- replacing a running tour -------------------------------------------------------------------
  t.test('starting a tour from the Tours menu replaces a running one', async (p) => {
    await gotoStep(p, 'welcome', 4);
    await p.click('#tbTour');
    await p.click('.menu-pop .menu-item', 'Tour: Debugging');
    await waitStep(p, 1, 9);
    p.assert.equal(await p.count('.tour-pop'), 1);
    p.assert.equal(await p.count('.tour-hole'), 1);
    p.assert.equal((await pop(p)).title, 'Become a bug detective');
    p.assert.equal(await p.ev('RC.Tours.active.id'), 'debug');
  }, { fresh: true });

  t.test('starting a tour from the Help menu replaces a running one', async (p) => {
    await gotoStep(p, 'files', 2);
    await p.menu('Help', 'Tour: Classic GW-BASIC Console');
    await waitStep(p, 1, 5);
    p.assert.equal(await p.count('.tour-pop'), 1);
    p.assert.equal(await p.count('.tour-hole'), 1);
    p.assert.equal((await pop(p)).title, 'Back to 1985');
    await waitHoleCentered(p);
  });

  t.test('a replaced tour stops waiting: finishing its task later does not move the new tour', async (p) => {
    await gotoStep(p, 'first', 1); // "Say hello" waits for a PRINT line
    await start(p, 'files');
    await clickEditorEnd(p);
    await typeText(p, 'print "x"');
    await p.sleep(1500);
    const s = await pop(p);
    p.assert.equal(s.title, 'Your disk');
    p.assert.equal(s.count, '1 / 4');
  }, { fresh: true });

  t.test('a replaced tour no longer follows window resizes', async (p) => {
    await gotoStep(p, 'welcome', 2); // #tbRun
    await start(p, 'files');          // #explorer
    await p.viewport(1200, 800);
    await waitHoleAround(p, '#explorer');
    await p.sleep(400);
    await waitHoleAround(p, '#explorer');
    p.assert.equal(await p.count('.tour-hole'), 1);
    await p.viewport(1400, 900);
  });

  t.test('the welcome dialog\'s "Show me around" replaces a tour started meanwhile', async (p) => {
    await p.waitModal();
    await p.ev("RC.Tours.start(RC.app, 'files')");
    await p.modalButton('Show me around');
    await waitStep(p, 1, 11);
    p.assert.equal(await p.count('.tour-pop'), 1);
    p.assert.equal((await pop(p)).title, 'Welcome to Baysik!');
  }, { fresh: { firstRun: true } });

  // ---- resize --------------------------------------------------------------------------------------
  for (const [idx, sel] of [[2, '#tbRun'], [5, '#editorArea'], [6, '#screenArea'], [7, '#bottom'], [9, '#tbExamples']]) {
    t.test(`window resize repositions the spotlight around ${sel}`, async (p) => {
      await p.viewport(1400, 900);
      await gotoStep(p, 'welcome', idx);
      await waitHoleAround(p, sel);
      const before = await p.rect('.tour-hole');
      await p.viewport(1000, 700);
      await waitHoleAround(p, sel);
      await waitPopInside(p);
      const after = await p.rect('.tour-hole');
      p.assert.notDeepEqual(after, before, 'the spotlight moved/resized with the layout');
      await p.viewport(1400, 900);
      await waitHoleAround(p, sel);
    });
  }

  t.test('window resize re-centres the spotlight and popover of an untargeted step', async (p) => {
    await start(p, 'welcome');
    await waitHoleCentered(p);
    await p.viewport(900, 640);
    await waitHoleCentered(p);
    const r = await p.rect('.tour-pop');
    p.assert.ok(Math.abs(r.x + r.w / 2 - 450) <= 2, 'popover centred horizontally at 900px');
    await p.viewport(1400, 900);
    await waitHoleCentered(p);
  });

  t.test('shrinking the window keeps the popover inside the viewport on every welcome step', async (p) => {
    await p.viewport(900, 600);
    await start(p, 'welcome');
    for (let i = 0; i < 11; i++) {
      await waitPopInside(p);
      if (i < 10) { await btn(p, 'Next'); await waitStep(p, i + 2, 11); }
    }
    await p.viewport(1400, 900);
  });

  // ---- phone viewport -----------------------------------------------------------------------------------
  const MOBILE_STEPS = [
    ['welcome', 5, '#editorArea', 'editor'],
    ['welcome', 6, '#screenArea', 'screen'],
    ['welcome', 7, '#bottom', 'debug'],
    ['welcome', 8, '#explorer', 'files'],
    ['first', 3, '#screenArea', 'screen'],
    ['debug', 3, '#bottom', 'debug'],
    ['gw', 1, '#screenArea', 'screen'],
    ['files', 0, '#explorer', 'files'],
  ];
  for (const [id, idx, sel, view] of MOBILE_STEPS) {
    t.test(`phone: ${id} step ${idx + 1} "${TOURS[id].steps[idx].title}" switches to the ${view} view and spotlights ${sel}`, async (p) => {
      await p.ev("RC.app.setMobileView(" + JSON.stringify(view === 'editor' ? 'screen' : 'editor') + ")");
      await gotoStep(p, id, idx);
      await p.wait(`document.getElementById('app').dataset.mview === ${JSON.stringify(view)}`, 2000);
      p.assert.equal(await p.ev(`document.querySelector('#mobileTabs button.active').dataset.view`), view);
      p.assert.equal(await p.visible(sel), true);
      await waitHoleAround(p, sel);
      await waitPopInside(p);
    }, { fresh: PHONE });
  }

  t.test('phone: debug "Set a breakpoint" (gutter step) switches to the editor view', async (p) => {
    await p.ev("RC.app.setMobileView('screen')");
    await gotoStep(p, 'debug', 1);
    await p.wait("document.getElementById('app').dataset.mview === 'editor'", 2000);
    p.assert.equal(await p.visible('#editorArea'), true);
  }, { fresh: PHONE });

  t.test('phone: Back to "The editor" switches from the screen view back to the editor view', async (p) => {
    await gotoStep(p, 'welcome', 6);
    await p.wait("document.getElementById('app').dataset.mview === 'screen'", 2000);
    await btn(p, 'Back');
    await waitStep(p, 6, 11);
    await p.wait("document.getElementById('app').dataset.mview === 'editor'", 2000);
    await waitHoleAround(p, '#editorArea');
  }, { fresh: PHONE });

  t.test('phone: a toolbar step leaves the current mobile view alone', async (p) => {
    await p.ev("RC.app.setMobileView('debug')");
    await gotoStep(p, 'welcome', 2); // "Run your program" (#tbRun)
    await p.sleep(300);
    p.assert.equal(await mview(p), 'debug');
    await waitHoleAround(p, '#tbRun');
  }, { fresh: PHONE });

  t.test('phone: popover is narrower than the screen and inside it on every welcome step', async (p) => {
    await start(p, 'welcome');
    for (let i = 0; i < 11; i++) {
      await waitPopInside(p);
      const r = await p.rect('.tour-pop');
      p.assert.ok(r.w <= 390 - 24 + 0.5, 'width ' + r.w);
      if (i < 10) { await btn(p, 'Next'); await waitStep(p, i + 2, 11); }
    }
    p.assert.equal(await p.noHScroll(), true);
  }, { fresh: PHONE });

  t.test('phone: Next and Back respond to touch taps', async (p) => {
    await start(p, 'welcome');
    await p.tap('.tour-pop .tour-foot button', 'Next');
    await waitStep(p, 2, 11);
    await p.tap('.tour-pop .tour-foot button', 'Next');
    await waitStep(p, 3, 11);
    await p.tap('.tour-pop .tour-foot button', 'Back');
    await waitStep(p, 2, 11);
    await p.tap('.tour-pop .tour-foot button', 'Close');
    await p.waitGone('.tour-pop');
  }, { fresh: PHONE });

  t.test('phone: rotating to landscape keeps the spotlight on the target and the popover on screen', async (p) => {
    await gotoStep(p, 'welcome', 6);
    await waitHoleAround(p, '#screenArea');
    await p.viewport(844, 390, { mobile: true, touch: true });
    await waitHoleAround(p, '#screenArea');
    await waitPopInside(p);
  }, { fresh: PHONE });

  for (const [idx, sel] of [[4, '#tbSpeed'], [9, '#tbExamples'], [10, '#tbTour']]) {
    t.test(`phone: welcome step ${idx + 1} "${TOURS.welcome.steps[idx].title}" spotlights ${sel} on screen`, async (p) => {
      await gotoStep(p, 'welcome', idx);
      await waitHoleAround(p, sel);
      await waitHoleOnScreen(p);
    }, { fresh: PHONE });
  }
};
