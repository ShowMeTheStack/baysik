// Tutorial: ~50 lessons built on the tour engine, with progress tracking.
(function (RC) {
  'use strict';
  const { h } = RC.UI;

  const fileFor = (l) => 'C:\\LESSONS\\' + l.id.toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 8) + '.BAS';
  const screenText = (app) => app.runner.display.textLines().map((s) => RC.fromCP437(s, false)).join('\n');

  function loadCode(app, lesson, code) {
    const vfs = app.vfs;
    if (!vfs.exists('C:\\LESSONS')) vfs.mkdir('C:\\LESSONS');
    const p = fileFor(lesson);
    vfs.writeFile(p, app.encodeText(code), { trusted: true });
    const d = app.docByPath(p);
    if (d) { d.editor.setValue(code); d.savedText = code; d.dirty = false; app.renderTabs(); }
    app.openFile(p);
  }

  /** Convert a lesson's step data into tour steps with live checks */
  function toTour(app, lesson, idx) {
    const steps = lesson.steps.map((s) => {
      const st = { title: s.title, text: s.text, sel: s.sel, hint: s.hint, quiz: s.quiz };
      const ctx = {};
      st.action = (a) => {
        if (s.code !== undefined) loadCode(a, lesson, s.code);
        else if (!a.docByPath(fileFor(lesson)) && a.vfs.exists(fileFor(lesson))) a.openFile(fileFor(lesson));
        if (s.panel) a.panels.show(s.panel);
      };
      st.enter = (a) => { ctx.runs = a.runCount || 0; };
      const c = s.check;
      if (c) {
        if (c.run) { st.wait = (a) => (a.runCount || 0) > ctx.runs && ['ended', 'waiting'].includes(a.runner.state); st.waitText = 'Waiting for you to run the program (F5)…'; }
        else if (c.codeHas) { const re = new RegExp(c.codeHas, 'i'); st.wait = (a) => !!a.active && re.test(a.active.editor.getValue()); st.waitText = 'Waiting for your code change…'; }
        else if (c.output) { const re = new RegExp(c.output, 'i'); st.wait = (a) => (a.runCount || 0) > ctx.runs && re.test(screenText(a)); st.waitText = 'Waiting for the right output…'; }
        else if (c.paused) { st.wait = (a) => a.runner.state === 'paused'; st.waitText = 'Waiting for the program to pause…'; }
        else if (c.breakpoint) { st.wait = (a) => { const b = a.breakpoints.get(fileFor(lesson)); return !!(b && b.size); }; st.waitText = 'Waiting for a breakpoint…'; }
      }
      return st;
    });
    const next = RC.LESSONS[idx + 1];
    return {
      title: lesson.title,
      lessonTitle: 'Lesson ' + (idx + 1) + ' · ' + lesson.unit,
      steps,
      finishLabel: next ? 'Complete ✓  Next lesson ▶' : 'Complete ✓',
      onFinish: (a) => { Lessons.complete(lesson.id); if (next) setTimeout(() => Lessons.start(a, idx + 1), 300); else RC.UI.toast('🎉 You finished the whole tutorial!', 'ok', 6000); },
    };
  }

  const Lessons = RC.Lessons = {
    done() { return new Set(RC.UI.storage.get('lessonsDone', [])); },
    complete(id) { const d = Lessons.done(); d.add(id); RC.UI.storage.set('lessonsDone', [...d]); RC.UI.storage.set('lessonLast', id); },
    start(app, idx) {
      const L = RC.LESSONS || [];
      const lesson = L[idx];
      if (!lesson) return;
      RC.UI.storage.set('lessonLast', lesson.id);
      if (lesson.tour) {
        const base = RC.Tours.TOURS[lesson.tour];
        const next = L[idx + 1];
        RC.Tours.start(app, Object.assign({}, base, {
          lessonTitle: 'Lesson ' + (idx + 1) + ' · ' + lesson.unit,
          finishLabel: next ? 'Complete ✓  Next lesson ▶' : 'Complete ✓',
          onFinish: (a) => { Lessons.complete(lesson.id); if (next) setTimeout(() => Lessons.start(a, idx + 1), 300); },
        }));
        return;
      }
      RC.Tours.start(app, toTour(app, lesson, idx));
    },
    async browse(app) {
      RC.Tours.stop(); // a running lesson popup would sit on top of this dialog
      const L = RC.LESSONS || [];
      const done = Lessons.done();
      const last = RC.UI.storage.get('lessonLast', null);
      const list = h('div', { style: { maxHeight: '62vh', overflow: 'auto' } });
      let closeFn = () => {};
      let unit = null;
      L.forEach((l, i) => {
        if (l.unit !== unit) { unit = l.unit; list.appendChild(h('div.vsec', { style: { marginTop: '6px' } }, unit)); }
        const row = h('div.list-row.clickable', { style: { padding: '6px 8px' } },
          h('span', { style: { width: '22px', color: done.has(l.id) ? 'var(--ok)' : 'var(--muted)' } }, done.has(l.id) ? '✓' : String(i + 1)),
          h('span', { style: { minWidth: '220px', fontWeight: 600 } }, l.title),
          h('span.grow.muted', l.summary),
          h('span.vbadge', l.level), h('span.muted', { style: { fontSize: '11px' } }, (l.minutes || 5) + ' min'));
        row.addEventListener('click', () => { closeFn(); Lessons.start(app, i); });
        list.appendChild(row);
      });
      const nextIdx = Math.max(0, L.findIndex((l) => !done.has(l.id)));
      const pct = L.length ? Math.round((done.size / L.length) * 100) : 0;
      const r = await RC.UI.modal({
        title: 'Learn BASIC — Tutorial', wide: true,
        body: h('div', h('p', `${L.length} lessons from your very first PRINT to building a complete game. Each lesson opens a practice program and guides you step by step. Progress: `, h('b', pct + '%'), last ? '' : ''), list),
        buttons: [{ label: 'Close', value: null }, { label: 'Reset Progress', value: 'reset' }, { label: done.size ? 'Continue ▶' : 'Start Lesson 1 ▶', value: 'go', primary: true }],
        onOpen: (b, c) => { closeFn = () => c(null); },
      });
      if (r === 'go') Lessons.start(app, nextIdx);
      if (r === 'reset' && await RC.UI.confirm('Reset progress?', 'Clear all lesson check marks?', 'Reset')) RC.UI.storage.set('lessonsDone', []);
    },
  };
})(RC);
