// Running programs: screenshot, timing (SLEEP/TIMER/ON TIMER), PC speaker (SOUND/PLAY/BEEP),
// printer (LPRINT), file I/O, CHAIN/RUN between files with COMMON, $INCLUDE and error trapping.
import { startProgram, stopAll, captureDownloads, downloads, frame } from './40-run-helpers.mjs';

const DIR = 'C:\\MYPROGS\\';
const readFile = (p, path) => p.ev(`(() => { try { return String.fromCharCode(...RC.app.vfs.readFile(${JSON.stringify(path)})); } catch (e) { return null; } })()`);
const exists = (p, path) => p.ev(`RC.app.vfs.exists(${JSON.stringify(path)})`);
const writeFile = (p, path, text) => p.ev(`RC.app.vfs.writeFile(${JSON.stringify(path)}, RC.app.encodeText(${JSON.stringify(text)}), {trusted: true})`);
const removeFile = (p, path) => p.ev(`(() => { try { if (RC.app.vfs.exists(${JSON.stringify(path)})) RC.app.vfs.unlink ? RC.app.vfs.unlink(${JSON.stringify(path)}) : RC.app.vfs.remove(${JSON.stringify(path)}); } catch (e) {} })()`);
const num = (s, label) => { const m = new RegExp(label + '\\s*(-?[\\d.E+-]+)').exec(s); return m ? parseFloat(m[1]) : NaN; };
const audio = (p, expr) => p.ev(`(() => { const a = RC.app.runner.audio; return ${expr}; })()`);
const printerLines = (p) => p.ev('RC.app.panels.printerLines || []');

