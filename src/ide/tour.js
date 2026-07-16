// Guided tours: spotlight an element, explain it, optionally wait for the learner to act.
(function (RC) {
  'use strict';
  const { h } = RC.UI;

  const ed = (app) => app.active && app.active.editor;
  const code = (s) => `<code>${RC.escapeHtml(s)}</code>`;

  async function scratch(app, name, text) {
    const vfs = app.vfs;
    if (!vfs.exists('C:\\MYPROGS')) vfs.mkdir('C:\\MYPROGS');
    const p = 'C:\\MYPROGS\\' + name;
    vfs.writeFile(p, app.encodeText(text), { trusted: true });
    const d = app.docByPath(p);
    if (d) { d.editor.setValue(text); d.savedText = text; d.dirty = false; }
    app.openFile(p);
    return p;
  }

  const TOURS = {
    welcome: {
      title: 'Welcome to the IDE',
      steps: [
        { title: 'Welcome to Compendium!', text: 'This is a complete BASIC programming studio in your browser, compatible with GW-BASIC and QBasic — the languages millions of people learned to program with. Let\'s take a quick look around.' },
        { sel: '#menubar', title: 'Menus', text: 'Everything lives in these menus. Hold <kbd>Alt</kbd> and press the first letter (Alt+F for File, Alt+R for Run…) or click.' },
        { sel: '#tbRun', title: 'Run your program', text: 'Press this button or <kbd>F5</kbd> to run the program in the editor. The same button continues a paused program.' },
        { sel: '#tbInto', title: 'Step through code', text: 'Debug buttons let you run one statement at a time (<kbd>F8</kbd>), step over SUB calls (<kbd>F10</kbd>) and step out (<kbd>Shift+F8</kbd>).' },
        { sel: '#tbSpeed', title: 'Speed', text: 'Old programs were written for slow PCs. Pick a vintage speed here, or slow motion to watch your program think.' },
        { sel: '#editorArea', title: 'The editor', text: 'Type your program here. Keywords turn UPPERCASE automatically, like in QBasic. Press <kbd>F1</kbd> on any keyword for help, and click the left margin to add a breakpoint.' },
        { sel: '#screenArea', title: 'The output screen', text: 'Your program draws here — text, colors, graphics in every classic screen mode. <b>Click it</b> to type into your program. <kbd>F4</kbd> makes it full size.' },
        { sel: '#bottom', title: 'Panels', text: 'The Immediate window runs single statements instantly. Variables, Watch and Call Stack show what is going on inside a paused program. History shows what just ran. The Printer collects LPRINT output.' },
        { sel: '#explorer', title: 'Files', text: 'Your programs live on drive C: — a virtual disk stored in this browser. Examples are in C:\\SAMPLES. You can import files, download them, mount a real folder as D: and share whole projects as a link.' },
        { sel: '#tbExamples', title: 'Examples', text: 'Games, graphics, music, files and recursion demos — open one and press F5.' },
        { sel: '#tbTour', title: 'More tours', text: 'Want to write your first program, or learn the debugger? Start another tour here any time. Have fun!' },
      ],
    },
    first: {
      title: 'Your First Program',
      steps: [
        { title: 'Your first program', text: 'Let\'s write a program together. I\'ll create a new empty file called FIRST.BAS for you.', action: (app) => scratch(app, 'FIRST.BAS', '') },
        { sel: '#editorArea', title: 'Say hello', text: `Click in the editor and type:<br>${code('PRINT "Hello, world!"')}<br>(the keyword turns uppercase when you leave the line)`, wait: (app) => /PRINT\s*"[^"]+"/i.test(ed(app) ? ed(app).getValue() : ''), waitText: 'Waiting for a PRINT line…' },
        { sel: '#tbRun', title: 'Run it!', text: 'Now press <kbd>F5</kbd> or click Run.', wait: (app) => app.runner.vm && app.runner.vm.prog && app.runner.vm.statementsExecuted > 0 && app.runner.state === 'ended', waitText: 'Waiting for the program to run…' },
        { sel: '#screenArea', title: 'It works!', text: 'There\'s your message on the output screen. Every program starts like this.' },
        { sel: '#editorArea', title: 'Ask a question', text: `Add two more lines:<br>${code('INPUT "What is your name"; n$')}<br>${code('PRINT "Hi, "; n$')}<br>Variables ending with <b>$</b> hold text.`, wait: (app) => /INPUT[^\n]*;\s*n\$/i.test(ed(app) ? ed(app).getValue() : ''), waitText: 'Waiting for an INPUT line…' },
        { sel: '#screenArea', title: 'Run and answer', text: 'Run again (F5). Click the screen if needed, type your name and press Enter.', wait: (app) => app.runner.state === 'ended' && /INPUT/i.test(ed(app) ? ed(app).getValue() : ''), waitText: 'Waiting for the program to finish…' },
        { sel: '#editorArea', title: 'Loops', text: `Computers love repeating. Add:<br>${code('FOR i = 1 TO 10')}<br>${code('    PRINT i; "Hi!"')}<br>${code('NEXT i')}<br>then run it.`, wait: (app) => /NEXT/i.test(ed(app) ? ed(app).getValue() : '') && app.runner.state === 'ended', waitText: 'Waiting for a FOR…NEXT loop to run…' },
        { title: 'You are a programmer!', text: 'Next ideas: change the numbers, add COLOR 14 before PRINT, or try the <b>Graphics & Sound</b> tour. The examples are full of ideas to borrow.' },
      ],
    },
    debug: {
      title: 'Debugging',
      steps: [
        { title: 'Become a bug detective', text: 'The debugger lets you freeze a running program and look inside. I\'ll open FACTORL.BAS, which uses recursion (a FUNCTION calling itself).', action: (app) => { app.openFile('C:\\SAMPLES\\FACTORL.BAS'); } },
        { sel: '.ed-gutter', title: 'Set a breakpoint', text: 'Find the line <code>Factorial# = 1</code> (marked with &lt;--). Click in the gutter left of its line number — a red dot appears.', wait: (app) => { const d = app.active; const bps = d && app.breakpoints.get(d.path); return !!(bps && [...bps.keys()].some((l) => /Factorial# = 1\b/.test(d.editor.getLine(l)))); }, waitText: 'Waiting for the breakpoint…' },
        { sel: '#tbRun', title: 'Run to the breakpoint', text: 'Press <kbd>F5</kbd>. The program will run and stop right before that line.', wait: (app) => app.runner.state === 'paused', waitText: 'Waiting for the pause…' },
        { sel: '#bottom', title: 'The call stack', text: 'Open the <b>Call Stack</b> tab. Factorial has called itself again and again — each call is a frame with its own n%. Click a lower frame to look at it.', action: (app) => app.panels.show('stack') },
        { sel: '#bottom', title: 'Variables', text: 'The <b>Variables</b> tab shows the selected frame\'s locals and the module globals. Double-click a value to change it while the program is paused!', action: (app) => app.panels.show('vars') },
        { sel: '#editorArea', title: 'Hover to peek', text: 'Hover the mouse over a variable name in the editor to see its value in the selected frame.' },
        { sel: '#tbInto', title: 'Step', text: 'Press <kbd>F8</kbd> a few times. The yellow arrow shows the next statement. Watch the stack shrink as functions return.', wait: (app) => app.runner.vm && app.runner.vm.history.length > 3 && app.runner.state === 'paused' && app.runner.vm.pauseReason === 'step', waitText: 'Waiting for a step…' },
        { sel: '#bottom', title: 'Immediate window', text: 'In the <b>Immediate</b> tab type <code>? n% * 100</code> and press Enter — it evaluates in the selected frame. You can also run statements like <code>PRINT "hi"</code>.', action: (app) => app.panels.show('immediate') },
        { sel: '#tbRun', title: 'Continue', text: 'Press <kbd>F5</kbd> to continue (it will stop at the breakpoint again — remove it by clicking the red dot). <kbd>Ctrl+F2</kbd> stops the program.' },
      ],
    },
    graphics: {
      title: 'Graphics & Sound',
      steps: [
        { title: 'Pixels and beeps', text: 'Classic PCs had several graphics modes. SCREEN picks one. Let\'s draw something.', action: (app) => scratch(app, 'DRAWING.BAS', "' Graphics demo\nSCREEN 12\nFOR r = 10 TO 200 STEP 10\n    CIRCLE (320, 240), r, r MOD 15 + 1\nNEXT\nLINE (100, 100)-(540, 380), 14, B\nPLAY \"T180 O3 L8 CEG>C\"\n") },
        { sel: '#editorArea', title: 'Graphics statements', text: '<code>SCREEN 12</code> is 640×480 with 16 colors. <code>CIRCLE</code>, <code>LINE … B</code> (box) and <code>PLAY</code> (music) do the rest. Press <kbd>F5</kbd>.', wait: (app) => app.runner.state === 'ended' || app.runner.state === 'waiting', waitText: 'Waiting for you to run it…' },
        { sel: '#screenArea', title: 'Try other modes', text: 'Change <code>SCREEN 12</code> to <code>SCREEN 13</code> (320×200, 256 colors) or <code>SCREEN 1</code> (old CGA, 4 colors) and run again. Help ▸ Language Reference ▸ Screen modes lists them all.' },
        { sel: '#tbExamples', title: 'More', text: 'MANDEL, PLASMA, SPRITES, TURTLE and MUSIC in the examples show palettes, animation, the DRAW language and songs.' },
      ],
    },
    files: {
      title: 'Files & Sharing',
      steps: [
        { sel: '#explorer', title: 'Your disk', text: 'Drive C: is a virtual disk saved in your browser. Programs can OPEN, write and read files here — try DIARY.BAS or PHONEBK.BAS.' },
        { sel: '#explorerActions', title: 'Import and export', text: 'Use these buttons to create programs and folders, import files from your computer, mount a real folder as D: (you decide whether programs may write to it), and share.' },
        { sel: '#explorerActions', title: 'Share a project', text: 'Sharing packs the current folder into a compressed link. Send it to a friend or teacher: when they open it, they get their own copy. Nothing is uploaded anywhere — the whole project is inside the link.' },
        { sel: '#menubar', title: 'Save', text: 'Files autosave (Options ▸ Autosave). <kbd>Ctrl+S</kbd> saves, File ▸ Save As copies, and Download saves to your computer. File ▸ Download Project (.zip) backs up a folder.' },
      ],
    },
    gw: {
      title: 'Classic GW-BASIC Console',
      steps: [
        { title: 'Back to 1985', text: 'Before QBasic, BASIC had no editor window: you typed numbered lines straight onto the screen. Let\'s try it.' },
        { sel: '#screenArea', title: 'The console', text: 'I\'ll switch the screen into GW-BASIC mode. Click the screen and type:<br><code>10 PRINT "HELLO"</code> (Enter)<br><code>20 GOTO 10</code> (Enter)<br><code>RUN</code> (Enter)', action: (app) => app.console.toggle(true), wait: (app) => app.runner.state === 'running' || app.runner.state === 'waiting', waitText: 'Waiting for RUN…' },
        { sel: '#screenArea', title: 'Break!', text: 'An endless loop! Press <kbd>Ctrl+C</kbd> (or Ctrl+Break) on the screen to stop it.', wait: (app) => app.runner.state === 'paused' || app.runner.state === 'ended', waitText: 'Waiting for Ctrl+C…' },
        { sel: '#screenArea', title: 'LIST and edit', text: 'Type <code>LIST</code>. Then move the cursor up onto line 10 with the arrow keys, change HELLO to your name and press Enter — that edits the line! Type RUN again to see it. <code>SYSTEM</code> leaves the console.' },
        { sel: '#editorArea', title: 'Same program, two views', text: 'Your numbered program also appears in the editor, so you can switch between both styles any time.' },
      ],
    },
  };

  const Tours = RC.Tours = {
    active: null,
    TOURS,
    menu(app) {
      const b = document.getElementById('tbTour');
      const r = b.getBoundingClientRect();
      RC.UI.showMenu(Object.entries(TOURS).map(([id, t]) => ({ label: t.title, action: () => Tours.start(app, id) })), r.left, r.bottom);
    },
    async offerWelcome(app) {
      const r = await RC.UI.modal({
        title: 'Welcome!',
        body: h('div', h('p', 'Compendium is a BASIC programming studio — GW-BASIC and QBasic compatible, with graphics, sound, files and a real debugger.'), h('p', 'Would you like a quick tour?')),
        buttons: [{ label: 'No thanks', value: null }, { label: 'Write my first program', value: 'first' }, { label: 'Show me around', value: 'welcome', primary: true }],
      });
      if (r) Tours.start(app, r);
    },
    start(app, id) {
      Tours.stop();
      const tour = TOURS[id];
      if (!tour) return;
      const hole = h('div.tour-hole');
      const pop = h('div.tour-pop', { role: 'dialog', 'aria-live': 'polite' });
      document.body.append(hole, pop);
      const st = { app, id, tour, i: 0, hole, pop, timer: null };
      Tours.active = st;
      Tours.show(st);
      st.onResize = () => Tours.place(st);
      window.addEventListener('resize', st.onResize);
    },
    stop() {
      const st = Tours.active;
      if (!st) return;
      clearInterval(st.timer);
      st.hole.remove(); st.pop.remove();
      window.removeEventListener('resize', st.onResize);
      Tours.active = null;
    },
    async show(st) {
      const step = st.tour.steps[st.i];
      clearInterval(st.timer);
      if (step.action) { try { await step.action(st.app); } catch (e) { console.error(e); } }
      if (st.app.isMobile() && step.sel) {
        const sel = step.sel;
        if (/editor|gutter/.test(sel)) st.app.setMobileView('editor');
        else if (/screen/.test(sel)) st.app.setMobileView('screen');
        else if (/bottom/.test(sel)) st.app.setMobileView('debug');
        else if (/explorer/.test(sel)) st.app.setMobileView('files');
      }
      const pop = st.pop;
      pop.innerHTML = '';
      const last = st.i === st.tour.steps.length - 1;
      const waitEl = step.wait ? h('div.tour-wait', step.waitText || 'Waiting…') : null;
      const next = h('button.btn.primary', { type: 'button' }, last ? 'Finish' : 'Next');
      const back = h('button.btn', { type: 'button', disabled: st.i === 0 }, 'Back');
      const skip = h('button.btn', { type: 'button' }, 'Close');
      next.addEventListener('click', () => { if (last) Tours.stop(); else { st.i++; Tours.show(st); } });
      back.addEventListener('click', () => { if (st.i > 0) { st.i--; Tours.show(st); } });
      skip.addEventListener('click', () => Tours.stop());
      pop.append(h('h3', step.title), h('p', { html: step.text }), waitEl, h('div.tour-foot', h('span.count', `${st.i + 1} / ${st.tour.steps.length}`), skip, back, next));
      if (step.wait) {
        next.textContent = 'Skip step';
        st.timer = setInterval(() => {
          let ok = false;
          try { ok = step.wait(st.app); } catch (e) { ok = false; }
          if (ok) { clearInterval(st.timer); waitEl.textContent = '✓ Done!'; next.textContent = last ? 'Finish' : 'Next'; next.focus(); setTimeout(() => { if (Tours.active === st && st.tour.steps[st.i] === step && !last) { st.i++; Tours.show(st); } }, 900); }
        }, 300);
      }
      Tours.place(st);
      setTimeout(() => Tours.place(st), 250);
    },
    place(st) {
      const step = st.tour.steps[st.i];
      const el = step.sel ? document.querySelector(step.sel) : null;
      const pop = st.pop;
      const pw = pop.offsetWidth, ph = pop.offsetHeight;
      const W = window.innerWidth, H = window.innerHeight;
      if (!el || !el.getClientRects().length) {
        st.hole.style.cssText = `left:${W / 2}px;top:${H / 2}px;width:0;height:0`;
        pop.style.left = Math.max(8, (W - pw) / 2) + 'px';
        pop.style.top = Math.max(8, (H - ph) / 2) + 'px';
        return;
      }
      const r = el.getBoundingClientRect();
      const pad = 4;
      st.hole.style.cssText = `left:${r.left - pad}px;top:${r.top - pad}px;width:${r.width + pad * 2}px;height:${r.height + pad * 2}px`;
      // choose a side with room
      let x, y;
      if (r.bottom + ph + 16 < H) { y = r.bottom + 12; x = r.left; }
      else if (r.top - ph - 16 > 0) { y = r.top - ph - 12; x = r.left; }
      else if (r.right + pw + 16 < W) { x = r.right + 12; y = r.top; }
      else if (r.left - pw - 16 > 0) { x = r.left - pw - 12; y = r.top; }
      else { x = (W - pw) / 2; y = H - ph - 12; }
      pop.style.left = Math.max(8, Math.min(W - pw - 8, x)) + 'px';
      pop.style.top = Math.max(8, Math.min(H - ph - 8, y)) + 'px';
    },
  };
})(RC);
