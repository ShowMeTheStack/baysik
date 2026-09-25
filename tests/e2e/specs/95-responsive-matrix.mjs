// Viewport matrix used by 95-responsive-a / 95-responsive-b (not a spec file itself).
import { modeOf, box, fullyInViewport, fittedFrame, hasAppClass } from './95-responsive-helpers.mjs';

export const VIEWPORTS = [
  [320, 568], [360, 640], [390, 844], [414, 896], [600, 960], [768, 1024], [820, 1180], [844, 390],
  [900, 600], [1024, 768], [1180, 820], [1280, 720], [1366, 768], [1440, 900], [1920, 1080], [2560, 1440],
];

async function showScreen(p, mode) {
  if (mode === 'phone') {
    await p.click('#mobileTabs button[data-view="screen"]');
    await p.wait("document.getElementById('app').dataset.mview === 'screen'", 2000);
  }
}

/** After a failure the harness reloads at 1400x900; put the viewport back so one failure doesn't cascade. */
async function ensure(p, w, h) {
  const ok = await p.ev(`innerWidth === ${w} && innerHeight === ${h} && !document.querySelector('.modal-back') && !document.getElementById('app').classList.contains('screen-max')`);
  if (!ok) await p.fresh({ width: w, height: h });
}

export function matrix(t, list) {
  for (const [w, h] of list) {
    const vp = `${w}x${h}`;
    const mode = modeOf(w, h);

    t.test(`${vp} (${mode}): no horizontal page scroll and no vertical page overflow`, async (p) => {
      p.assert.equal(await p.ev('innerWidth'), w);
      p.assert.ok(await p.noHScroll(), 'page scrolls horizontally');
      const sh = await p.ev('document.documentElement.scrollHeight');
      p.assert.ok(sh <= h + 1, `page is taller than the viewport: ${sh} > ${h}`);
      const st = await box(p, '#statusbar');
      p.assert.ok(Math.abs(st.bottom - h) <= 1, `status bar should sit at the bottom edge (bottom=${st.bottom})`);
    }, { fresh: { width: w, height: h } });

    t.test(`${vp} (${mode}): the right panes are visible for the layout`, async (p) => {
      await ensure(p, w, h);
      const tabs = await p.visible('#mobileTabs');
      const files = await p.visible('#tbFiles');
      const editor = await p.visible('#editorArea');
      const screen = await p.visible('#screenArea');
      const explorer = await p.visible('#explorer');
      const bottom = await p.visible('#bottom');
      const exSplit = await p.visible('.splitter[data-split="explorer"]');
      p.assert.ok(editor, 'editor should always be visible on load');
      if (mode === 'phone') {
        p.assert.ok(tabs, 'mobile tab bar visible');
        p.assert.equal(screen, false, 'screen hidden in Code view');
        p.assert.equal(explorer, false, 'explorer hidden in Code view');
        p.assert.equal(bottom, false, 'debug panels hidden in Code view');
        p.assert.equal(files, false, 'drawer Files button hidden on phones');
        p.assert.equal(await p.ev("[...document.querySelectorAll('.splitter')].every(s => getComputedStyle(s).display === 'none')"), true);
        const ed = await box(p, '#editorArea');
        p.assert.ok(Math.abs(ed.w - w) <= 1, `editor should span the full width (${ed.w})`);
      } else if (mode === 'tablet') {
        p.assert.equal(tabs, false, 'no mobile tabs on tablets');
        p.assert.ok(files, 'Files drawer button visible on tablets');
        p.assert.ok(screen, 'screen visible beside the editor');
        p.assert.ok(bottom, 'debug panels visible');
        p.assert.equal(exSplit, false, 'explorer splitter hidden on tablets');
        const ex = await box(p, '#explorer');
        p.assert.ok(ex.right <= 0, `explorer drawer should be off-canvas (right=${ex.right})`);
        const ed = await box(p, '#editorArea'), sc = await box(p, '#screenArea');
        p.assert.ok(ed.right <= sc.x + 1, 'editor is left of the screen');
        p.assert.ok(ed.x <= 1, 'editor starts at the left edge');
      } else {
        p.assert.equal(tabs, false, 'no mobile tabs on desktop');
        p.assert.equal(files, false, 'no drawer Files button on desktop');
        p.assert.ok(explorer && screen && bottom && exSplit, 'explorer, screen, bottom panels and splitter visible');
        const ex = await box(p, '#explorer'), ed = await box(p, '#editorArea'), sc = await box(p, '#screenArea');
        p.assert.ok(ex.x <= 1 && ex.right <= ed.x + 1 && ed.right <= sc.x + 1 && sc.right <= w + 1, 'explorer | editor | screen order without overlap');
      }
    });

    t.test(`${vp} (${mode}): menubar, toolbar and status bar never widen the page`, async (p) => {
      await ensure(p, w, h);
      for (const sel of ['#menubar', '#toolbar', '#statusbar']) {
        const b = await box(p, sel);
        p.assert.ok(b.x >= -1 && b.right <= w + 1, `${sel} spills out of the page (${b.x}..${b.right})`);
        if (b.sw > b.cw + 1) p.assert.ok(['auto', 'scroll', 'hidden'].includes(b.overflowX), `${sel} overflows without internal scrolling (${b.overflowX})`);
      }
      // every menu and the Run button can be reached (scrolled into view inside its bar)
      const n = await p.count('#menubar .menu-btn');
      p.assert.equal(n, 7);
      await p.ev("document.querySelectorAll('#menubar .menu-btn')[6].scrollIntoView({inline: 'nearest'})");
      p.assert.ok(await p.visible('#menubar .menu-btn[data-menu="6"]'), 'Help menu reachable');
      p.assert.ok(await p.visible('#tbRun'), 'Run button visible');
      p.assert.ok(await p.noHScroll());
    });

    t.test(`${vp} (${mode}): output screen frame keeps 4:3 and fits inside its area`, async (p) => {
      await ensure(p, w, h);
      await showScreen(p, mode);
      const { frame, wrap } = await fittedFrame(p);
      p.assert.ok(frame.x >= wrap.x - 1 && frame.right <= wrap.right + 1 && frame.y >= wrap.y - 1 && frame.bottom <= wrap.bottom + 1, 'frame inside wrap');
      p.assert.ok(Math.abs(frame.w / frame.h - 4 / 3) < 0.02, `aspect ${frame.w}x${frame.h}`);
      // the frame uses the available space: it touches (within padding) one pair of edges
      const slackW = wrap.w - frame.w, slackH = wrap.h - frame.h;
      p.assert.ok(Math.min(slackW, slackH) <= 24, `frame does not fill its area (slack ${slackW}, ${slackH})`);
      p.assert.ok(await p.noHScroll());
    });

    t.test(`${vp} (${mode}): About dialog fits within the viewport and closes with Escape`, async (p) => {
      await ensure(p, w, h);
      await p.menu('Help', 'About Baysik');
      p.assert.equal(await p.waitModal(), 'About Baysik');
      p.assert.ok(await fullyInViewport(p, '.modal-back:last-child .modal'), 'About dialog is cut off');
      p.assert.ok(await fullyInViewport(p, '.modal-back:last-child .modal-foot button'), 'OK button off-screen');
      p.assert.ok(await p.noHScroll());
      await p.key('Escape');
      await p.waitGone('.modal-back');
    });

    t.test(`${vp} (${mode}): Language Reference dialog fits within the viewport`, async (p) => {
      await ensure(p, w, h);
      await p.click('#tbHelp');
      p.assert.match(await p.waitModal(), /Language Reference/);
      p.assert.ok(await fullyInViewport(p, '.modal-back:last-child .modal'), 'Help dialog is cut off');
      p.assert.ok(await fullyInViewport(p, '.modal-back:last-child .modal-head'), 'Help title off-screen');
      p.assert.ok(await p.visible('.help-main'), 'help topic area visible');
      p.assert.ok(await p.noHScroll());
      await p.key('Escape');
      await p.waitGone('.modal-back');
    });

    t.test(`${vp} (${mode}): Program Library dialog fits within the viewport`, async (p) => {
      await ensure(p, w, h);
      await p.click('#tbExamples');
      await p.waitModal();
      p.assert.ok(await fullyInViewport(p, '.modal-back:last-child .modal'), 'Library dialog is cut off');
      p.assert.ok(await fullyInViewport(p, '.modal-back:last-child .modal-foot'), 'Library buttons off-screen');
      const body = await box(p, '.modal-back:last-child .modal-body');
      p.assert.ok(body.h > 40, 'library body has usable height');
      p.assert.ok(await p.noHScroll());
      await p.key('Escape');
      await p.waitGone('.modal-back');
    });

    t.test(`${vp} (${mode}): F4 shows the output screen full size at 4:3, F4 again restores`, async (p) => {
      await ensure(p, w, h);
      await showScreen(p, mode);
      await p.ev('document.activeElement && document.activeElement.blur()');
      await p.key('F4');
      p.assert.ok(await hasAppClass(p, 'screen-max'));
      const sa = await box(p, '#screenArea');
      p.assert.ok(sa.x <= 1 && sa.y <= 1 && sa.w >= w - 1 && sa.h >= h - 1, `screen area should cover the viewport: ${JSON.stringify(sa)}`);
      const { frame } = await fittedFrame(p);
      p.assert.ok(frame.w >= w - 24 || frame.h >= h - 60, `full-size frame should use the full width or height (${frame.w}x${frame.h})`);
      p.assert.ok(frame.right <= w + 1 && frame.bottom <= h + 1);
      p.assert.equal(await p.focusedId(), 'screen', 'screen canvas gets focus');
      await p.key('F4');
      p.assert.equal(await hasAppClass(p, 'screen-max'), false);
      if (mode !== 'phone') p.assert.ok(await p.visible('#editorArea'), 'editor visible again');
      p.assert.ok(await p.noHScroll());
    });
  }
}
