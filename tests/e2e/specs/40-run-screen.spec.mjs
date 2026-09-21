// Running programs: SCREEN modes, rendered pixels, text attributes, WIDTH, PALETTE/DAC, pages, scrolling.
import { rgb, hex, countColor, canvasSize, stopAll } from './40-run-helpers.mjs';

const MODES = {
  1: [320, 200], 2: [640, 200], 3: [720, 348], 7: [320, 200], 8: [640, 200], 9: [640, 350],
  10: [640, 350], 11: [640, 480], 12: [640, 480], 13: [320, 200],
};
// mode -> [attribute drawn, expected canvas color]
const DRAW = {
  1: [2, '#ff55ff'], 2: [1, '#ffffff'], 3: [1, '#cccccc'], 7: [4, '#aa0000'], 8: [14, '#ffff55'],
  9: [6, '#aa5500'], 10: [3, '#ffffff'], 11: [1, '#ffffff'], 12: [9, '#5555ff'], 13: [40, '#ff0000'],
};

export default (t) => {
  t.beforeEach(async (p) => { await stopAll(p); });

  // ---- welcome screen -----------------------------------------------------------------------------
  t.test('welcome screen is drawn on start with the BAYSIK banner', async (p) => {
    const s = await p.screen();
    p.assert.match(s, /B {3}A {3}Y {3}S {3}I {3}K/);
    p.assert.match(s, /Press F5 to run the program in the editor/);
  }, { fresh: true });
  t.test('welcome screen has a blue background on the canvas', async (p) => {
    p.assert.equal(await hex(p, 2, 2), '#0000aa');
    p.assert.equal(await hex(p, 637, 397), '#0000aa');
  });
  t.test('welcome banner frame is drawn in bright cyan', async (p) => {
    // row 9-11 (0-based 8-10) holds the double-line frame in color 11
    const n = await countColor(p, 0, 8 * 16, 640, 48, [0x55, 0xff, 0xff]);
    p.assert.ok(n > 500, 'cyan pixels in banner: ' + n);
  });
  t.test('welcome hint line is drawn in yellow', async (p) => {
    const n = await countColor(p, 0, 15 * 16, 640, 16, [0xff, 0xff, 0x55]);
    p.assert.ok(n > 200, 'yellow pixels: ' + n);
  });
  t.test('running a program replaces the welcome screen with a black text screen', async (p) => {
    await p.runProgram('PRINT "CLEAN"');
    const s = await p.screen();
    p.assert.doesNotMatch(s, /B {3}A {3}Y/);
    p.assert.match(s.split('\n')[0], /^CLEAN$/);
    p.assert.equal(await hex(p, 600, 300), '#000000');
  });

  // ---- SCREEN mode resolutions ----------------------------------------------------------------------
  t.test('SCREEN 0 text mode is 640x400 (80x25 with 8x16 cells)', async (p) => {
    await p.runProgram('SCREEN 0: PRINT "T"');
    p.assert.deepEqual(await canvasSize(p), [640, 400]);
    p.assert.equal(await p.ev('RC.app.runner.display.mode'), 0);
    p.assert.equal(await p.ev('RC.app.runner.display.textLines().length'), 25);
  });
  for (const [m, [w, h]] of Object.entries(MODES)) {
    t.test(`SCREEN ${m} sets the canvas to ${w}x${h}`, async (p) => {
      await p.runProgram(`SCREEN ${m}`);
      p.assert.equal(await p.state(), 'ended');
      p.assert.deepEqual(await canvasSize(p), [w, h]);
      p.assert.equal(await p.ev('RC.app.runner.display.mode'), +m);
      p.assert.match(await p.status(), new RegExp('SCREEN ' + m + '\\b'));
    });
  }
  for (const [m, [c, col]] of Object.entries(DRAW)) {
    t.test(`SCREEN ${m} renders PSET/LINE BF pixels in attribute ${c} as ${col}`, async (p) => {
      await p.runProgram(`SCREEN ${m}\nPSET (5, 5), ${c}\nLINE (20, 20)-(29, 29), ${c}, BF`);
      p.assert.equal(await p.state(), 'ended');
      p.assert.equal(await p.pixel(5, 5), c);
      p.assert.equal(await p.pixel(25, 25), c);
      p.assert.equal(await p.pixel(6, 6), 0);
      p.assert.equal(await hex(p, 25, 25), col);
      p.assert.equal(await hex(p, 5, 5), col);
      p.assert.equal(await hex(p, 40, 40), '#000000');
      p.assert.equal(await countColor(p, 20, 20, 10, 10, [1, 3, 5].map((i) => parseInt(col.slice(i, i + 2), 16))), 100);
    });
  }
  t.test('SCREEN 13 POINT reads back the drawn color', async (p) => {
    await p.runProgram('SCREEN 13: PSET (100, 50), 77: PRINT POINT(100, 50); POINT(101, 50)');
    p.assert.match(await p.screen(), /^ 77 {2}0/);
  });
  t.test('PSET in SCREEN 0 is an Illegal function call', async (p) => {
    await p.runProgram('SCREEN 0: PSET (1, 1), 1');
    p.assert.equal(await p.state(), 'error');
    p.assert.match(await p.status(), /Runtime error 5/);
  });
  t.test('SCREEN 5 is not a valid mode (Illegal function call)', async (p) => {
    await p.runProgram('SCREEN 5');
    p.assert.equal(await p.state(), 'error');
    p.assert.match(await p.status(), /Illegal function call/);
  });
  t.test('a new run resets to SCREEN 0 80x25 after a graphics program', async (p) => {
    await p.runProgram('SCREEN 12: CIRCLE (320, 240), 100, 14');
    p.assert.deepEqual(await canvasSize(p), [640, 480]);
    await p.runProgram('PRINT "BACK"');
    p.assert.deepEqual(await canvasSize(p), [640, 400]);
    p.assert.equal(await p.ev('RC.app.runner.display.mode'), 0);
  });
  t.test('graphics stay on screen after the program ends', async (p) => {
    await p.runProgram('SCREEN 13: LINE (0, 0)-(319, 199), 2, BF');
    await p.sleep(300);
    p.assert.equal(await hex(p, 160, 100), '#00aa00');
  });

  // ---- graphics primitives on the canvas ---------------------------------------------------------------
  t.test('CIRCLE draws its outline at the radius', async (p) => {
    await p.runProgram('SCREEN 12: CIRCLE (320, 240), 100, 15');
    p.assert.equal(await p.pixel(420, 240), 15);
    p.assert.equal(await p.pixel(220, 240), 15);
    p.assert.equal(await p.pixel(320, 240), 0);
    p.assert.equal(await hex(p, 420, 240), '#ffffff');
  });
  t.test('PAINT fills the inside of a circle', async (p) => {
    await p.runProgram('SCREEN 12: CIRCLE (320, 240), 50, 4: PAINT (320, 240), 2, 4');
    p.assert.equal(await p.pixel(320, 240), 2);
    p.assert.equal(await p.pixel(10, 10), 0);
    p.assert.equal(await hex(p, 320, 240), '#00aa00');
  });
  t.test('LINE with B draws only a box outline', async (p) => {
    await p.runProgram('SCREEN 13: LINE (10, 10)-(50, 50), 14, B');
    p.assert.equal(await p.pixel(10, 30), 14);
    p.assert.equal(await p.pixel(50, 30), 14);
    p.assert.equal(await p.pixel(30, 30), 0);
    p.assert.equal(await hex(p, 30, 10), '#ffff55');
  });
  t.test('DRAW moves the pen and plots lines', async (p) => {
    await p.runProgram('SCREEN 13: PSET (100, 100), 0: DRAW "C12 R20 D20"');
    p.assert.equal(await p.pixel(110, 100), 12);
    p.assert.equal(await p.pixel(120, 110), 12);
    p.assert.equal(await hex(p, 120, 110), '#ff5555');
  });
  t.test('GET and PUT copy a sprite', async (p) => {
    await p.runProgram('SCREEN 13: DIM a%(100): LINE (0, 0)-(9, 9), 9, BF: GET (0, 0)-(9, 9), a%: PUT (100, 100), a%, PSET');
    p.assert.equal(await p.pixel(105, 105), 9);
    p.assert.equal(await hex(p, 109, 109), '#5555ff');
    p.assert.equal(await p.pixel(111, 111), 0);
  });
  t.test('PUT with XOR twice erases the sprite', async (p) => {
    await p.runProgram('SCREEN 13: DIM a%(100): LINE (0, 0)-(9, 9), 9, BF: GET (0, 0)-(9, 9), a%: PUT (100, 100), a%: PUT (100, 100), a%');
    p.assert.equal(await p.pixel(105, 105), 0);
    p.assert.equal(await hex(p, 105, 105), '#000000');
  });
  t.test('VIEW clips drawing to the viewport', async (p) => {
    await p.runProgram('SCREEN 13: VIEW (50, 50)-(100, 100): LINE (0, 0)-(300, 190), 15, BF');
    p.assert.equal(await p.pixel(75, 75), 15);
    p.assert.equal(await p.pixel(10, 10), 0);
    p.assert.equal(await p.pixel(150, 150), 0);
  });
  t.test('WINDOW maps logical coordinates to the canvas', async (p) => {
    await p.runProgram('SCREEN 12: WINDOW (0, 0)-(100, 100): PSET (50, 50), 14');
    // WINDOW (not SCREEN) flips Y; (50,50) is the screen centre
    p.assert.equal(await p.pixel(320, 240), 14);
  });
  t.test('CLS in a graphics mode clears the canvas', async (p) => {
    await p.runProgram('SCREEN 13: LINE (0, 0)-(319, 199), 4, BF: CLS');
    p.assert.equal(await p.pixel(100, 100), 0);
    p.assert.equal(await hex(p, 100, 100), '#000000');
  });
  t.test('POKE into A000 video memory in SCREEN 13 plots a pixel', async (p) => {
    await p.runProgram('SCREEN 13: DEF SEG = &HA000: POKE 320 * 10 + 20, 4: DEF SEG');
    p.assert.equal(await p.pixel(20, 10), 4);
    p.assert.equal(await hex(p, 20, 10), '#aa0000');
  });
  t.test('PRINT text in SCREEN 13 renders glyph pixels in the foreground color', async (p) => {
    await p.runProgram('SCREEN 13: COLOR 14: PRINT CHR$(219)');
    p.assert.equal(await p.pixel(3, 3), 14);
    p.assert.equal(await hex(p, 3, 3), '#ffff55');
  });

  // ---- text mode colors and attributes ---------------------------------------------------------------
  t.test('default text is light grey on black', async (p) => {
    await p.runProgram('PRINT CHR$(219); " "');
    p.assert.equal(await hex(p, 3, 8), '#aaaaaa');
    p.assert.equal(await hex(p, 11, 8), '#000000');
  });
  t.test('COLOR 14, 4 renders yellow text on a red background', async (p) => {
    await p.runProgram('COLOR 14, 4: PRINT CHR$(219); " "');
    p.assert.equal(await hex(p, 3, 8), '#ffff55');
    p.assert.equal(await hex(p, 11, 8), '#aa0000');
  });
  for (const [c, col] of [[1, '#0000aa'], [2, '#00aa00'], [6, '#aa5500'], [8, '#555555'], [9, '#5555ff'], [12, '#ff5555'], [15, '#ffffff']]) {
    t.test(`COLOR ${c} draws text in ${col}`, async (p) => {
      await p.runProgram(`COLOR ${c}: PRINT CHR$(219)`);
      p.assert.equal(await hex(p, 4, 4), col);
    });
  }
  t.test('COLOR 0, 7 gives inverse video', async (p) => {
    await p.runProgram('COLOR 0, 7: PRINT " "; CHR$(219)');
    p.assert.equal(await hex(p, 3, 8), '#aaaaaa');
    p.assert.equal(await hex(p, 11, 8), '#000000');
  });
  t.test('the attribute byte is stored and read by SCREEN(r, c, 1)', async (p) => {
    await p.runProgram('COLOR 14, 4: LOCATE 5, 5: PRINT "Q": COLOR 7, 0: PRINT SCREEN(5, 5, 1); SCREEN(5, 5)');
    p.assert.match(await p.screen(), / 78 {2}81/);
  });
  t.test('COLOR 16+n sets the blink bit and the text blinks on the canvas', async (p) => {
    await p.runProgram('COLOR 30, 1: PRINT CHR$(219)');
    p.assert.equal(await p.ev('RC.app.runner.display.pages[0].attrs[0]'), 0x80 | 0x10 | 14);
    const seen = new Set();
    for (let i = 0; i < 14 && seen.size < 2; i++) { seen.add(await hex(p, 4, 4)); await p.sleep(70); }
    p.assert.deepEqual([...seen].sort(), ['#0000aa', '#ffff55']);
  });
  t.test('CLS after COLOR , 1 paints the whole text screen blue', async (p) => {
    await p.runProgram('COLOR 7, 1: CLS');
    p.assert.equal(await countColor(p, 0, 0, 640, 400, [0, 0, 0xaa]), 640 * 400);
  });
  t.test('LOCATE positions text at the row and column', async (p) => {
    await p.runProgram('LOCATE 10, 20: PRINT "X";: PRINT CSRLIN; POS(0)');
    const lines = (await p.screen()).split('\n');
    p.assert.equal(lines[9].indexOf('X'), 19);
    p.assert.match(lines[9], /X 10 {2}25/);
  });
  t.test('LOCATE text appears at the matching canvas cell', async (p) => {
    await p.runProgram('LOCATE 3, 11: COLOR 10: PRINT CHR$(219)');
    p.assert.equal(await hex(p, 10 * 8 + 4, 2 * 16 + 8), '#55ff55');
    p.assert.equal(await hex(p, 9 * 8 + 4, 2 * 16 + 8), '#000000');
  });
  t.test('VIEW PRINT limits scrolling to a text window', async (p) => {
    await p.runProgram('LOCATE 1, 1: PRINT "HEADER": VIEW PRINT 3 TO 10: FOR i = 1 TO 30: PRINT "L"; i: NEXT');
    const lines = (await p.screen()).split('\n');
    p.assert.equal(lines[0], 'HEADER');
    p.assert.equal(lines[8], "L 30");
    p.assert.equal(lines[2], "L 24");
    p.assert.equal(lines[15], '');
  });
  t.test('LOCATE outside the screen is an Illegal function call', async (p) => {
    await p.runProgram('LOCATE 26, 1');
    p.assert.equal(await p.state(), 'error');
    p.assert.match(await p.status(), /Runtime error 5/);
  });

  // ---- WIDTH -----------------------------------------------------------------------------------------
  t.test('WIDTH 40 makes a 320x400 canvas with 40 columns', async (p) => {
    await p.runProgram('WIDTH 40: PRINT STRING$(45, "A")');
    p.assert.deepEqual(await canvasSize(p), [320, 400]);
    const lines = (await p.screen()).split('\n');
    p.assert.equal(lines[0], 'A'.repeat(40));
    p.assert.equal(lines[1], 'AAAAA');
  });
  t.test('WIDTH 80, 43 gives 43 rows on a 640x344 canvas', async (p) => {
    await p.runProgram('WIDTH 80, 43: LOCATE 43, 1: PRINT "BOTTOM";');
    p.assert.deepEqual(await canvasSize(p), [640, 344]);
    const lines = (await p.screen()).split('\n');
    p.assert.equal(lines.length, 43);
    p.assert.equal(lines[42], 'BOTTOM');
  });
  t.test('WIDTH 80, 50 gives 50 rows of 8-pixel cells', async (p) => {
    await p.runProgram('WIDTH 80, 50: LOCATE 50, 1: COLOR 15: PRINT CHR$(219);');
    p.assert.deepEqual(await canvasSize(p), [640, 400]);
    p.assert.equal(await p.ev('RC.app.runner.display.rows'), 50);
    p.assert.equal(await hex(p, 3, 49 * 8 + 4), '#ffffff');
  });
  t.test('WIDTH 40, 50 combines 40 columns and 50 rows', async (p) => {
    await p.runProgram('WIDTH 40, 50: PRINT "OK"');
    p.assert.deepEqual(await canvasSize(p), [320, 400]);
    p.assert.equal(await p.ev('RC.app.runner.display.cols'), 40);
    p.assert.equal(await p.ev('RC.app.runner.display.rows'), 50);
  });
  t.test('WIDTH 80, 30 in text mode is an Illegal function call', async (p) => {
    await p.runProgram('WIDTH 80, 30');
    p.assert.equal(await p.state(), 'error');
    p.assert.match(await p.status(), /Runtime error 5/);
  });
  t.test('WIDTH 80, 60 in SCREEN 12 gives 60 text rows', async (p) => {
    await p.runProgram('SCREEN 12: WIDTH 80, 60: LOCATE 60, 1: PRINT "Z";');
    p.assert.deepEqual(await canvasSize(p), [640, 480]);
    p.assert.equal(await p.ev('RC.app.runner.display.rows'), 60);
    p.assert.match((await p.screen()).split('\n')[59], /^Z/);
  });
  t.test('WIDTH 80 in SCREEN 1 switches to the 640x200 mode', async (p) => {
    await p.runProgram('SCREEN 1: WIDTH 80');
    p.assert.equal(await p.ev('RC.app.runner.display.mode'), 2);
    p.assert.deepEqual(await canvasSize(p), [640, 200]);
  });
  t.test('the next run resets WIDTH 40 back to 80 columns', async (p) => {
    await p.runProgram('WIDTH 40');
    await p.runProgram('PRINT STRING$(60, "B")');
    p.assert.deepEqual(await canvasSize(p), [640, 400]);
    p.assert.equal((await p.screen()).split('\n')[0], 'B'.repeat(60));
  });

  // ---- PALETTE and the VGA DAC -----------------------------------------------------------------------
  t.test('SCREEN 13 PALETTE 1, 63 turns attribute 1 red', async (p) => {
    await p.runProgram('SCREEN 13: LINE (0, 0)-(9, 9), 1, BF: PALETTE 1, 63');
    p.assert.equal(await hex(p, 5, 5), '#ff0000');
  });
  t.test('SCREEN 13 PALETTE 1, 63 * 256 turns attribute 1 green', async (p) => {
    await p.runProgram('SCREEN 13: LINE (0, 0)-(9, 9), 1, BF: PALETTE 1, 63 * 256');
    p.assert.equal(await hex(p, 5, 5), '#00ff00');
  });
  t.test('SCREEN 13 PALETTE 1, 63 * 65536 turns attribute 1 blue', async (p) => {
    await p.runProgram('SCREEN 13: LINE (0, 0)-(9, 9), 1, BF: PALETTE 1, 63 * 65536');
    p.assert.equal(await hex(p, 5, 5), '#0000ff');
  });
  t.test('PALETTE recolors pixels already on the screen', async (p) => {
    await p.runProgram('SCREEN 13: LINE (0, 0)-(9, 9), 200, BF');
    const before = await hex(p, 5, 5);
    await p.runProgram('SCREEN 13: LINE (0, 0)-(9, 9), 200, BF: PALETTE 200, 32 + 32 * 256 + 32 * 65536');
    p.assert.notEqual(before, '#828282');
    p.assert.equal(await hex(p, 5, 5), '#828282');
    p.assert.equal(await p.pixel(5, 5), 200);
  });
  t.test('OUT &H3C8/&H3C9 programs the DAC and changes rendered colors', async (p) => {
    await p.runProgram('SCREEN 13: LINE (0, 0)-(9, 9), 5, BF: OUT &H3C8, 5: OUT &H3C9, 0: OUT &H3C9, 63: OUT &H3C9, 63');
    p.assert.equal(await hex(p, 5, 5), '#00ffff');
  });
  t.test('OUT &H3C8 auto-increments to the next DAC entry', async (p) => {
    await p.runProgram('SCREEN 13: LINE (0, 0)-(9, 9), 1, BF: LINE (10, 0)-(19, 9), 2, BF\nOUT &H3C8, 1\nFOR i = 1 TO 3: OUT &H3C9, 63: NEXT\nOUT &H3C9, 63: OUT &H3C9, 0: OUT &H3C9, 0');
    p.assert.equal(await hex(p, 5, 5), '#ffffff');
    p.assert.equal(await hex(p, 15, 5), '#ff0000');
  });
  t.test('OUT &H3C7 then INP(&H3C9) reads the DAC back', async (p) => {
    await p.runProgram('SCREEN 13: PALETTE 7, 10 + 20 * 256 + 30 * 65536: OUT &H3C7, 7: PRINT INP(&H3C9); INP(&H3C9); INP(&H3C9)');
    p.assert.match(await p.screen(), /^ 10 {2}20 {2}30/);
  });
  t.test('SCREEN 12 also honours OUT &H3C8 DAC writes', async (p) => {
    await p.runProgram('SCREEN 12: LINE (0, 0)-(9, 9), 3, BF: OUT &H3C8, 3: OUT &H3C9, 63: OUT &H3C9, 63: OUT &H3C9, 0');
    p.assert.equal(await hex(p, 5, 5), '#ffff00');
  });
  t.test('SCREEN 9 PALETTE maps an attribute to an EGA color', async (p) => {
    await p.runProgram('SCREEN 9: LINE (0, 0)-(9, 9), 1, BF: PALETTE 1, 36');
    p.assert.equal(await hex(p, 5, 5), '#ff0000');
  });
  t.test('SCREEN 0 PALETTE 0, 1 turns the text background blue', async (p) => {
    await p.runProgram('PALETTE 0, 1: PRINT "HI"');
    p.assert.equal(await hex(p, 600, 300), '#0000aa');
  });
  t.test('SCREEN 7 PALETTE 1, 14 shows attribute 1 as yellow', async (p) => {
    await p.runProgram('SCREEN 7: LINE (0, 0)-(9, 9), 1, BF: PALETTE 1, 14');
    p.assert.equal(await hex(p, 5, 5), '#ffff55');
  });
  t.test('PALETTE with no arguments restores the default colors', async (p) => {
    await p.runProgram('SCREEN 13: LINE (0, 0)-(9, 9), 1, BF: PALETTE 1, 63: PALETTE');
    p.assert.equal(await hex(p, 5, 5), '#0000aa');
  });
  t.test('PALETTE USING sets every EGA attribute from an array', async (p) => {
    await p.runProgram('SCREEN 9: DIM pal&(15): FOR i = 0 TO 15: pal&(i) = 63 - i: NEXT: LINE (0, 0)-(9, 9), 0, BF: PALETTE USING pal&(0)');
    p.assert.equal(await hex(p, 5, 5), '#ffffff');
  });
  t.test('SCREEN 1 COLOR 1, 0 sets a blue background and palette 0', async (p) => {
    await p.runProgram('SCREEN 1: COLOR 1, 0: LINE (20, 20)-(29, 29), 1, BF');
    p.assert.equal(await hex(p, 100, 100), '#0000aa');
    p.assert.equal(await hex(p, 25, 25), '#55ff55');
  });
  t.test('PALETTE with an out-of-range DAC value is an Illegal function call', async (p) => {
    await p.runProgram('SCREEN 13: PALETTE 1, 64');
    p.assert.equal(await p.state(), 'error');
    p.assert.match(await p.status(), /Runtime error 5/);
  });

  // ---- pages --------------------------------------------------------------------------------------
  t.test('SCREEN 7,,1,0 draws on a hidden page; only the visual page is shown', async (p) => {
    await p.runProgram('SCREEN 7, , 1, 0: LINE (0, 0)-(99, 99), 12, BF');
    p.assert.equal(await p.ev('RC.app.runner.display.apage'), 1);
    p.assert.equal(await p.ev('RC.app.runner.display.vpage'), 0);
    p.assert.equal(await p.ev('RC.app.runner.display.pages[1].pix[50 * 320 + 50]'), 12);
    p.assert.equal(await p.pixel(50, 50), 0);
    p.assert.equal(await hex(p, 50, 50), '#000000');
  });
  t.test('PCOPY 1, 0 copies the hidden page to the visible one', async (p) => {
    await p.runProgram('SCREEN 7, , 1, 0: LINE (0, 0)-(99, 99), 12, BF: PCOPY 1, 0');
    p.assert.equal(await p.pixel(50, 50), 12);
    p.assert.equal(await hex(p, 50, 50), '#ff5555');
  });
  t.test('switching the visual page with SCREEN 7,,0,1 reveals page 1', async (p) => {
    await p.runProgram('SCREEN 7, , 1, 0: LINE (0, 0)-(99, 99), 10, BF: SCREEN 7, , 0, 1');
    p.assert.equal(await p.ev('RC.app.runner.display.vpage'), 1);
    p.assert.equal(await hex(p, 50, 50), '#55ff55');
  });
  t.test('page flipping animation loop ends showing the last drawn frame', async (p) => {
    await p.runProgram('SCREEN 7, , 1, 0\nFOR f = 1 TO 20\nCLS\nLINE (f * 5, 0)-(f * 5 + 9, 9), 14, BF\nPCOPY 1, 0\nNEXT');
    p.assert.equal(await p.pixel(105, 5), 14);
    p.assert.equal(await p.pixel(50, 5), 0);
  });
  t.test('SCREEN 9 has two pages; page 2 is an Illegal function call', async (p) => {
    await p.runProgram('SCREEN 9, , 2');
    p.assert.equal(await p.state(), 'error');
    p.assert.match(await p.status(), /Runtime error 5/);
  });
  t.test('SCREEN 0 text written to a hidden page is not shown', async (p) => {
    await p.runProgram('SCREEN 0, , 1, 0: PRINT "HIDDEN"');
    p.assert.doesNotMatch(await p.screen(), /HIDDEN/);
    p.assert.match(await p.ev('RC.app.runner.display.textLines(1).join("\\n")'), /HIDDEN/);
  });
  t.test('SCREEN 0 PCOPY shows text from another page', async (p) => {
    await p.runProgram('SCREEN 0, , 1, 0: PRINT "COPIED": PCOPY 1, 0');
    p.assert.match(await p.screen(), /^COPIED/);
  });

  // ---- scrolling / long output -----------------------------------------------------------------------
  t.test('very long output scrolls; the last 24 lines remain', async (p) => {
    await p.runProgram('FOR i = 1 TO 100: PRINT i: NEXT');
    const lines = (await p.screen()).split('\n');
    p.assert.equal(lines[0], ' 77');
    p.assert.equal(lines[23], ' 100');
    p.assert.equal(lines[24], '');
  });
  t.test('2000 lines of output finish and end on the last line', async (p) => {
    await p.runProgram('FOR i = 1 TO 2000: PRINT "LINE"; i: NEXT', { timeout: 20000 });
    p.assert.equal(await p.state(), 'ended');
    p.assert.match(await p.screen(), /LINE 2000\n/);
  });
  t.test('a line longer than 80 characters wraps to the next row', async (p) => {
    await p.runProgram('PRINT STRING$(85, "W")');
    const lines = (await p.screen()).split('\n');
    p.assert.equal(lines[0].length, 80);
    p.assert.equal(lines[1], 'WWWWW');
  });
  t.test('printing on the last row scrolls the canvas contents up', async (p) => {
    await p.runProgram('COLOR 15: PRINT CHR$(219): COLOR 7: FOR i = 1 TO 24: PRINT: NEXT');
    // the block moved off the top; top-left cell now blank
    p.assert.equal(await hex(p, 4, 4), '#000000');
    p.assert.doesNotMatch(await p.screen(), /█/);
  });
  t.test('CLS clears scrolled text', async (p) => {
    await p.runProgram('FOR i = 1 TO 50: PRINT i: NEXT: CLS: PRINT "FRESH"');
    const s = await p.screen();
    p.assert.match(s, /^FRESH\n/);
    p.assert.doesNotMatch(s, / 50/);
  });
  t.test('graphics-mode text scrolls within SCREEN 12 (30 rows)', async (p) => {
    await p.runProgram('SCREEN 12: FOR i = 1 TO 40: PRINT i: NEXT');
    const lines = (await p.screen()).split('\n');
    p.assert.equal(lines.length, 30);
    p.assert.equal(lines[28], ' 40');
  });
};
