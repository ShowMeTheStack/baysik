// First-run welcome dialog, the welcome screen on the output canvas, and the menus that start tours.
import { TOURS, pop, isOpen, waitStep } from './70-tours-lib.mjs';

const TOUR_LABELS = Object.values(TOURS).map((t) => 'Tour: ' + t.title);

async function modalButtons(p) {
  return p.ev("[...document.querySelectorAll('.modal-back:last-child .modal-foot button')].map(b => ({ text: b.innerText.trim(), primary: b.classList.contains('primary') }))");
}

export default (t) => {
  t.beforeEach(async (p) => {
    await p.ev('RC.Tours.stop()');
    await p.closeMenus();
  });

  // ---- welcome dialog ---------------------------------------------------------------------------
  t.test('welcome dialog appears on a first run with title "Welcome!"', async (p) => {
    p.assert.equal(await p.waitModal(), 'Welcome!');
    const txt = await p.modalText();
    p.assert.match(txt, /BASIC programming studio/);
    p.assert.match(txt, /GW-BASIC and QBasic compatible/);
    p.assert.match(txt, /Would you like a quick tour\?/);
  }, { fresh: { firstRun: true } });

  t.test('welcome dialog has No thanks / Start the tutorial / Show me around (primary)', async (p) => {
    await p.waitModal();
    const b = await modalButtons(p);
    p.assert.deepEqual(b.map((x) => x.text), ['No thanks', 'Start the tutorial', 'Show me around']);
    p.assert.deepEqual(b.filter((x) => x.primary).map((x) => x.text), ['Show me around']);
  }, { fresh: { firstRun: true } });

  t.test('no tour overlay is shown while the welcome dialog is open', async (p) => {
    await p.waitModal();
    p.assert.equal(await isOpen(p), false);
    p.assert.equal(await p.ev('RC.Tours.active'), null);
    p.assert.equal(await p.count('.modal-back'), 1);
  }, { fresh: { firstRun: true } });

  t.test('first run flag is cleared in saved settings once the dialog is offered', async (p) => {
    await p.waitModal();
    p.assert.equal(await p.ev("JSON.parse(localStorage.getItem('baysik.settings')).firstRun"), false);
    p.assert.equal(await p.ev('RC.app.settings.firstRun'), false);
  }, { fresh: { firstRun: true } });

  t.test('welcome dialog does not appear again after a reload', async (p) => {
    await p.waitModal();
    await p.modalButton('No thanks');
    await p.reload();
    await p.sleep(1200);
    p.assert.equal(await p.modalOpen(), false);
    p.assert.equal(await isOpen(p), false);
  }, { fresh: { firstRun: true } });

  t.test('welcome dialog does not appear on a normal (not first) run', async (p) => {
    await p.sleep(1200);
    p.assert.equal(await p.modalOpen(), false);
    p.assert.equal(await isOpen(p), false);
  }, { fresh: true });

  t.test('"No thanks" closes the dialog without starting a tour or lessons', async (p) => {
    await p.waitModal();
    await p.modalButton('No thanks');
    await p.sleep(500);
    p.assert.equal(await p.modalOpen(), false);
    p.assert.equal(await isOpen(p), false);
    p.assert.equal(await p.ev('RC.Tours.active'), null);
  }, { fresh: { firstRun: true } });

  t.test('"Start the tutorial" opens the Learn BASIC dialog', async (p) => {
    await p.waitModal();
    await p.modalButton('Start the tutorial');
    await p.wait("(document.querySelector('.modal-back:last-child .modal-head') || {}).innerText === 'Learn BASIC — Tutorial'", 4000);
    const txt = await p.modalText();
    p.assert.match(txt, /lessons from your very first PRINT/);
    p.assert.equal(await p.count('.modal-back'), 1, 'welcome dialog was replaced by the Learn dialog');
    p.assert.equal(await isOpen(p), false, 'no tour is running');
  }, { fresh: { firstRun: true } });

  t.test('"Show me around" starts the welcome tour at step 1 of 11', async (p) => {
    await p.waitModal();
    await p.modalButton('Show me around');
    await waitStep(p, 1, 11);
    const s = await pop(p);
    p.assert.equal(s.title, 'Welcome to Baysik!');
    p.assert.equal(await p.ev('RC.Tours.active.id'), 'welcome');
    p.assert.equal(await p.modalOpen(), false);
  }, { fresh: { firstRun: true } });

  t.test('"Show me around" is focused, so Enter starts the welcome tour', async (p) => {
    await p.waitModal();
    await p.wait("document.activeElement && document.activeElement.innerText === 'Show me around'", 2000);
    await p.key('Enter');
    await waitStep(p, 1, 11);
    p.assert.equal(await p.modalOpen(), false);
    p.assert.equal((await pop(p)).title, 'Welcome to Baysik!');
  }, { fresh: { firstRun: true } });

  t.test('Escape dismisses the welcome dialog without starting anything', async (p) => {
    await p.waitModal();
    await p.key('Escape');
    await p.sleep(400);
    p.assert.equal(await p.modalOpen(), false);
    p.assert.equal(await isOpen(p), false);
  }, { fresh: { firstRun: true } });

  // ---- welcome screen on the output canvas ------------------------------------------------------
  t.test('welcome screen shows the boxed B A Y S I K banner', async (p) => {
    const lines = (await p.screen()).split('\n');
    p.assert.match(lines[9], /B {3}A {3}Y {3}S {3}I {3}K/);
    p.assert.match(lines[8], /╔═+╗/);
    p.assert.match(lines[10], /╚═+╝/);
    p.assert.match(lines[9], /^\s*║.*║$/);
  }, { fresh: true });

  t.test('welcome screen banner is centred on the 80-column text screen', async (p) => {
    const lines = await p.ev("RC.app.runner.display.textLines().map(s => RC.fromCP437(s, false))");
    p.assert.equal(lines.length, 25);
    p.assert.equal(lines[8].length, 80);
    const lead = lines[8].length - lines[8].trimStart().length;
    p.assert.equal(lead, 16, 'banner starts at column 17');
    p.assert.equal(lines[8].trim().length, 48);
  }, { fresh: true });

  t.test('welcome screen shows the compatibility tagline with • separators', async (p) => {
    const lines = (await p.screen()).split('\n');
    p.assert.match(lines[12], /GW-BASIC \+ QBasic compatible {2}• {2}every screen mode {2}• {2}debugger/);
  }, { fresh: true });

  t.test('welcome screen tagline names compatibility, screen modes and the debugger', async (p) => {
    const line = (await p.screen()).split('\n')[12];
    p.assert.match(line, /GW-BASIC \+ QBasic compatible\s+.*every screen mode\s+.*debugger/);
  }, { fresh: true });

  t.test('welcome screen tells you to press F5 and mentions Learn and Library', async (p) => {
    const lines = (await p.screen()).split('\n');
    p.assert.match(lines[15], /Press F5 to run the program in the editor/);
    p.assert.match(lines[16], /Learn: step-by-step lessons {3}Library: hundreds of programs/);
  }, { fresh: true });

  t.test('welcome screen points to the GW-BASIC Classic Console', async (p) => {
    const lines = (await p.screen()).split('\n');
    p.assert.match(lines[18], /View > GW-BASIC Classic Console for the 1980s experience/);
  }, { fresh: true });

  t.test('welcome screen is drawn under the first-run welcome dialog too', async (p) => {
    await p.waitModal();
    p.assert.match(await p.screen(), /B {3}A {3}Y {3}S {3}I {3}K/);
    p.assert.match(await p.screen(), /Press F5 to run/);
  }, { fresh: { firstRun: true } });

  t.test('welcome screen is text mode 0 with a blue background', async (p) => {
    p.assert.equal(await p.ev('RC.app.runner.display.mode'), 0);
    // sample the canvas inside the screen, away from the text: background colour 1 is blue
    const px = await p.fn(() => {
      const c = document.getElementById('screen');
      const g = c.getContext('2d');
      const d = g.getImageData(4, Math.floor(c.height * 0.1), 1, 1).data;
      return [d[0], d[1], d[2]];
    });
    p.assert.ok(px[2] > 120 && px[0] < 60 && px[1] < 60, 'blue background, got ' + px);
  }, { fresh: true });

  t.test('running a program replaces the welcome screen', async (p) => {
    p.assert.match(await p.screen(), /B {3}A {3}Y/);
    await p.runProgram('CLS: PRINT "GONE"');
    const s = await p.screen();
    p.assert.match(s, /GONE/);
    p.assert.doesNotMatch(s, /B {3}A {3}Y {3}S/);
  }, { fresh: true });

  // ---- Tours toolbar button ------------------------------------------------------------------------
  t.test('Tours toolbar button opens a menu with lessons and all six tours in order', async (p) => {
    await p.click('#tbTour');
    await p.wait("!!document.querySelector('.menu-pop')", 3000);
    const items = await p.menuItems();
    p.assert.deepEqual(items.map((i) => i.label), ['Learn BASIC — all lessons…', ...TOUR_LABELS]);
    p.assert.ok(items.every((i) => !i.disabled));
  }, { fresh: true });

  t.test('Tours menu has a separator right after the lessons item', async (p) => {
    await p.click('#tbTour');
    await p.wait("!!document.querySelector('.menu-pop')", 3000);
    const kids = await p.ev("[...document.querySelector('.menu-pop').children].map(e => e.classList.contains('menu-sep') ? '---' : e.innerText.trim())");
    p.assert.equal(kids.filter((k) => k === '---').length, 1);
    p.assert.equal(kids[1], '---');
  });

  t.test('Tours menu opens just below the Tours button', async (p) => {
    await p.click('#tbTour');
    await p.wait("!!document.querySelector('.menu-pop')", 3000);
    const b = await p.rect('#tbTour');
    const m = await p.rect('.menu-pop');
    p.assert.ok(Math.abs(m.y - b.bottom) <= 6, `menu top ${m.y} vs button bottom ${b.bottom}`);
    p.assert.ok(m.right <= (await p.ev('innerWidth')) + 0.5, 'menu inside viewport');
  });

  t.test('Tours menu "Learn BASIC — all lessons…" opens the Learn dialog', async (p) => {
    await p.click('#tbTour');
    await p.click('.menu-pop .menu-item', 'Learn BASIC — all lessons');
    p.assert.equal(await p.waitModal(), 'Learn BASIC — Tutorial');
    p.assert.equal(await p.exists('.menu-pop'), false);
    await p.modalButton('Close');
  });

  for (const [id, tour] of Object.entries(TOURS)) {
    t.test(`Tours menu "Tour: ${tour.title}" starts the ${id} tour`, async (p) => {
      await p.closeModals();
      await p.click('#tbTour');
      await p.click('.menu-pop .menu-item', 'Tour: ' + tour.title);
      await waitStep(p, 1, tour.steps.length);
      const s = await pop(p);
      p.assert.equal(s.title, tour.steps[0].title);
      p.assert.equal(await p.ev('RC.Tours.active.id'), id);
      p.assert.equal(await p.exists('.menu-pop'), false, 'menu closed');
      p.assert.equal(s.overlays, 2, 'exactly one popover and one spotlight');
    });
  }

  // ---- Help menu ---------------------------------------------------------------------------------
  t.test('Help menu lists all six tours between separators', async (p) => {
    await p.click('.menu-btn', 'Help');
    await p.wait("!!document.querySelector('.menu-pop')", 3000);
    const kids = await p.ev("[...document.querySelector('.menu-pop').children].map(e => e.classList.contains('menu-sep') ? '---' : e.children[0].innerText.trim())");
    const a = kids.indexOf('Tour: Welcome to the IDE');
    p.assert.equal(kids[a - 1], '---');
    p.assert.deepEqual(kids.slice(a, a + 6), TOUR_LABELS);
    p.assert.equal(kids[a + 6], '---');
    p.assert.equal(kids[a + 7], 'About the Author');
    p.assert.equal(kids[a + 8], 'About Baysik');
  });

  for (const [id, tour] of Object.entries(TOURS)) {
    t.test(`Help ▸ Tour: ${tour.title} starts the ${id} tour`, async (p) => {
      await p.closeModals();
      await p.menu('Help', 'Tour: ' + tour.title);
      await waitStep(p, 1, tour.steps.length);
      const s = await pop(p);
      p.assert.equal(s.title, tour.steps[0].title);
      p.assert.equal(s.count, `1 / ${tour.steps.length}`);
      p.assert.equal(await p.ev('RC.Tours.active.id'), id);
    });
  }
};
