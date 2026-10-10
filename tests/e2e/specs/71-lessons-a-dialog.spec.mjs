// Tutorial: the Learn dialog (units, rows, progress, Start/Continue, Reset), tour controls, lesson data.
import { LESSONS, TOURS, fileFor, tourInfo, waitStep, tourButton, stopIfActive } from './71-lessons-lib.mjs';

const DIALOG = 'Learn BASIC — Tutorial';
const rows = (p) => p.ev(`[...document.querySelectorAll('.modal-back:last-child .list-row.clickable')].map((r) => ({
  num: r.children[0].innerText, title: r.children[1].innerText, summary: r.children[2].innerText,
  level: r.children[3].innerText, minutes: r.children[4].innerText, numColor: getComputedStyle(r.children[0]).color,
  unit: (() => { let e = r.previousElementSibling; while (e && !e.classList.contains('vsec')) e = e.previousElementSibling; return e ? e.textContent : null; })(),
}))`);
const footButtons = (p) => p.ev("[...document.querySelectorAll('.modal-back:last-child .modal-foot button')].map((b) => b.innerText.trim())");
const progress = (p) => p.ev("(document.querySelector('.modal-back:last-child .modal-body p b') || {}).innerText");
async function openLearn(p, via = 'toolbar') {
  await p.closeModals();
  if (via === 'menu') await p.menu('Help', 'Learn BASIC (Tutorial)…');
  else await p.click('#tbLearn');
  return p.waitModal();
}
const setDone = (p, ids) => p.fn((ids) => RC.UI.storage.set('lessonsDone', ids), ids);
async function clickRow(p, title) {
  const xy = await p.fn((t) => {
    const r = [...document.querySelectorAll('.modal-back:last-child .list-row.clickable')].find((x) => x.children[1].innerText === t);
    r.scrollIntoView({ block: 'center' });
    const b = r.getBoundingClientRect();
    return [b.left + 40, b.top + b.height / 2];
  }, title);
  await p.clickAt(xy[0], xy[1]);
}
const units = [...new Set(LESSONS.map((l) => l.unit))];

