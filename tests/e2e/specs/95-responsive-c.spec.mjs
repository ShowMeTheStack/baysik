// Responsive behaviour: mobile view tabs, live resizing across breakpoints, the tablet drawer,
// splitters (real mouse drags, limits, persistence) and the full-size output screen.
import { box, fittedFrame, drag, hasAppClass, mview, activeMobileTab } from './95-responsive-helpers.mjs';

const PHONE = { width: 390, height: 844 };
const TABLET = { width: 1024, height: 768 };
const DESK = { width: 1400, height: 900 };

async function drawerOpen(p) {
  return p.ev("(() => { const r = document.getElementById('explorer').getBoundingClientRect(); return document.getElementById('app').classList.contains('explorer-open') && r.left >= -1 && r.width > 100; })()");
}
async function waitDrawer(p, open) {
  if (open) await p.wait("(() => { const r = document.getElementById('explorer').getBoundingClientRect(); return r.left >= -1 && r.width > 100; })()", 3000);
  else await p.wait("(() => { const r = document.getElementById('explorer').getBoundingClientRect(); return r.right <= 0 && !document.getElementById('app').classList.contains('explorer-open'); })()", 3000);
}
const tabNames = (p) => p.texts('#editorTabs .tab');
/** After a failed test the harness reloads at 1400x900; restore the viewport this group needs. */
async function ensureVp(p, o) {
  if (!(await p.ev(`innerWidth === ${o.width} && innerHeight === ${o.height}`))) await p.fresh(o);
}