export default (t) => {
  t.beforeEach(async (p) => { await stopAll(p); });

  // ---- screenshot -------------------------------------------------------------------------------------------
  t.test('the screenshot button downloads SCREEN.PNG', async (p) => {
    await captureDownloads(p);
    await p.runProgram('SCREEN 13: LINE (0, 0)-(99, 99), 4, BF');
    await frame(p);
    await p.click('#screenActions button[title="Save screenshot (PNG)"]');
    await p.wait('window.__dl.length && window.__dl[0].done', 4000);
    const [d] = await downloads(p);
    p.assert.equal(d.name, 'SCREEN.PNG');
    p.assert.equal(d.type, 'image/png');
    p.assert.deepEqual(d.head, [137, 80, 78, 71, 13, 10, 26, 10]);
  });
  t.test('the screenshot PNG has the emulated screen resolution', async (p) => {
    await captureDownloads(p);
    await p.runProgram('SCREEN 12: CIRCLE (320, 240), 100, 14');
    await frame(p);
    await p.click('#screenActions button[title="Save screenshot (PNG)"]');
    await p.wait('window.__dl.length && window.__dl[0].done', 4000);
    const [d] = await downloads(p);
    p.assert.equal(d.w, 640);
    p.assert.equal(d.h, 480);
  });
  t.test('the screenshot of text mode is 640x400', async (p) => {
    await captureDownloads(p);
    await p.runProgram('PRINT "SHOT"');
    await p.click('#screenActions button[title="Save screenshot (PNG)"]');
    await p.wait('window.__dl.length && window.__dl[0].done', 4000);
    const [d] = await downloads(p);
    p.assert.deepEqual([d.w, d.h], [640, 400]);
    p.assert.ok(d.size > 100);
  });

  // ---- SLEEP and TIMER ----------------------------------------------------------------------------------------
  t.test('SLEEP 1 pauses for about one second', async (p) => {
    const t0 = Date.now();
    await p.runProgram('t! = TIMER: SLEEP 1: PRINT "DT"; TIMER - t!');
    const wall = Date.now() - t0;
    const dt = num(await p.screen(), 'DT');
    p.assert.ok(dt >= 0.9 && dt < 1.8, 'dt ' + dt);
    p.assert.ok(wall >= 900, 'wall ' + wall);
  });
  t.test('the program is in the waiting state during SLEEP', async (p) => {
    await startProgram(p, 'SLEEP 2: PRINT "WOKE"');
    await p.sleep(300);
    p.assert.equal(await p.state(), 'waiting');
    await p.waitState('ended', 4000);
    p.assert.match(await p.screen(), /WOKE/);
  });
  t.test('a key press ends SLEEP early', async (p) => {
    await startProgram(p, 't! = TIMER: SLEEP 10: PRINT "DT"; TIMER - t!');
    await p.sleep(300);
    await p.key('x');
    await p.waitState('ended', 3000);
    const dt = num(await p.screen(), 'DT');
    p.assert.ok(dt < 2, 'dt ' + dt);
  });
  t.test('SLEEP with no argument waits for a key', async (p) => {
    await startProgram(p, 'SLEEP: PRINT "KEYED"');
    await p.sleep(600);
    p.assert.equal(await p.state(), 'waiting');
    await p.key(' ');
    await p.waitState('ended', 3000);
    p.assert.match(await p.screen(), /KEYED/);
  });
  t.test('TIMER returns seconds since midnight', async (p) => {
    await p.runProgram('PRINT "T"; TIMER');
    const tm = num(await p.screen(), 'T');
    const js = await p.ev('(() => { const d = new Date(); return d.getHours() * 3600 + d.getMinutes() * 60 + d.getSeconds() + d.getMilliseconds() / 1000; })()');
    p.assert.ok(Math.abs(js - tm) < 3, `${tm} vs ${js}`);
  });
  t.test('a TIMER busy-wait loop of 0.5 s takes real time', async (p) => {
    const t0 = Date.now();
    await p.runProgram('t! = TIMER: DO: LOOP UNTIL TIMER - t! >= .5: PRINT "OK"');
    p.assert.ok(Date.now() - t0 >= 450);
    p.assert.match(await p.screen(), /OK/);
  });
  t.test('ON TIMER(1) GOSUB fires about once a second', async (p) => {
    await p.runProgram('ON TIMER(1) GOSUB tick: TIMER ON\nt! = TIMER: DO: LOOP UNTIL TIMER - t! >= 2.5\nPRINT "TICKS"; n: END\ntick: n = n + 1: RETURN', { timeout: 6000 });
    p.assert.equal(num(await p.screen(), 'TICKS'), 2);
  });
  t.test('TIMER OFF stops ON TIMER events', async (p) => {
    await p.runProgram('ON TIMER(1) GOSUB tick: TIMER ON: TIMER OFF\nt! = TIMER: DO: LOOP UNTIL TIMER - t! >= 1.5\nPRINT "TICKS"; n: END\ntick: n = n + 1: RETURN', { timeout: 6000 });
    p.assert.equal(num(await p.screen(), 'TICKS'), 0);
  });
  t.test('TIMER STOP remembers the event until TIMER ON', async (p) => {
    await p.runProgram('ON TIMER(1) GOSUB tick: TIMER ON: TIMER STOP\nt! = TIMER: DO: LOOP UNTIL TIMER - t! >= 1.3\nPRINT "A"; n: TIMER ON: PRINT "B"; n: END\ntick: n = n + 1: RETURN', { timeout: 6000 });
    const s = await p.screen();
    p.assert.equal(num(s, 'A'), 0);
    p.assert.equal(num(s, 'B'), 1);
  });
  t.test('an ON TIMER event interrupts SLEEP', async (p) => {
    await p.runProgram('ON TIMER(1) GOSUB tick: TIMER ON\nt! = TIMER: SLEEP 10: PRINT "DT"; TIMER - t!; "N"; n: END\ntick: n = n + 1: RETURN', { timeout: 6000 });
    const s = await p.screen();
    p.assert.ok(num(s, 'DT') < 2.5, s);
    p.assert.equal(num(s, 'N'), 1);
  });
  t.test('an ON TIMER event during INPUT is handled after INPUT completes', async (p) => {
    await startProgram(p, 'ON TIMER(1) GOSUB tick: TIMER ON\nINPUT a$: PRINT "N"; n: END\ntick: n = n + 1: LOCATE 10, 1: PRINT "TICK"; n: RETURN');
    await p.sleep(1400);
    p.assert.doesNotMatch(await p.screen(), /TICK/);
    p.assert.equal(await p.state(), 'waiting');
    await p.type('x\n');
    await p.waitState('ended');
    const s = await p.screen();
    p.assert.match(s, /TICK 1/);
    p.assert.match(s, /N 1/);
  });

  // ---- SOUND / PLAY / BEEP -------------------------------------------------------------------------------------
  t.test('SOUND schedules a note on the audio timeline', async (p) => {
    await p.runProgram('SOUND 440, 36.4');
    const n = await audio(p, '({ q: a.notesQueued(), freq: a.notes[0] && a.notes[0].freq, dur: a.notes[0] && a.notes[0].end - a.notes[0].start, left: a.endTime - performance.now() })');
    p.assert.equal(n.q, 1);
    p.assert.equal(n.freq, 440);
    p.assert.ok(Math.abs(n.dur - 2000) < 5, 'dur ' + n.dur);
    p.assert.ok(n.left > 1000, 'left ' + n.left);
  });
  t.test('SOUND duration is measured in clock ticks (18.2 per second)', async (p) => {
    await p.runProgram('SOUND 1000, 9.1');
    const dur = await audio(p, 'a.notes[0].end - a.notes[0].start');
    p.assert.ok(Math.abs(dur - 500) < 3, 'dur ' + dur);
  });
  t.test('BEEP schedules an 800 Hz quarter-second tone', async (p) => {
    await p.runProgram('BEEP');
    const n = await audio(p, '({ q: a.notesQueued(), f: a.notes[0].freq, d: a.notes[0].end - a.notes[0].start })');
    p.assert.deepEqual(n, { q: 1, f: 800, d: 250 });
  });
  t.test('PRINT CHR$(7) beeps', async (p) => {
    await p.runProgram('PRINT CHR$(7);');
    p.assert.equal(await audio(p, 'a.notes.length && a.notes[0].freq'), 800);
  });
  t.test('PLAY "MB" queues all notes and lets the program continue', async (p) => {
    await p.runProgram('t! = TIMER: PLAY "MB T120 L2 CDE": PRINT "DT"; TIMER - t!');
    p.assert.ok(num(await p.screen(), 'DT') < 0.3);
    p.assert.equal(await audio(p, 'a.notesQueued()'), 3);
    p.assert.ok(await audio(p, 'a.endTime - performance.now()') > 1500);
  });
  t.test('PLAY "MF" blocks until the music has finished', async (p) => {
    await p.runProgram('t! = TIMER: PLAY "MF T120 L4 CDE": PRINT "DT"; TIMER - t!', { timeout: 6000 });
    const dt = num(await p.screen(), 'DT');
    p.assert.ok(dt >= 1.3 && dt < 2.5, 'dt ' + dt);
    p.assert.ok(await audio(p, 'a.endTime - performance.now()') < 200);
  });
  t.test('the program stays in the waiting state while MF music plays', async (p) => {
    await startProgram(p, 'PLAY "MF T120 L2 CDE": PRINT "END"');
    await p.sleep(300);
    p.assert.equal(await p.state(), 'waiting');
    await p.waitState('ended', 6000);
  });
  t.test('PLAY "O3 A" is 440 Hz and O4 A is 880 Hz', async (p) => {
    await p.runProgram('PLAY "MB O3 A O4 A"');
    const f = await audio(p, 'a.notes.map(n => Math.round(n.freq))');
    p.assert.deepEqual(f, [440, 880]);
  });
  t.test('PLAY tempo and length set the note duration', async (p) => {
    await p.runProgram('PLAY "MB T120 L4 C L8 C C."');
    const d = await audio(p, 'a.notes.map(n => Math.round(n.end - n.start))');
    p.assert.deepEqual(d, [500, 250, 375]);
  });
  t.test('PLAY P4 schedules a silent rest', async (p) => {
    await p.runProgram('PLAY "MB T120 C P4 C"');
    const f = await audio(p, 'a.notes.map(n => n.freq)');
    p.assert.equal(f.length, 3);
    p.assert.equal(f[1], 0);
  });
  t.test('PLAY sharps and octave changes adjust the pitch', async (p) => {
    await p.runProgram('PLAY "MB O2 C C# > C"');
    const f = await audio(p, 'a.notes.map(n => n.freq)');
    p.assert.ok(Math.abs(f[1] / f[0] - Math.pow(2, 1 / 12)) < 1e-6);
    p.assert.ok(Math.abs(f[2] / f[0] - 2) < 1e-6);
  });
  t.test('PLAY with an invalid command is an Illegal function call', async (p) => {
    await p.runProgram('PLAY "MB Z"');
    p.assert.equal(await p.state(), 'error');
    p.assert.match(await p.status(), /Runtime error 5/);
  });
  t.test('ON PLAY(n) refills the background music queue', async (p) => {
    await p.runProgram('ON PLAY(2) GOSUB more: PLAY ON\nPLAY "MB T255 L32 CDEF"\nt! = TIMER: DO: LOOP UNTIL TIMER - t! >= 1.2\nPRINT "REFILLS"; n: END\nmore: n = n + 1: IF n < 3 THEN PLAY "MB L32 CDEF"\nRETURN', { timeout: 6000 });
    p.assert.ok(num(await p.screen(), 'REFILLS') >= 1);
  });
  t.test('PLAY(0) returns the number of queued background notes', async (p) => {
    await p.runProgram('PLAY "MB T120 L2 CDEFG": PRINT "Q"; PLAY(0)');
    p.assert.equal(num(await p.screen(), 'Q'), 5);
  });
  t.test('stopping the program silences queued music', async (p) => {
    await startProgram(p, 'PLAY "MB T120 L2 CDEFGAB": DO: LOOP');
    p.assert.ok(await audio(p, 'a.notesQueued()') > 0);
    await p.click('#tbStop');
    await p.waitState(['ended', 'idle']);
    p.assert.equal(await audio(p, 'a.notesQueued()'), 0);
  });
  t.test('a new run clears the previous program\'s queued notes', async (p) => {
    await p.runProgram('PLAY "MB T120 L1 CDEF"');
    p.assert.ok(await audio(p, 'a.notesQueued()') > 0);
    await p.runProgram('PRINT 1');
    p.assert.equal(await audio(p, 'a.notesQueued()'), 0);
  });
  t.test('consecutive SOUND statements wait for the previous note', async (p) => {
    await p.runProgram('t! = TIMER: SOUND 500, 9.1: SOUND 600, 9.1: SOUND 700, 9.1: PRINT "DT"; TIMER - t!', { timeout: 6000 });
    const dt = num(await p.screen(), 'DT');
    p.assert.ok(dt >= 0.4 && dt < 1.5, 'dt ' + dt);
  });
  t.test('SOUND with zero duration stops the current sound', async (p) => {
    await p.runProgram('PLAY "MB L1 CDEF": SOUND 440, 0');
    p.assert.equal(await audio(p, 'a.notesQueued()'), 0);
  });

  // ---- printer -------------------------------------------------------------------------------------------
  t.test('LPRINT sends lines to the Printer panel', async (p) => {
    await p.ev("RC.app.panels.show('immediate'); RC.app.panels.printerLines = []");
    await p.runProgram('LPRINT "INVOICE"\nLPRINT "TOTAL"; 42');
    p.assert.deepEqual(await printerLines(p), ['INVOICE', 'TOTAL 42 ']);
    p.assert.equal(await p.text('.tab[data-id="printer"] .count'), '2');
    await p.click('.tab[data-id="printer"]');
    p.assert.match(await p.panelText(), /INVOICE\s+TOTAL 42/);
    p.assert.equal(await p.exists('.tab[data-id="printer"] .count'), true);
  });
  t.test('LPRINT does not print on the output screen', async (p) => {
    await p.runProgram('LPRINT "PAPER ONLY": PRINT "SCREEN"');
    p.assert.doesNotMatch(await p.screen(), /PAPER/);
    p.assert.ok((await printerLines(p)).includes('PAPER ONLY'));
  });
  t.test('LPRINT with a trailing semicolon continues the same printer line', async (p) => {
    await p.ev('RC.app.panels.printerLines = []');
    await p.runProgram('LPRINT "A";: LPRINT "B";: LPRINT "C"');
    p.assert.deepEqual(await printerLines(p), ['ABC']);
  });
  t.test('LPRINT USING formats numbers on the printer', async (p) => {
    await p.ev('RC.app.panels.printerLines = []');
    await p.runProgram('LPRINT USING "##.##"; 3.14159');
    p.assert.deepEqual(await printerLines(p), [' 3.14']);
  });
  t.test('the Printer panel shows output live while the panel is open', async (p) => {
    await p.panel('printer');
    await p.click('.bpanel.active .small-btn', 'Clear');
    await p.runProgram('LPRINT "LIVE 1"');
    p.assert.match(await p.text('.bpanel.active .printer'), /^LIVE 1$/);
  });
  t.test('the Printer Clear button empties the printer output', async (p) => {
    await p.runProgram('LPRINT "TO CLEAR"');
    await p.panel('printer');
    p.assert.match(await p.text('.bpanel.active .printer'), /TO CLEAR/);
    await p.click('.bpanel.active .small-btn', 'Clear');
    p.assert.equal(await p.text('.bpanel.active .printer'), '');
    p.assert.deepEqual(await printerLines(p), []);
    p.assert.equal(await p.exists('.tab[data-id="printer"] .count'), false);
  });
  t.test('the Printer Save button downloads LPT1.TXT with CRLF lines', async (p) => {
    await p.panel('printer');
    await p.click('.bpanel.active .small-btn', 'Clear');
    await p.runProgram('LPRINT "LINE ONE": LPRINT "LINE TWO"');
    await captureDownloads(p);
    await p.click('.bpanel.active .small-btn', 'Save');
    await p.wait('window.__dl.length && window.__dl[0].done', 4000);
    const [d] = await downloads(p);
    p.assert.equal(d.name, 'LPT1.TXT');
    p.assert.equal(d.text, 'LINE ONE\r\nLINE TWO');
  });
  t.test('View menu Printer opens the Printer panel', async (p) => {
    await p.panel('immediate');
    await p.menu('View', 'Printer');
    p.assert.equal(await p.ev('RC.app.panels.active'), 'printer');
  });
  t.test('OPEN "LPT1:" writes to the printer', async (p) => {
    await p.ev('RC.app.panels.printerLines = []');
    await p.runProgram('OPEN "LPT1:" FOR OUTPUT AS #1: PRINT #1, "VIA FILE": CLOSE #1');
    p.assert.deepEqual(await printerLines(p), ['VIA FILE']);
  });

  // ---- file I/O ------------------------------------------------------------------------------------------
  t.test('PRINT # writes a text file to the virtual disk', async (p) => {
    await removeFile(p, DIR + 'OUT.TXT');
    await p.runProgram('OPEN "OUT.TXT" FOR OUTPUT AS #1: PRINT #1, "HELLO": PRINT #1, 1 + 2: CLOSE #1');
    p.assert.equal(await p.state(), 'ended');
    p.assert.equal(await readFile(p, DIR + 'OUT.TXT'), 'HELLO\r\n 3 \r\n');
  });
  t.test('WRITE # quotes strings and separates with commas', async (p) => {
    await p.runProgram('OPEN "W.TXT" FOR OUTPUT AS #1: WRITE #1, "A", 1, "B C": CLOSE');
    p.assert.equal(await readFile(p, DIR + 'W.TXT'), '"A",1,"B C"\r\n');
  });
  t.test('a file written then read back with INPUT # round-trips', async (p) => {
    await p.runProgram('OPEN "R.TXT" FOR OUTPUT AS #1: WRITE #1, "NAME", 42: CLOSE\nOPEN "R.TXT" FOR INPUT AS #1: INPUT #1, a$, n: CLOSE: PRINT a$; n');
    p.assert.match(await p.screen(), /^NAME 42/);
  });
  t.test('APPEND adds to the end of an existing file', async (p) => {
    await writeFile(p, DIR + 'LOG.TXT', 'first\r\n');
    await p.runProgram('OPEN "LOG.TXT" FOR APPEND AS #1: PRINT #1, "second": CLOSE');
    p.assert.equal(await readFile(p, DIR + 'LOG.TXT'), 'first\r\nsecond\r\n');
  });
  t.test('LINE INPUT # with EOF reads every line of a prepared file', async (p) => {
    await writeFile(p, DIR + 'LINES.TXT', 'alpha\r\nbeta, gamma\r\ndelta\r\n');
    await p.runProgram('OPEN "LINES.TXT" FOR INPUT AS #1\nDO UNTIL EOF(1): LINE INPUT #1, l$: n = n + 1: PRINT n; l$: LOOP: CLOSE');
    const lines = (await p.screen()).split('\n');
    p.assert.deepEqual(lines.slice(0, 3), [' 1 alpha', ' 2 beta, gamma', ' 3 delta']);
  });
  t.test('LOF reports the file length', async (p) => {
    await writeFile(p, DIR + 'SIZE.TXT', '0123456789');
    await p.runProgram('OPEN "SIZE.TXT" FOR INPUT AS #1: PRINT "LEN"; LOF(1): CLOSE');
    p.assert.equal(num(await p.screen(), 'LEN'), 10);
  });
  t.test('RANDOM files store and fetch records with FIELD/PUT/GET', async (p) => {
    await removeFile(p, DIR + 'REC.DAT');
    await p.runProgram('OPEN "REC.DAT" FOR RANDOM AS #1 LEN = 10: FIELD #1, 10 AS r$\nFOR i = 1 TO 3: LSET r$ = "REC" + STR$(i): PUT #1, i: NEXT\nGET #1, 2: PRINT "[" + RTRIM$(r$) + "]"; LOF(1): CLOSE');
    p.assert.match(await p.screen(), /\[REC 2\] 30/);
  });
  t.test('BINARY files PUT and GET typed values', async (p) => {
    await removeFile(p, DIR + 'BIN.DAT');
    await p.runProgram('OPEN "BIN.DAT" FOR BINARY AS #1: x% = 1234: PUT #1, 1, x%: y% = 0: GET #1, 1, y%: PRINT "Y"; y%; LOF(1): CLOSE');
    p.assert.match(await p.screen(), /Y 1234  2/);
    p.assert.deepEqual(await p.ev(`Array.from(RC.app.vfs.readFile(${JSON.stringify(DIR + 'BIN.DAT')}))`), [0xD2, 0x04]);
  });
  t.test('KILL deletes a file', async (p) => {
    await writeFile(p, DIR + 'GONE.TXT', 'x');
    await p.runProgram('KILL "GONE.TXT": PRINT "KILLED"');
    p.assert.equal(await exists(p, DIR + 'GONE.TXT'), false);
  });
  t.test('NAME renames a file', async (p) => {
    await writeFile(p, DIR + 'OLDN.TXT', 'data');
    await removeFile(p, DIR + 'NEWN.TXT');
    await p.runProgram('NAME "OLDN.TXT" AS "NEWN.TXT"');
    p.assert.equal(await exists(p, DIR + 'OLDN.TXT'), false);
    p.assert.equal(await readFile(p, DIR + 'NEWN.TXT'), 'data');
  });
  t.test('MKDIR creates a folder and files can be written into it', async (p) => {
    await p.runProgram('MKDIR "SUBD": OPEN "SUBD\\IN.TXT" FOR OUTPUT AS #1: PRINT #1, "deep": CLOSE');
    p.assert.equal(await readFile(p, DIR + 'SUBD\\IN.TXT'), 'deep\r\n');
  });
  t.test('opening a missing file for INPUT is error 53 File not found', async (p) => {
    await p.runProgram('OPEN "NOPE.TXT" FOR INPUT AS #1');
    p.assert.equal(await p.state(), 'error');
    p.assert.match(await p.status(), /Runtime error 53: File not found/);
  });
  t.test('ON ERROR traps File not found and ERR is 53', async (p) => {
    await p.runProgram('ON ERROR GOTO h\nOPEN "NOPE.TXT" FOR INPUT AS #1\nPRINT "AFTER": END\nh: PRINT "ERR"; ERR: RESUME NEXT');
    const s = await p.screen();
    p.assert.match(s, /ERR 53/);
    p.assert.match(s, /AFTER/);
  });
  t.test('reading past the end of a file is error 62', async (p) => {
    await writeFile(p, DIR + 'SHORT.TXT', 'one\r\n');
    await p.runProgram('OPEN "SHORT.TXT" FOR INPUT AS #1: LINE INPUT #1, a$: LINE INPUT #1, b$');
    p.assert.equal(await p.state(), 'error');
    p.assert.match(await p.status(), /Runtime error 62/);
  });
  t.test('FREEFILE returns the next free file number', async (p) => {
    await p.runProgram('OPEN "F1.TXT" FOR OUTPUT AS #1: PRINT "FF"; FREEFILE: CLOSE');
    p.assert.equal(num(await p.screen(), 'FF'), 2);
  });
  t.test('FILES lists files in the program folder', async (p) => {
    await writeFile(p, DIR + 'LISTME.TXT', 'x');
    await p.runProgram('FILES "*.TXT"');
    p.assert.match(await p.screen(), /LISTME\s*\.TXT|LISTME\.TXT/);
  });
  t.test('a file written by the program can be opened in the editor', async (p) => {
    await p.runProgram('OPEN "SHOWN.TXT" FOR OUTPUT AS #1: PRINT #1, "visible text": CLOSE');
    await p.ev(`RC.app.openFile(${JSON.stringify(DIR + 'SHOWN.TXT')})`);
    await p.sleep(80);
    p.assert.match(await p.code(), /visible text/);
  });

  // ---- CHAIN / RUN "file" / COMMON ---------------------------------------------------------------------------
  t.test('CHAIN passes COMMON variables to the next program', async (p) => {
    await p.newFile(DIR + 'CH2.BAS', 'COMMON a, b$\nPRINT "IN CH2:"; a; b$');
    await p.runProgram('COMMON a, b$\na = 7: b$ = "SEVEN"\nPRINT "IN CH1"\nCHAIN "CH2"', { path: DIR + 'CH1.BAS' });
    p.assert.equal(await p.state(), 'ended');
    const s = await p.screen();
    p.assert.match(s, /IN CH1/);
    p.assert.match(s, /IN CH2: 7 SEVEN/);
    p.assert.equal(await p.ev('RC.app.runner.mainPath'), DIR + 'CH2.BAS');
  });
  t.test('CHAIN without COMMON does not pass variables', async (p) => {
    await p.newFile(DIR + 'CH4.BAS', 'PRINT "X="; x; "S=["; s$; "]"');
    await p.runProgram('x = 5: s$ = "hi": CHAIN "CH4.BAS"', { path: DIR + 'CH3.BAS' });
    p.assert.match(await p.screen(), /X= 0 S=\[\]/);
  });
  t.test('COMMON passes arrays through CHAIN', async (p) => {
    await p.newFile(DIR + 'CH6.BAS', 'COMMON v()\nPRINT "V"; v(1); v(3)');
    await p.runProgram('COMMON v()\nDIM v(3)\nv(1) = 11: v(3) = 33: CHAIN "CH6"', { path: DIR + 'CH5.BAS' });
    p.assert.match(await p.screen(), /V 11  33/);
  });
  t.test('CHAIN keeps files open for the chained program', async (p) => {
    await p.newFile(DIR + 'CH8.BAS', 'PRINT #1, "from CH8": CLOSE #1: PRINT "CLOSED"');
    await p.runProgram('OPEN "SHARED.TXT" FOR OUTPUT AS #1: PRINT #1, "from CH7": CHAIN "CH8"', { path: DIR + 'CH7.BAS' });
    p.assert.match(await p.screen(), /CLOSED/);
    p.assert.equal(await readFile(p, DIR + 'SHARED.TXT'), 'from CH7\r\nfrom CH8\r\n');
  });
  t.test('CHAIN to a line number starts the program there', async (p) => {
    await p.newFile(DIR + 'CHL.BAS', '10 PRINT "TEN"\n20 PRINT "TWENTY"');
    await p.runProgram('CHAIN "CHL", 20', { path: DIR + 'CHM.BAS' });
    const s = await p.screen();
    p.assert.doesNotMatch(s, /TEN\n/);
    p.assert.match(s, /TWENTY/);
  });
  t.test('CHAIN to a missing file is error 53', async (p) => {
    await p.runProgram('CHAIN "NOSUCH"');
    p.assert.equal(await p.state(), 'error');
    p.assert.match(await p.status(), /Runtime error 53/);
  });
  t.test('RUN "file" starts another program with fresh variables', async (p) => {
    await p.newFile(DIR + 'RUN2.BAS', 'COMMON a\nPRINT "RUN2 A="; a');
    await p.runProgram('COMMON a\na = 99: RUN "RUN2.BAS"', { path: DIR + 'RUN1.BAS' });
    p.assert.equal(await p.state(), 'ended');
    p.assert.match(await p.screen(), /RUN2 A= 0/);
    p.assert.equal(await p.ev('RC.app.runner.mainPath'), DIR + 'RUN2.BAS');
  });
  t.test('RUN "file" closes open files', async (p) => {
    await p.newFile(DIR + 'RUN4.BAS', 'PRINT #1, "x"');
    await p.runProgram('OPEN "R4.TXT" FOR OUTPUT AS #1: PRINT #1, "kept": RUN "RUN4"', { path: DIR + 'RUN3.BAS' });
    p.assert.equal(await p.state(), 'error');
    p.assert.match(await p.status(), /Runtime error 52|Bad file/);
    p.assert.equal(await readFile(p, DIR + 'R4.TXT'), 'kept\r\n');
  });
  t.test('CHAIN uses the unsaved editor text of an open file', async (p) => {
    await p.newFile(DIR + 'CHE.BAS', 'PRINT "SAVED VERSION"');
    await p.setCode('PRINT "EDITED VERSION"');
    await p.runProgram('CHAIN "CHE"', { path: DIR + 'CHD.BAS' });
    p.assert.match(await p.screen(), /EDITED VERSION/);
  });
  t.test('a runtime error in a chained program highlights that file', async (p) => {
    await p.newFile(DIR + 'CHX.BAS', 'PRINT "OK"\nx = 1 / 0');
    await p.runProgram('CHAIN "CHX"', { path: DIR + 'CHW.BAS' });
    p.assert.equal(await p.state(), 'error');
    p.assert.equal(await p.activePath(), DIR + 'CHX.BAS');
    p.assert.equal(await p.ev('RC.app.active.editor.marks.err'), 1);
  });

  // ---- $INCLUDE --------------------------------------------------------------------------------------------
  t.test('$INCLUDE pulls SUBs and CONSTs from another file', async (p) => {
    await p.newFile(DIR + 'LIB.BI', "CONST GREETING = \"HI FROM LIB\"\nSUB Shout (s$)\nPRINT UCASE$(s$)\nEND SUB");
    await p.runProgram("'$INCLUDE: 'LIB.BI'\nPRINT GREETING\nShout \"quiet\"", { path: DIR + 'INCMAIN.BAS' });
    p.assert.equal(await p.state(), 'ended');
    const s = await p.screen();
    p.assert.match(s, /HI FROM LIB/);
    p.assert.match(s, /QUIET/);
  });
  t.test('REM $INCLUDE also works', async (p) => {
    await p.newFile(DIR + 'LIB2.BI', 'FUNCTION Twice (n)\nTwice = n * 2\nEND FUNCTION');
    await p.runProgram("REM $INCLUDE: 'LIB2.BI'\nPRINT \"T\"; Twice(21)", { path: DIR + 'INC2.BAS' });
    p.assert.match(await p.screen(), /T 42/);
  });
  t.test('a missing $INCLUDE file is reported as a compile error', async (p) => {
    await p.runProgram("'$INCLUDE: 'MISSING.BI'\nPRINT 1", { path: DIR + 'INC3.BAS', wait: false });
    await p.sleep(200);
    p.assert.notEqual(await p.state(), 'running');
    p.assert.match(await p.status(), /MISSING\.BI|include/i);
  });
  t.test('a runtime error inside an included SUB highlights the include file line', async (p) => {
    await p.newFile(DIR + 'BAD.BI', "SUB Boom\nPRINT \"in boom\"\nx = 1 / 0\nEND SUB");
    await p.runProgram("'$INCLUDE: 'BAD.BI'\nBoom", { path: DIR + 'INC4.BAS' });
    p.assert.equal(await p.state(), 'error');
    p.assert.equal(await p.activePath(), DIR + 'BAD.BI');
    p.assert.equal(await p.ev('RC.app.active.editor.marks.err'), 2);
  });

  // ---- error trapping and runtime errors -------------------------------------------------------------------------
  t.test('ON ERROR GOTO with RESUME NEXT continues after the error', async (p) => {
    await p.runProgram('ON ERROR GOTO h\nx = 1 / 0\nPRINT "CONTINUED"\nEND\nh: PRINT "CAUGHT"; ERR: RESUME NEXT');
    const s = await p.screen();
    p.assert.match(s, /CAUGHT 11\nCONTINUED/);
    p.assert.equal(await p.state(), 'ended');
  });
  t.test('ERL reports the line number of the error', async (p) => {
    await p.runProgram('10 ON ERROR GOTO 100\n20 PRINT "A"\n30 ERROR 5\n40 END\n100 PRINT "ERL"; ERL; "ERR"; ERR: RESUME 40');
    p.assert.match(await p.screen(), /ERL 30 ERR 5/);
  });
  t.test('RESUME label jumps to the label after the handler', async (p) => {
    await p.runProgram('ON ERROR GOTO h\nERROR 7\nPRINT "SKIPPED"\nfin: PRINT "FIN": END\nh: RESUME fin');
    const s = await p.screen();
    p.assert.doesNotMatch(s, /SKIPPED/);
    p.assert.match(s, /FIN/);
  });
  t.test('ERROR with a user code is trapped with that code', async (p) => {
    await p.runProgram('ON ERROR GOTO h\nERROR 200\nEND\nh: PRINT "CODE"; ERR: RESUME NEXT');
    p.assert.match(await p.screen(), /CODE 200/);
  });
  t.test('an untrapped error stops the program and reports it in the status bar', async (p) => {
    await p.runProgram('PRINT "BEFORE"\nx = 1 / 0\nPRINT "NEVER"');
    p.assert.equal(await p.state(), 'error');
    p.assert.match(await p.status(), /Runtime error 11: Division by zero/);
    const s = await p.screen();
    p.assert.match(s, /BEFORE/);
    p.assert.doesNotMatch(s, /NEVER/);
  });
  t.test('an untrapped error shows a toast and logs in the Immediate panel', async (p) => {
    await p.runProgram('DIM a(5): a(10) = 1');
    await p.waitToast(/Runtime error/);
    p.assert.match(await p.lastToast(), /Subscript out of range/);
    p.assert.equal(await p.ev('RC.app.panels.active'), 'immediate');
    p.assert.match(await p.panelText(), /Runtime error 9: Subscript out of range/);
  });
  t.test('the error line is highlighted in the editor', async (p) => {
    await p.runProgram('PRINT 1\nPRINT 2\nx = 1 / 0\nPRINT 4');
    p.assert.equal(await p.ev('RC.app.active.editor.marks.err'), 2);
    await p.sleep(50);
    p.assert.equal(await p.count('.errline'), 1);
    p.assert.match(await p.text('.errline'), /x = 1 \/ 0/);
  });
  t.test('a runtime error inside a SUB highlights the line in the SUB', async (p) => {
    await p.runProgram('DECLARE SUB Fail (n)\nPRINT "MAIN"\nFail 0\nPRINT "UNREACHED"\n\nSUB Fail (n)\n  PRINT "IN SUB"\n  y = 10 / n\nEND SUB');
    p.assert.equal(await p.state(), 'error');
    p.assert.equal(await p.ev('RC.app.active.editor.marks.err'), 7);
    await p.sleep(50);
    p.assert.match(await p.text('.errline'), /y = 10 \/ n/);
    p.assert.match(await p.status(), /Division by zero/);
  });
  t.test('a runtime error inside a FUNCTION highlights the line in the FUNCTION', async (p) => {
    await p.runProgram('PRINT Root(-4)\n\nFUNCTION Root (x)\n  Root = SQR(x)\nEND FUNCTION');
    p.assert.equal(await p.state(), 'error');
    p.assert.equal(await p.ev('RC.app.active.editor.marks.err'), 3);
    p.assert.match(await p.status(), /Illegal function call/);
  });
  t.test('an error in a SUB is caught by the module-level ON ERROR handler', async (p) => {
    await p.runProgram('ON ERROR GOTO h\nBoom\nPRINT "BACK"\nEND\nh: PRINT "HANDLED"; ERR: RESUME NEXT\n\nSUB Boom\n  ERROR 6\nEND SUB');
    const s = await p.screen();
    p.assert.match(s, /HANDLED 6/);
    p.assert.match(s, /BACK/);
  });
  t.test('a runtime error with line numbers names the line in the status bar', async (p) => {
    await p.runProgram('10 PRINT "X"\n20 GOSUB 100\n30 END\n100 y = LOG(0)\n110 RETURN');
    p.assert.match(await p.status(), /Illegal function call in line 100/);
  });
  t.test('the Problems tab counts the runtime error', async (p) => {
    await p.runProgram('ERROR 13');
    p.assert.equal(await p.text('.tab[data-id="problems"] .count'), '1');
  });
  t.test('running again clears the previous error highlight', async (p) => {
    await p.runProgram('x = 1 / 0');
    p.assert.equal(await p.ev('RC.app.active.editor.marks.err'), 0);
    await p.runProgram('x = 1');
    p.assert.equal(await p.ev('RC.app.active.editor.marks.err'), null);
    p.assert.doesNotMatch(await p.status(), /Runtime error/);
  });
  t.test('ON ERROR GOTO 0 inside the handler stops with the original error', async (p) => {
    await p.runProgram('ON ERROR GOTO h\nERROR 61\nEND\nh: ON ERROR GOTO 0');
    p.assert.equal(await p.state(), 'error');
    p.assert.match(await p.status(), /Runtime error 61/);
  });
  t.test('a program that ends normally reports so in the status bar', async (p) => {
    await p.runProgram('PRINT "BYE"');
    p.assert.match(await p.status(), /Program ended/);
  });
  t.test('STOP pauses the program with a STOP statement message', async (p) => {
    await p.runProgram('PRINT "A": STOP: PRINT "B"');
    p.assert.equal(await p.state(), 'paused');
    p.assert.match(await p.status(), /STOP statement/);
  });
};