export default (t) => {
  t.test('page exposes all 57 lessons with the same ids and order as the source', async (p) => {
    const ids = await p.ev('RC.LESSONS.map((l) => l.id)');
    p.assert.equal(ids.length, 57);
    p.assert.deepEqual(ids, LESSONS.map((l) => l.id));
  });
  t.test('every lesson has either steps or an existing tour, and ids are unique', async (p) => {
    const bad = await p.ev("RC.LESSONS.filter((l) => !(l.tour ? RC.Tours.TOURS[l.tour] : (l.steps && l.steps.length))).map((l) => l.id)");
    p.assert.deepEqual(bad, []);
    p.assert.equal(new Set(LESSONS.map((l) => l.id)).size, LESSONS.length);
  });
  t.test('every practice-file name (C:\\LESSONS\\<ID>.BAS) is distinct and 8.3', async (p) => {
    const files = LESSONS.filter((l) => !l.tour).map(fileFor);
    p.assert.equal(new Set(files).size, files.length);
    for (const f of files) p.assert.match(f, /^C:\\LESSONS\\[A-Z0-9]{1,8}\.BAS$/);
  });
  t.test('the tutorial covers about 390 hand-written steps', async (p) => {
    const n = await p.ev('RC.LESSONS.reduce((a, l) => a + (l.steps ? l.steps.length : 0), 0)');
    p.assert.equal(n, LESSONS.reduce((a, l) => a + (l.steps ? l.steps.length : 0), 0));
    p.assert.ok(n >= 380, 'steps: ' + n);
  });

  t.test('toolbar Learn button opens the tutorial dialog', async (p) => {
    p.assert.equal(await p.attr('#tbLearn', 'title'), 'BASIC tutorial: step-by-step lessons');
    p.assert.equal(await openLearn(p), DIALOG);
  });
  t.test('Help ▸ Learn BASIC (Tutorial)… opens the same dialog', async (p) => {
    p.assert.equal(await openLearn(p, 'menu'), DIALOG);
    p.assert.equal(await p.count('.modal-back:last-child .list-row.clickable'), 57);
  });
  t.test('Tours button menu has "Learn BASIC — all lessons…" that opens the dialog', async (p) => {
    await p.closeModals();
    await p.click('#tbTour');
    await p.wait("!!document.querySelector('.menu-pop')", 3000);
    const items = await p.menuItems();
    p.assert.equal(items[0].label, 'Learn BASIC — all lessons…');
    await p.click('.menu-pop .menu-item', 'Learn BASIC — all lessons…');
    p.assert.equal(await p.waitModal(), DIALOG);
  });
  t.test('dialog intro states the lesson count and 0% progress on a fresh start', async (p) => {
    await openLearn(p);
    const txt = await p.modalText();
    p.assert.match(txt, /57 lessons from your very first PRINT to building a complete game/);
    p.assert.equal(await progress(p), '0%');
  }, { fresh: true });
  t.test('fresh dialog buttons: Close, Reset Progress, Start Lesson 1 ▶', async (p) => {
    await openLearn(p);
    p.assert.deepEqual(await footButtons(p), ['Close', 'Reset Progress', 'Start Lesson 1 ▶']);
    p.assert.ok(await p.ev("document.querySelector('.modal-back:last-child .modal-foot button.primary').innerText.includes('Start Lesson 1')"));
  });
  t.test('units appear as section headers in course order', async (p) => {
    await openLearn(p);
    const secs = await p.texts('.modal-back:last-child .vsec');
    p.assert.equal(secs.length, 16);
    p.assert.deepEqual(await p.ev("[...document.querySelectorAll('.modal-back:last-child .vsec')].map((e) => e.textContent)"), units);
  });
  t.test('rows are listed in lesson order, numbered 1..57', async (p) => {
    await openLearn(p);
    const r = await rows(p);
    p.assert.deepEqual(r.map((x) => x.num), LESSONS.map((_, i) => String(i + 1)));
    p.assert.deepEqual(r.map((x) => x.title), LESSONS.map((l) => l.title));
  });
  t.test('the lesson list scrolls inside the dialog', async (p) => {
    await openLearn(p);
    const s = await p.ev("(() => { const l = document.querySelector('.modal-back:last-child .list-row').parentElement; return { sh: l.scrollHeight, ch: l.clientHeight, ov: getComputedStyle(l).overflowY }; })()");
    p.assert.equal(s.ov, 'auto');
    p.assert.ok(s.sh > s.ch, 'list is taller than its box');
  });

  // one test per lesson row
  LESSONS.forEach((l, i) => {
    t.test(`row ${i + 1}: "${l.title}" shows number, title, summary, level badge and minutes under "${l.unit}"`, async (p) => {
      if (!(await p.modalOpen()) || (await p.modalTitle()) !== DIALOG) await openLearn(p);
      const r = (await rows(p))[i];
      const PL = await p.fn((i) => { const l = RC.LESSONS[i]; return { title: l.title, summary: l.summary, level: l.level, minutes: l.minutes, unit: l.unit }; }, i);
      p.assert.equal(r.num, String(i + 1));
      p.assert.equal(r.title, PL.title);
      p.assert.equal(r.summary, PL.summary);
      p.assert.equal(r.level, PL.level);
      p.assert.match(PL.level, /^(Everyone|Kids|Beginner|Intermediate|Advanced)$/);
      p.assert.equal(r.minutes, (PL.minutes || 5) + ' min');
      p.assert.equal(r.unit, PL.unit);
    });
  });

  t.test('Close button closes the dialog without starting a lesson', async (p) => {
    await openLearn(p);
    await p.modalButton('Close');
    p.assert.equal(await p.modalOpen(), false);
    p.assert.equal(await p.ev('RC.Tours.active'), null);
  });
  t.test('Escape closes the dialog without starting a lesson', async (p) => {
    await openLearn(p);
    await p.key('Escape');
    await p.waitGone('.modal-back');
    p.assert.equal(await p.ev('RC.Tours.active'), null);
  });
  t.test('Start Lesson 1 ▶ starts lesson 1 (the IDE tour) with its lesson header', async (p) => {
    await openLearn(p);
    await p.modalButton('Start Lesson 1 ▶');
    await p.waitGone('.modal-back');
    await waitStep(p, 0, TOURS.welcome.steps[0].title);
    const info = await tourInfo(p);
    p.assert.equal(info.header, 'Lesson 1 · 1. Getting Started');
    p.assert.equal(info.count, `1 / ${TOURS.welcome.steps.length}`);
    p.assert.equal(await p.ev("RC.UI.storage.get('lessonLast', null)"), 'meet-ide');
  });
  t.test('clicking a row closes the dialog and starts that lesson', async (p) => {
    await openLearn(p);
    await clickRow(p, 'Strings: Words in Boxes');
    await p.waitGone('.modal-back');
    await waitStep(p, 0, 'Text boxes');
    p.assert.equal((await tourInfo(p)).header, 'Lesson 7 · 2. Variables & Input');
    p.assert.equal(await p.activePath(), 'C:\\LESSONS\\STRINGS.BAS');
  });
  t.test('tour Back returns to the previous step and Back is disabled on step 1', async (p) => {
    await tourButton(p, 'Next');
    await waitStep(p, 1, 'Run it');
    await tourButton(p, 'Back');
    await waitStep(p, 0, 'Text boxes');
    p.assert.equal((await tourInfo(p)).btns.find((b) => b.text === 'Back').disabled, true);
  });
  t.test('"Skip step" moves past a check step without completing it', async (p) => {
    await tourButton(p, 'Next');
    await waitStep(p, 1, 'Run it');
    p.assert.equal((await tourInfo(p)).wait, 'Waiting for the right output…');
    await tourButton(p, 'Skip step');
    await waitStep(p, 2, 'Your turn');
    p.assert.equal(await p.ev('RC.app.runCount || 0'), 0, 'nothing was run');
  });
  t.test('tour Close removes the popup and spotlight and does not mark the lesson done', async (p) => {
    await tourButton(p, 'Close');
    p.assert.equal(await p.ev('RC.Tours.active'), null);
    p.assert.equal(await p.exists('.tour-pop'), false);
    p.assert.equal(await p.exists('.tour-hole'), false);
    p.assert.deepEqual(await p.ev("RC.UI.storage.get('lessonsDone', [])"), []);
  });
  t.test('starting a lesson again re-creates its practice file with the original code', async (p) => {
    await p.setCode('PRINT "changed"\n');
    await openLearn(p);
    await clickRow(p, 'Strings: Words in Boxes');
    await waitStep(p, 0, 'Text boxes');
    const code = await p.ev("RC.LESSONS.find((l) => l.id === 'strings').steps[0].code");
    p.assert.equal(await p.code(), code);
    p.assert.equal(await p.ev("RC.app.active.dirty"), false);
    await tourButton(p, 'Close');
  });

  t.test('completing a lesson via the UI marks its row with a check mark', async (p) => {
    // lesson 46 is a short tour (no waits): walk through it and press Complete
    await openLearn(p);
    await clickRow(p, 'Files & Sharing Tour');
    await waitStep(p, 0, TOURS.files.steps[0].title);
    for (let i = 1; i < TOURS.files.steps.length; i++) { await tourButton(p, 'Next'); await waitStep(p, i, TOURS.files.steps[i].title); }
    await tourButton(p, 'Complete ✓ Next lesson ▶');
    await p.wait("RC.UI.storage.get('lessonsDone', []).includes('files-tour')", 3000);
    await p.wait("RC.Tours.active && RC.Tours.active.tour.lessonTitle === 'Lesson 47 · 13. Files'", 3000);
    await tourButton(p, 'Close');
    await openLearn(p);
    const r = (await rows(p))[45];
    p.assert.equal(r.num, '✓');
    p.assert.equal((await rows(p))[46].num, '47');
    p.assert.equal(await progress(p), Math.round(100 / 57) + '%');
    p.assert.deepEqual(await footButtons(p), ['Close', 'Reset Progress', 'Continue ▶']);
  }, { fresh: true, timeout: 30000 });
  t.test('the check mark uses the "ok" color, unfinished numbers are muted', async (p) => {
    const r = await rows(p);
    p.assert.notEqual(r[45].numColor, r[0].numColor);
    p.assert.equal(r[45].numColor, await p.ev("(() => { const s = document.createElement('span'); s.style.color = 'var(--ok)'; document.querySelector('.modal-back:last-child .list-row').appendChild(s); const c = getComputedStyle(s).color; s.remove(); return c; })()"));
  });
  t.test('check marks persist across a reload', async (p) => {
    await p.closeModals();
    await setDone(p, ['meet-ide', 'hello-print', 'files-tour']);
    await p.reload();
    await openLearn(p);
    const r = await rows(p);
    p.assert.deepEqual([r[0].num, r[1].num, r[2].num, r[45].num], ['✓', '✓', '3', '✓']);
    p.assert.equal(await progress(p), Math.round(300 / 57) + '%');
  }, { timeout: 30000 });
  t.test('Continue ▶ goes to the first unfinished lesson (3)', async (p) => {
    await openLearn(p);
    await p.modalButton('Continue ▶');
    await waitStep(p, 0, TOURS.first.steps[0].title);
    p.assert.equal((await tourInfo(p)).header, 'Lesson 3 · 1. Getting Started');
    await tourButton(p, 'Close');
  });
  t.test('Continue ▶ skips over a gap: with 1–5 and 7 done it starts lesson 6', async (p) => {
    await stopIfActive(p);
    await setDone(p, ['meet-ide', 'hello-print', 'first-program', 'calculator', 'colors-comments', 'strings']);
    await openLearn(p, 'menu');
    p.assert.equal(await progress(p), Math.round(600 / 57) + '%');
    await p.modalButton('Continue ▶');
    await waitStep(p, 0, 'Named boxes');
    p.assert.equal((await tourInfo(p)).header, 'Lesson 6 · 2. Variables & Input');
    p.assert.equal(await p.activePath(), 'C:\\LESSONS\\VARIABLE.BAS');
    await tourButton(p, 'Close');
  });
  t.test('progress shows 100% when every lesson is done; Continue then restarts at lesson 1', async (p) => {
    await setDone(p, LESSONS.map((l) => l.id));
    await openLearn(p);
    p.assert.equal(await progress(p), '100%');
    p.assert.ok((await rows(p)).every((r) => r.num === '✓'));
    await p.modalButton('Continue ▶');
    await waitStep(p, 0, TOURS.welcome.steps[0].title);
    p.assert.equal((await tourInfo(p)).header, 'Lesson 1 · 1. Getting Started');
    await tourButton(p, 'Close');
  });
  t.test('Reset Progress asks for confirmation', async (p) => {
    await openLearn(p);
    await p.modalButton('Reset Progress');
    p.assert.equal(await p.waitModal(), 'Reset progress?');
    p.assert.match(await p.modalText(), /Clear all lesson check marks\?/);
    p.assert.deepEqual(await footButtons(p), ['Cancel', 'Reset']);
  });
  t.test('Reset Progress → Cancel keeps the check marks', async (p) => {
    await p.modalButton('Cancel');
    await p.waitGone('.modal-back');
    p.assert.equal((await p.ev("RC.UI.storage.get('lessonsDone', [])")).length, 57);
  });
  t.test('Reset Progress → Reset clears every check mark and progress returns to 0%', async (p) => {
    await openLearn(p);
    await p.modalButton('Reset Progress');
    await p.waitModal();
    await p.modalButton('Reset');
    await p.waitGone('.modal-back');
    p.assert.deepEqual(await p.ev("RC.UI.storage.get('lessonsDone', [])"), []);
    await openLearn(p);
    p.assert.equal(await progress(p), '0%');
    p.assert.equal((await rows(p))[0].num, '1');
    p.assert.deepEqual(await footButtons(p), ['Close', 'Reset Progress', 'Start Lesson 1 ▶']);
  });
  t.test('reset survives a reload', async (p) => {
    await p.closeModals();
    await p.reload();
    await openLearn(p);
    p.assert.ok((await rows(p)).every((r, i) => r.num === String(i + 1)));
    await p.closeModals();
  }, { timeout: 30000 });
  t.test('opening the Learn dialog during a lesson: the lesson popup does not sit on top of the dialog', async (p) => {
    await p.closeModals();
    await p.fn(() => RC.Lessons.start(RC.app, 54));
    await waitStep(p, 0, 'A falling star');
    await p.click('#tbLearn');
    await p.waitModal();
    // opening Learn closes the running lesson, so nothing covers the dialog's rows
    const r = await p.fn(() => {
      const pop = document.querySelector('.tour-pop');
      const row = document.querySelector('.modal-back:last-child .list-row.clickable');
      const b = row.getBoundingClientRect();
      const e = document.elementFromPoint(b.left + b.width / 2, b.top + b.height / 2);
      return { popGone: !pop, rowOnTop: !!(e && e.closest('.modal-back')) };
    });
    try { p.assert.ok(r.popGone && r.rowOnTop, 'lesson popup should be closed and dialog rows clickable ' + JSON.stringify(r)); } finally {
      await p.closeModals();
      await p.ev('RC.Tours.stop()');
    }
  });
  t.test('first-run welcome "Start the tutorial" opens the Learn dialog', async (p) => {
    p.assert.equal(await p.waitModal(), 'Welcome!');
    await p.modalButton('Start the tutorial');
    await p.wait(`document.querySelector('.modal-back:last-child .modal-head') && document.querySelector('.modal-back:last-child .modal-head').innerText === ${JSON.stringify(DIALOG)}`, 4000);
    p.assert.equal(await p.count('.modal-back:last-child .list-row.clickable'), 57);
  }, { fresh: { firstRun: true } });
};