export default (t) => {
  // ---------------------------------------------------------------- mobile view tabs
  t.test('phone: Code tab is active by default and shows only the editor', async (p) => {
    await ensureVp(p, PHONE);
    p.assert.equal(await mview(p), 'editor');
    p.assert.equal(await activeMobileTab(p), 'editor');
    p.assert.ok(await p.visible('#editorArea'));
    p.assert.equal(await p.visible('#screenArea'), false);
    p.assert.deepEqual(await p.texts('#mobileTabs button'), ['Code', 'Screen', 'Debug', 'Files']);
  }, { fresh: PHONE });

  t.test('phone: Screen tab shows the output screen full width and hides the editor', async (p) => {
    await ensureVp(p, PHONE);
    await p.click('#mobileTabs button', 'Screen');
    p.assert.equal(await mview(p), 'screen');
    p.assert.equal(await activeMobileTab(p), 'screen');
    p.assert.ok(await p.visible('#screenArea'));
    p.assert.equal(await p.visible('#editorArea'), false);
    const sa = await box(p, '#screenArea');
    p.assert.ok(Math.abs(sa.w - 390) <= 1, 'screen spans the width');
    const { frame } = await fittedFrame(p);
    p.assert.ok(frame.w >= 390 - 24, `screen frame uses the width (${frame.w})`);
  });

  t.test('phone: Debug tab shows the debug panels in place of the workspace', async (p) => {
    await ensureVp(p, PHONE);
    await p.click('#mobileTabs button', 'Debug');
    p.assert.equal(await mview(p), 'debug');
    p.assert.equal(await activeMobileTab(p), 'debug');
    p.assert.ok(await p.visible('#bottom'));
    p.assert.ok(await p.visible('#bottomTabs'));
    p.assert.equal(await p.visible('#editorArea'), false);
    p.assert.equal(await p.visible('#screenArea'), false);
    const b = await box(p, '#bottom');
    p.assert.ok(b.h > 400, `debug panels get the main area (${b.h}px)`);
    p.assert.ok(await p.noHScroll());
  });

  t.test('phone: Files tab shows the explorer full width', async (p) => {
    await ensureVp(p, PHONE);
    await p.click('#mobileTabs button', 'Files');
    p.assert.equal(await mview(p), 'files');
    p.assert.equal(await activeMobileTab(p), 'files');
    p.assert.ok(await p.visible('#explorer'));
    p.assert.equal(await p.visible('#editorArea'), false);
    const ex = await box(p, '#explorer');
    p.assert.ok(Math.abs(ex.w - 390) <= 1 && ex.x <= 1, 'explorer spans the width');
    p.assert.ok(await p.visible('#explorerTree .tree-item'), 'file tree items visible');
    p.assert.equal(await p.visible('#explorerClose'), false, 'drawer close button is not shown on phones');
  });

  t.test('phone: opening a file from the Files view switches back to Code with that file', async (p) => {
    await ensureVp(p, PHONE);
    await p.ev("RC.app.vfs.writeFile('C:\\\\MYPROGS\\\\MOBI.BAS', RC.app.encodeText('PRINT \"MOBILE\"'), {trusted: true}); RC.app.renderExplorer()");
    await p.sleep(250);
    if (await mview(p) !== 'files') await p.click('#mobileTabs button', 'Files');
    await p.click('#explorerTree .tree-item', 'MOBI.BAS');
    await p.wait("document.getElementById('app').dataset.mview === 'editor'", 3000);
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\MOBI.BAS');
    p.assert.equal(await activeMobileTab(p), 'editor');
    p.assert.match(await p.code(), /MOBILE/);
    p.assert.ok(await p.visible('#editorArea'));
  });

  t.test('phone: clicking a procedure in the Files view jumps to it in the Code view', async (p) => {
    await ensureVp(p, PHONE);
    await p.newFile('C:\\MYPROGS\\PROCS.BAS', 'PRINT 1\nPRINT 2\nSUB Hello\nPRINT "H"\nEND SUB\n');
    await p.click('#mobileTabs button', 'Files');
    await p.wait("!!document.querySelector('#procList .proc-item')", 3000);
    await p.click('#procList .proc-item', 'Hello');
    await p.wait("document.getElementById('app').dataset.mview === 'editor'", 3000);
    p.assert.equal(await p.ev('RC.app.active.editor.cursor().line'), 2);
  });

  t.test('phone: running a program switches to the Screen tab and shows its output', async (p) => {
    await ensureVp(p, PHONE);
    await p.click('#mobileTabs button', 'Code');
    await p.runProgram('PRINT "PHONE RUN"');
    p.assert.equal(await mview(p), 'screen');
    p.assert.equal(await activeMobileTab(p), 'screen');
    p.assert.ok(await p.visible('#screenFrame'));
    await fittedFrame(p);
    p.assert.match(await p.screen(), /PHONE RUN/);
  });

  t.test('phone: Run button in the toolbar runs from the Code tab and lands on Screen', async (p) => {
    await ensureVp(p, PHONE);
    await p.newFile('C:\\MYPROGS\\TB.BAS', 'PRINT "VIA BUTTON"');
    await p.click('#mobileTabs button', 'Code');
    await p.click('#tbRun');
    await p.waitState(['ended', 'error']);
    p.assert.equal(await mview(p), 'screen');
    p.assert.match(await p.screen(), /VIA BUTTON/);
  });

  t.test('phone: Debug tab shows variables of a program paused by STOP', async (p) => {
    await ensureVp(p, PHONE);
    await p.runProgram('ZEBRA% = 41 + 1\nSTOP\nPRINT ZEBRA%');
    p.assert.equal(await p.state(), 'paused');
    await p.click('#mobileTabs button', 'Debug');
    await p.click('#bottomTabs .tab', 'Variables');
    await p.wait("/ZEBRA/.test((document.querySelector('.bpanel.active') || {}).innerText || '')", 3000);
    p.assert.match(await p.panelText(), /ZEBRA%?[\s\S]*42/);
    await p.stopProgram();
  });

  t.test('phone: exactly one mobile tab is active after each switch', async (p) => {
    await ensureVp(p, PHONE);
    for (const v of ['Screen', 'Files', 'Debug', 'Code']) {
      await p.click('#mobileTabs button', v);
      p.assert.equal(await p.count('#mobileTabs button.active'), 1);
    }
    p.assert.equal(await activeMobileTab(p), 'editor');
  });

  t.test('landscape phone 844x390: mobile tabs are used and Screen view fits the short height', async (p) => {
    p.assert.ok(await p.visible('#mobileTabs'));
    await p.click('#mobileTabs button', 'Screen');
    const { frame } = await fittedFrame(p);
    p.assert.ok(frame.bottom <= 390 && frame.h < 300, `frame ${frame.h}px tall`);
    p.assert.ok(await p.noHScroll());
  }, { fresh: { width: 844, height: 390 } });

  // ---------------------------------------------------------------- live resizing in one page
  t.test('live resize: start on desktop with two open files and an unsaved edit', async (p) => {
    await p.newFile('C:\\MYPROGS\\ONE.BAS', 'PRINT "ONE"');
    await p.newFile('C:\\MYPROGS\\TWO.BAS', 'PRINT "TWO"');
    await p.setCode('PRINT "TWO EDITED"');
    p.assert.equal(await p.ev('RC.app.active.dirty'), true);
    p.assert.ok(await p.visible('#explorer'));
    const names = await tabNames(p);
    p.assert.ok(names.some((n) => /ONE\.BAS/.test(n)) && names.some((n) => /TWO\.BAS/.test(n)));
  }, { fresh: DESK });

  t.test('live resize: desktop → tablet turns the explorer into a drawer, keeps tabs and edits', async (p) => {
    await p.viewport(1024, 768);
    await p.wait("getComputedStyle(document.querySelector('#tbFiles')).display !== 'none'", 2000);
    await p.wait("document.getElementById('explorer').getBoundingClientRect().right <= 0", 3000);
    p.assert.ok(await p.visible('#editorArea') && await p.visible('#screenArea'));
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\TWO.BAS');
    p.assert.equal(await p.code(), 'PRINT "TWO EDITED"');
    p.assert.equal((await tabNames(p)).length >= 2, true);
    p.assert.ok(await p.noHScroll());
    await fittedFrame(p);
  });

  t.test('live resize: tablet → phone shows the mobile tabs and only the editor', async (p) => {
    await p.viewport(390, 844);
    await p.wait("getComputedStyle(document.getElementById('mobileTabs')).display === 'flex'", 2000);
    p.assert.equal(await p.visible('#screenArea'), false);
    p.assert.equal(await p.visible('#explorer'), false);
    p.assert.ok(await p.visible('#editorArea'));
    p.assert.equal(await p.code(), 'PRINT "TWO EDITED"');
    p.assert.ok(await p.noHScroll());
  });

  t.test('live resize: phone Screen view, then back to desktop shows every pane again', async (p) => {
    await p.click('#mobileTabs button', 'Screen');
    await fittedFrame(p);
    await p.viewport(1400, 900);
    await p.wait("getComputedStyle(document.getElementById('mobileTabs')).display === 'none'", 2000);
    for (const s of ['#explorer', '#editorArea', '#screenArea', '#bottom']) p.assert.ok(await p.visible(s), s + ' visible');
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\TWO.BAS');
    p.assert.equal(await p.code(), 'PRINT "TWO EDITED"');
    p.assert.equal(await p.ev('RC.app.active.dirty'), true, 'unsaved state kept');
    const names = await tabNames(p);
    p.assert.ok(names.some((n) => /ONE\.BAS/.test(n)) && names.some((n) => /TWO\.BAS/.test(n)), 'both tabs still open');
    await fittedFrame(p);
    p.assert.ok(await p.noHScroll());
  });

  t.test('live resize: the screen frame refits to 4:3 at every step of a resize sweep', async (p) => {
    for (const [w, h] of [[1920, 1080], [1280, 720], [1100, 800], [900, 600], [1600, 1000]]) {
      await p.viewport(w, h);
      const { frame, wrap } = await fittedFrame(p);
      p.assert.ok(frame.right <= wrap.right + 1 && frame.bottom <= wrap.bottom + 1, `${w}x${h}: frame overflows`);
      p.assert.ok(await p.noHScroll(), `${w}x${h}: horizontal scroll`);
    }
  });

  t.test('live resize: a running program keeps running and keeps its output across breakpoints', async (p) => {
    await p.viewport(1400, 900);
    await p.runProgram('PRINT "ALIVE"\nDO\n  N& = N& + 1\n  IF INKEY$ = "q" THEN EXIT DO\nLOOP\nPRINT "BYE"', { wait: false });
    await p.waitScreen(/ALIVE/);
    for (const [w, h] of [[1024, 768], [390, 844], [844, 390], [1400, 900]]) {
      await p.viewport(w, h);
      p.assert.ok(['running', 'waiting'].includes(await p.state()), `stopped at ${w}x${h}`);
    }
    const n1 = await p.ev('RC.app.runner.vm.statementsExecuted');
    await p.sleep(150);
    p.assert.ok(await p.ev('RC.app.runner.vm.statementsExecuted') > n1, 'program still executing');
    p.assert.match(await p.screen(), /ALIVE/);
    await p.stopProgram();
  });

  t.test('live resize: an open tablet drawer does not overlay the desktop layout after widening', async (p) => {
    await p.viewport(1024, 768);
    await p.click('#tbFiles');
    await waitDrawer(p, true);
    await p.viewport(1400, 900);
    p.assert.equal(await p.ev("getComputedStyle(document.getElementById('drawerScrim')).display"), 'none', 'scrim hidden on desktop');
    const ex = await box(p, '#explorer'), ed = await box(p, '#editorArea');
    p.assert.ok(ex.right <= ed.x + 1, 'explorer back in its column, not over the editor');
    await p.ev("RC.app.toggleDrawer(false)");
  });

  t.test('live resize: open modal dialog stays within the viewport after shrinking to a phone', async (p) => {
    await p.viewport(1400, 900);
    await p.menu('Help', 'Keyboard Shortcuts');
    await p.waitModal();
    await p.viewport(360, 640);
    await p.sleep(100);
    const m = await box(p, '.modal-back:last-child .modal');
    p.assert.ok(m.x >= -1 && m.right <= 361 && m.y >= -1 && m.bottom <= 641, `modal ${JSON.stringify(m)}`);
    await p.key('Escape');
    await p.waitGone('.modal-back');
    await p.viewport(1400, 900);
  });

  // ---------------------------------------------------------------- tablet drawer
  t.test('tablet: Files button is shown with an accessible name and the drawer starts closed', async (p) => {
    await ensureVp(p, TABLET);
    p.assert.ok(await p.visible('#tbFiles'));
    p.assert.equal(await p.attr('#tbFiles', 'aria-label'), 'Show files');
    p.assert.equal(await hasAppClass(p, 'explorer-open'), false);
    p.assert.ok((await box(p, '#explorer')).right <= 0);
    p.assert.equal(await p.ev("getComputedStyle(document.getElementById('drawerScrim')).display"), 'none');
  }, { fresh: TABLET });

  t.test('tablet: Files button opens the drawer with a scrim behind it', async (p) => {
    await ensureVp(p, TABLET);
    await p.click('#tbFiles');
    await waitDrawer(p, true);
    p.assert.ok(await drawerOpen(p));
    const ex = await box(p, '#explorer');
    p.assert.ok(ex.x <= 1 && ex.y <= 1 && ex.bottom >= 767, 'drawer is a full-height left panel');
    p.assert.ok(Math.abs(ex.w - 320) <= 1, `drawer width min(320px, 80vw) = ${ex.w}`);
    p.assert.equal(await p.ev("getComputedStyle(document.getElementById('drawerScrim')).display"), 'block');
    p.assert.ok(await p.visible('#explorerClose'), 'close button visible in drawer');
    p.assert.ok(await p.visible('#explorerTree .tree-item'));
  });

  t.test('tablet: clicking the scrim closes the drawer', async (p) => {
    await ensureVp(p, TABLET);
    await p.clickAt(900, 500);
    await waitDrawer(p, false);
    p.assert.equal(await p.ev("getComputedStyle(document.getElementById('drawerScrim')).display"), 'none');
  });

  t.test('tablet: the ✕ button closes the drawer', async (p) => {
    await ensureVp(p, TABLET);
    await p.click('#tbFiles');
    await waitDrawer(p, true);
    await p.click('#explorerClose');
    await waitDrawer(p, false);
  });

  t.test('tablet: the Files button toggles the drawer closed again', async (p) => {
    await ensureVp(p, TABLET);
    await p.click('#tbFiles');
    await waitDrawer(p, true);
    await p.ev("RC.app.toggleDrawer()");
    await waitDrawer(p, false);
    await p.click('#tbFiles');
    await waitDrawer(p, true);
    await p.click('#explorerClose');
    await waitDrawer(p, false);
  });

  t.test('tablet: opening a file from the drawer closes it and opens the file', async (p) => {
    await ensureVp(p, TABLET);
    await p.ev("RC.app.vfs.writeFile('C:\\\\MYPROGS\\\\DRAWER.BAS', RC.app.encodeText('PRINT \"D\"'), {trusted: true}); RC.app.renderExplorer()");
    await p.sleep(250);
    await p.click('#tbFiles');
    await waitDrawer(p, true);
    await p.click('#explorerTree .tree-item', 'DRAWER.BAS');
    await waitDrawer(p, false);
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\DRAWER.BAS');
    p.assert.ok(await p.visible('#editorArea'));
  });

  t.test('tablet: drawer explorer actions are clickable (New program opens its dialog)', async (p) => {
    await ensureVp(p, TABLET);
    await p.click('#tbFiles');
    await waitDrawer(p, true);
    await p.click('#explorerActions button[aria-label="New program"]');
    p.assert.equal(await p.waitModal(), 'New Program');
    await p.key('Escape');
    await p.waitGone('.modal-back');
    await p.click('#explorerClose');
    await waitDrawer(p, false);
  });

  for (const [w, h] of [[900, 600], [1180, 820]]) {
    t.test(`tablet ${w}x${h}: drawer opens over the editor and closes via scrim`, async (p) => {
      await p.click('#tbFiles');
      await waitDrawer(p, true);
      const ex = await box(p, '#explorer');
      p.assert.ok(ex.right <= w && ex.w <= Math.min(320, w * 0.8) + 1);
      p.assert.ok(await p.noHScroll());
      await p.clickAt(w - 30, h / 2);
      await waitDrawer(p, false);
    }, { fresh: { width: w, height: h } });
  }

  t.test('tablet: Files button still opens the drawer after View ▸ Explorer was turned off', async (p) => {
    await p.menu('View', 'Explorer');
    p.assert.equal(await p.ev('RC.app.settings.showExplorer'), false);
    await p.click('#tbFiles');
    await p.sleep(400);
    p.assert.ok(await drawerOpen(p), 'drawer should show the files even when the desktop explorer column is hidden');
  }, { fresh: TABLET });

  // ---------------------------------------------------------------- splitters
  t.test('splitter: dragging the explorer splitter right widens the explorer', async (p) => {
    await ensureVp(p, DESK);
    const sp = await box(p, '.splitter[data-split="explorer"]');
    const before = (await box(p, '#explorer')).w;
    await drag(p, sp.x + 2, sp.y + 100, sp.x + 102, sp.y + 100);
    const after = (await box(p, '#explorer')).w;
    p.assert.ok(Math.abs(after - (before + 100)) <= 3, `explorer ${before} → ${after}`);
    p.assert.ok(Math.abs(await p.ev('RC.app.settings.explorerW') - after) <= 1);
    p.assert.equal(await p.ev("document.body.classList.contains('resizing')"), false, 'resizing class removed after drag');
    p.assert.equal(await p.count('.splitter.dragging'), 0);
  }, { fresh: DESK });

  t.test('splitter: explorer width is clamped to 120px minimum', async (p) => {
    await ensureVp(p, DESK);
    const sp = await box(p, '.splitter[data-split="explorer"]');
    await drag(p, sp.x + 2, sp.y + 100, 5, sp.y + 100);
    p.assert.equal(await p.ev('RC.app.settings.explorerW'), 120);
    p.assert.ok(Math.abs((await box(p, '#explorer')).w - 120) <= 1);
  });

  t.test('splitter: explorer width is clamped to 480px maximum', async (p) => {
    await ensureVp(p, DESK);
    const sp = await box(p, '.splitter[data-split="explorer"]');
    await drag(p, sp.x + 2, sp.y + 100, 800, sp.y + 100);
    p.assert.equal(await p.ev('RC.app.settings.explorerW'), 480);
    p.assert.ok(Math.abs((await box(p, '#explorer')).w - 480) <= 1);
    p.assert.ok(await p.noHScroll());
  });

  t.test('splitter: dragging the screen splitter left widens the output screen', async (p) => {
    await ensureVp(p, DESK);
    await p.ev('RC.app.settings.explorerW = 210; RC.app.settings.screenW = 46; RC.app.applyLayout()');
    await p.sleep(100);
    const sp = await box(p, '.splitter[data-split="screen"]');
    const before = (await box(p, '#screenArea')).w;
    await drag(p, sp.x + 2, sp.y + 100, sp.x - 98, sp.y + 100);
    const after = (await box(p, '#screenArea')).w;
    p.assert.ok(after > before + 80, `screen ${before} → ${after}`);
    const pct = await p.ev('RC.app.settings.screenW');
    p.assert.ok(pct > 46 && pct <= 75, `screenW ${pct}%`);
    await fittedFrame(p);
  });

  t.test('splitter: screen width is clamped between 18% and the editor-minimum limit (max 75%)', async (p) => {
    await ensureVp(p, DESK);
    await p.ev('RC.app.settings.explorerW = 210; RC.app.settings.screenW = 46; RC.app.applyLayout()');
    await p.sleep(100);
    let sp = await box(p, '.splitter[data-split="screen"]');
    await drag(p, sp.x + 2, sp.y + 100, 1395, sp.y + 100);
    p.assert.equal(await p.ev('RC.app.settings.screenW'), 18);
    const ws = await box(p, '#workspace');
    p.assert.ok(Math.abs((await box(p, '#screenArea')).w - ws.w * 0.18) <= 2);
    sp = await box(p, '.splitter[data-split="screen"]');
    await drag(p, sp.x + 2, sp.y + 100, 10, sp.y + 100);
    // the screen may widen until the editor reaches its 240px minimum (explorer 210 + splitters), capped at 75%
    const wsw = (await box(p, '#workspace')).w;
    const cap = Math.min(75, ((wsw - 214 - 248) / wsw) * 100);
    p.assert.ok(Math.abs((await p.ev('RC.app.settings.screenW')) - cap) < 0.6, 'screenW at cap ' + cap);
    p.assert.ok(await p.visible('#editorArea'), 'editor keeps a minimum width');
    p.assert.ok((await box(p, '#editorArea')).w >= 239, 'editor min width 240px');
  });

  t.test('splitter: dragging the screen splitter to its maximum keeps the screen inside the window', async (p) => {
    await ensureVp(p, DESK);
    const sp = await box(p, '.splitter[data-split="screen"]');
    await drag(p, sp.x + 2, sp.y + 100, 10, sp.y + 100);
    const sa = await box(p, '#screenArea');
    p.assert.ok(sa.right <= 1401, `screen pane extends past the right edge of the window (right=${sa.right})`);
    p.assert.ok(await p.noHScroll(), 'layout wider than the window');
  });

  t.test('splitter: dragging the bottom splitter up makes the debug panels taller', async (p) => {
    await ensureVp(p, DESK);
    const sp = await box(p, '.splitter[data-split="bottom"]');
    const before = (await box(p, '#bottom')).h;
    await drag(p, 600, sp.y + 2, 600, sp.y - 98);
    const after = (await box(p, '#bottom')).h;
    p.assert.ok(Math.abs(after - (before + 100)) <= 4, `bottom ${before} → ${after}`);
    p.assert.ok(Math.abs(await p.ev('RC.app.settings.bottomH') - after) <= 2);
  });

  t.test('splitter: bottom panel height is clamped to 60px minimum and viewport-200 maximum', async (p) => {
    await ensureVp(p, DESK);
    let sp = await box(p, '.splitter[data-split="bottom"]');
    await drag(p, 600, sp.y + 2, 600, 895);
    p.assert.equal(await p.ev('RC.app.settings.bottomH'), 60);
    sp = await box(p, '.splitter[data-split="bottom"]');
    await drag(p, 600, sp.y + 2, 600, 5);
    p.assert.equal(await p.ev('RC.app.settings.bottomH'), 700);
    p.assert.ok((await box(p, '#editorArea')).h > 20, 'workspace keeps some height');
    p.assert.ok(await p.ev('document.documentElement.scrollHeight <= innerHeight + 1'));
  });

  t.test('splitter: sizes persist across a reload', async (p) => {
    await ensureVp(p, DESK);
    let sp = await box(p, '.splitter[data-split="explorer"]');
    await drag(p, sp.x + 2, sp.y + 100, 300, sp.y + 100);
    sp = await box(p, '.splitter[data-split="screen"]');
    await drag(p, sp.x + 2, sp.y + 100, 900, sp.y + 100);
    sp = await box(p, '.splitter[data-split="bottom"]');
    await drag(p, 600, sp.y + 2, 600, 600);
    const want = await p.ev('({e: RC.app.settings.explorerW, s: RC.app.settings.screenW, b: RC.app.settings.bottomH})');
    const rects = { e: (await box(p, '#explorer')).w, s: (await box(p, '#screenArea')).w, b: (await box(p, '#bottom')).h };
    p.assert.equal(want.e, 300);
    await p.reload();
    const got = await p.ev('({e: RC.app.settings.explorerW, s: RC.app.settings.screenW, b: RC.app.settings.bottomH})');
    p.assert.deepEqual(got, want);
    p.assert.ok(Math.abs((await box(p, '#explorer')).w - rects.e) <= 1);
    p.assert.ok(Math.abs((await box(p, '#screenArea')).w - rects.s) <= 1);
    p.assert.ok(Math.abs((await box(p, '#bottom')).h - rects.b) <= 1);
  });

  t.test('splitter: dragging adds the dragging/resizing classes only while the button is held', async (p) => {
    await ensureVp(p, DESK);
    const sp = await box(p, '.splitter[data-split="screen"]');
    await p.mouse('mouseMoved', sp.x + 2, sp.y + 50);
    await p.mouse('mousePressed', sp.x + 2, sp.y + 50);
    await p.mouse('mouseMoved', sp.x - 20, sp.y + 50);
    p.assert.equal(await p.ev("document.querySelector('.splitter[data-split=\"screen\"]').classList.contains('dragging')"), true);
    p.assert.equal(await p.ev("document.body.classList.contains('resizing')"), true);
    await p.mouse('mouseReleased', sp.x - 20, sp.y + 50);
    await p.sleep(50);
    p.assert.equal(await p.ev("document.querySelector('.splitter[data-split=\"screen\"]').classList.contains('dragging')"), false);
    p.assert.equal(await p.ev("document.body.classList.contains('resizing')"), false);
  });

  t.test('splitter: persisted desktop sizes do not break the phone layout', async (p) => {
    await ensureVp(p, DESK);
    await p.viewport(390, 844);
    await p.wait("getComputedStyle(document.getElementById('mobileTabs')).display === 'flex'", 2000);
    p.assert.ok(Math.abs((await box(p, '#editorArea')).w - 390) <= 1);
    p.assert.ok(await p.noHScroll());
    await p.viewport(1400, 900);
  });

  // ---------------------------------------------------------------- full-size screen
  t.test('F4 full size: screen pane button toggles full size, banner explains how to return', async (p) => {
    await p.click('#screenActions button[aria-label="Full size output (F4)"]');
    p.assert.ok(await hasAppClass(p, 'screen-max'));
    p.assert.match(await p.text('.screen-banner'), /F4 or Esc/);
    await p.key('Escape');
    p.assert.equal(await hasAppClass(p, 'screen-max'), false);
  }, { fresh: DESK });

  t.test('F4 full size: View menu item toggles it and output stays visible', async (p) => {
    await p.runProgram('PRINT "BIG SCREEN"');
    await p.menu('View', 'Output Screen Full Size');
    p.assert.ok(await hasAppClass(p, 'screen-max'));
    const { frame } = await fittedFrame(p);
    p.assert.ok(frame.h >= 900 - 60);
    p.assert.match(await p.screen(), /BIG SCREEN/);
    await p.key('F4');
    p.assert.equal(await hasAppClass(p, 'screen-max'), false);
  });

  t.test('F4 full size: survives a resize while maximised and refits', async (p) => {
    await p.key('F4');
    await p.viewport(1024, 768);
    let sa = await box(p, '#screenArea');
    p.assert.ok(sa.w >= 1023 && sa.h >= 767);
    await fittedFrame(p);
    await p.viewport(1400, 900);
    sa = await box(p, '#screenArea');
    p.assert.ok(sa.w >= 1399 && sa.h >= 899);
    await p.key('Escape');
    p.assert.equal(await hasAppClass(p, 'screen-max'), false);
  });

  t.test('F4 from the phone Code view shows the output screen full size', async (p) => {
    await p.ev('document.activeElement && document.activeElement.blur()');
    await p.key('F4');
    p.assert.ok(await hasAppClass(p, 'screen-max'));
    const sa = await box(p, '#screenArea');
    p.assert.ok(sa.w >= 389 && sa.h >= 843, `full-size screen is invisible: ${JSON.stringify(sa)}`);
  }, { fresh: PHONE });
};
