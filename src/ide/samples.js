// Example programs: installation onto the virtual disk and the gallery dialog.
(function (RC) {
  'use strict';
  const { h } = RC.UI;
  const VERSION = 3;
  const INFO = [
    ['HELLO.BAS', 'Hello, World', 'Your very first program: PRINT, INPUT, COLOR and a FOR loop.', ['beginner', 'text']],
    ['SAMPLES\\GUESS.BAS', 'Guess the Number', 'RANDOMIZE, RND, INPUT and DO…LOOP in a classic game.', ['beginner', 'game']],
    ['SAMPLES\\TIMESTBL.BAS', 'Times Table', 'Neat columns with PRINT USING and nested FOR loops.', ['beginner', 'text']],
    ['SAMPLES\\COLORS.BAS', 'Color Chart', 'All 16 text colors, blinking and box-drawing characters.', ['text']],
    ['SAMPLES\\CLASSIC.BAS', 'GW-BASIC Quiz', 'Line numbers, GOTO, GOSUB, READ/DATA and ON…GOTO — 1980s style.', ['gw-basic', 'game']],
    ['SAMPLES\\FACTORL.BAS', 'Factorials & Recursion', 'Recursive FUNCTIONs — perfect for learning the debugger and call stack.', ['debugging', 'recursion']],
    ['SAMPLES\\HANOI.BAS', 'Towers of Hanoi', 'Recursive SUBs with animated graphics. Watch the call stack!', ['recursion', 'graphics']],
    ['SAMPLES\\SNAKE.BAS', 'Snake', 'Arrow keys, INKEY$, arrays, SOUND and the SCREEN function.', ['game']],
    ['SAMPLES\\SPIRAL.BAS', 'Spirals', 'LINE, SIN and COS in 640×480 VGA.', ['graphics']],
    ['SAMPLES\\TURTLE.BAS', 'Turtle Drawing', 'The DRAW macro language: turn, move and paint like Logo.', ['graphics']],
    ['SAMPLES\\SIERPIN.BAS', 'Chaos Game', 'Random jumps that draw the Sierpinski triangle.', ['graphics', 'math']],
    ['SAMPLES\\MANDEL.BAS', 'Mandelbrot Set', 'Fractal in 256-color VGA with a custom palette via OUT.', ['graphics', 'math']],
    ['SAMPLES\\PLASMA.BAS', 'Plasma', 'Palette cycling animation with VGA DAC ports and retrace WAIT.', ['graphics']],
    ['SAMPLES\\SPRITES.BAS', 'Bouncing Sprites', 'GET/PUT sprites and page flipping with PCOPY in SCREEN 7.', ['graphics', 'game']],
    ['SAMPLES\\SORTS.BAS', 'Sorting Visualizer', 'Bubble and selection sort shown as moving bars.', ['graphics', 'algorithms']],
    ['SAMPLES\\LIFE.BAS', 'Game of Life', "Conway's cellular automaton with 2-D arrays.", ['algorithms']],
    ['SAMPLES\\CLOCK.BAS', 'Analog Clock', 'ON TIMER event handlers, TIME$ and trigonometry.', ['events', 'graphics']],
    ['SAMPLES\\MUSIC.BAS', 'Music Box', 'PLAY tunes, SOUND effects and background music.', ['sound']],
    ['SAMPLES\\MODES.BAS', 'Screen Mode Tour', 'Every SCREEN mode from CGA to VGA, one keypress at a time.', ['graphics']],
    ['SAMPLES\\PHONEBK.BAS', 'Phone Book', 'TYPE records in a RANDOM-access file with GET and PUT.', ['files']],
    ['SAMPLES\\DIARY.BAS', 'Diary', 'Text files: OPEN for APPEND/INPUT, LINE INPUT #, EOF, ON ERROR.', ['files']],
    ['SAMPLES\\MULTI\\MAIN.BAS', 'Multi-file Program', "$INCLUDE a library file, then CHAIN to another program with COMMON.", ['multi-file']],
  ];
  RC.Samples = {
    INFO,
    install(vfs, force) {
      const files = RC.SAMPLE_FILES || {};
      const stamp = RC.UI.storage.get('samplesVersion', 0);
      const upgrade = stamp < VERSION;
      for (const [rel, text] of Object.entries(files)) {
        const target = rel.startsWith('SAMPLES\\') ? 'C:\\' + rel : 'C:\\MYPROGS\\' + rel;
        const parts = target.split('\\');
        let cur = parts[0];
        for (let i = 1; i < parts.length - 1; i++) { cur += '\\' + parts[i]; if (!vfs.exists(cur)) vfs.mkdir(cur); }
        const isSample = target.startsWith('C:\\SAMPLES\\');
        if (!vfs.exists(target) || ((force || upgrade) && isSample)) {
          vfs.writeFile(target, RC.strToBytes(RC.toCP437(text.replace(/\r?\n/g, '\r\n'))), { trusted: true });
        }
      }
      RC.UI.storage.set('samplesVersion', VERSION);
    },
    pathFor(rel) { return rel.startsWith('SAMPLES\\') ? 'C:\\' + rel : 'C:\\MYPROGS\\' + rel; },
    async gallery(app) {
      const grid = h('div.gallery');
      let close;
      for (const [rel, title, desc, tags] of INFO) {
        const card = h('button.card', { type: 'button' }, h('span.t', title), h('span.d', desc), h('span.tags', tags.map((t) => h('span', t))));
        card.addEventListener('click', () => {
          close();
          const p = this.pathFor(rel);
          if (!app.vfs.exists(p)) this.install(app.vfs, true);
          app.openFile(p);
          app.setStatus('Opened ' + p + ' — press F5 to run');
          if (app.isMobile()) app.setMobileView('editor');
        });
        grid.appendChild(card);
      }
      await RC.UI.modal({ title: 'Example Programs', wide: true, body: h('div', h('p.muted', 'Pick one to open it, then press F5 (or the Run button). The originals live in C:\\SAMPLES — edit freely, you can always reinstall them from Options ▸ Disk Usage.'), grid), buttons: [{ label: 'Close', value: null }], onOpen: (b, c) => { close = () => c(null); } });
    },
  };
})(RC);
