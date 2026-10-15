// GW-BASIC classic console, part C: full-screen editing keys, wrapped logical lines,
// function keys F1-F10, Ctrl+C / Ctrl+Break and pasting into the console.
import { enter, rows, row, cur, prog, progLines, idle, waitOk, cmd, line, out, clear, typeProgram, paste, writeFile } from './60-console-lib.mjs';

const at = async (p) => { const c = await cur(p); return [c.row, c.col]; };

export default (t) => {
  t.beforeEach(async (p) => { await p.fresh(); await enter(p); await clear(p); });

  // ---- cursor movement ------------------------------------------------------------------------------------------
  t.test('ArrowUp and ArrowDown move the cursor between rows', async (p) => {
    await p.type('ABC');
    p.assert.deepEqual(await at(p), [0, 3]);
    await p.key('ArrowDown');
    await p.key('ArrowDown');
    p.assert.deepEqual(await at(p), [2, 3]);
    await p.key('ArrowUp');
    p.assert.deepEqual(await at(p), [1, 3]);
  });

  t.test('ArrowLeft and ArrowRight move the cursor along the row', async (p) => {
    await p.type('HELLO');
    await p.key('ArrowLeft');
    await p.key('ArrowLeft');
    p.assert.deepEqual(await at(p), [0, 3]);
    await p.key('ArrowRight');
    p.assert.deepEqual(await at(p), [0, 4]);
  });

  t.test('ArrowLeft at column 0 wraps to the end of the previous row', async (p) => {
    await p.key('ArrowDown');
    await p.key('ArrowLeft');
    p.assert.deepEqual(await at(p), [0, 79]);
  });

  t.test('ArrowRight at column 80 wraps to the next row', async (p) => {
    await p.key('End'); // empty line: stays at col 0
    for (let i = 0; i < 79; i++) await p.key('ArrowRight', { after: 0 });
    p.assert.deepEqual(await at(p), [0, 79]);
    await p.key('ArrowRight');
    p.assert.deepEqual(await at(p), [1, 0]);
  });

  t.test('ArrowUp at the top row stays on row 1', async (p) => {
    await p.key('ArrowUp');
    p.assert.deepEqual(await at(p), [0, 0]);
  });

  t.test('ArrowDown never enters the KEY line on row 25', async (p) => {
    for (let i = 0; i < 30; i++) await p.key('ArrowDown', { after: 0 });
    p.assert.deepEqual(await at(p), [23, 0]);
    p.assert.match(await row(p, 24), /^1LIST/);
  });

  t.test('cursor keys can reach text anywhere on the screen', async (p) => {
    await cmd(p, 'PRINT "TARGET"');
    // cursor is now on row 3; TARGET is on row 1
    await p.key('ArrowUp'); await p.key('ArrowUp');
    for (let i = 0; i < 3; i++) await p.key('ArrowRight');
    p.assert.deepEqual(await at(p), [1, 3]);
    p.assert.equal((await row(p, 1))[3], 'G');
  });

  t.test('Home moves the cursor to the top-left corner', async (p) => {
    await cmd(p, 'PRINT 1');
    await p.type('XYZ');
    await p.key('Home');
    p.assert.deepEqual(await at(p), [0, 0]);
  });

  t.test('End moves the cursor after the last character of the line', async (p) => {
    await p.type('PRINT "END"');
    await p.key('ArrowLeft'); await p.key('ArrowLeft'); await p.key('ArrowLeft'); await p.key('ArrowLeft');
    await p.key('End');
    p.assert.deepEqual(await at(p), [0, 11]);
  });

  t.test('Ctrl+Left and Ctrl+Right jump between words', async (p) => {
    await p.type('PRINT "one two three"');
    await p.key('ArrowLeft', { ctrl: true });
    p.assert.equal((await cur(p)).col, 15);
    await p.key('ArrowLeft', { ctrl: true });
    p.assert.equal((await cur(p)).col, 11);
    await p.key('ArrowRight', { ctrl: true });
    p.assert.equal((await cur(p)).col, 15);
  });

  // ---- full-screen editing ------------------------------------------------------------------------------------------
  t.test('overtyping a LISTed line and pressing Enter changes the program', async (p) => {
    await typeProgram(p, ['10 PRINT "A"', '20 PRINT "B"']);
    await clear(p);
    await cmd(p, 'LIST');
    // rows: 0 LIST, 1 "10 PRINT "A"", 2 "20 PRINT "B"", 3 Ok, cursor row 4
    for (let i = 0; i < 3; i++) await p.key('ArrowUp');
    for (let i = 0; i < 10; i++) await p.key('ArrowRight', { after: 0 });
    await p.type('Q\n');
    p.assert.deepEqual(await progLines(p), ['10 PRINT "Q"', '20 PRINT "B"']);
    p.assert.deepEqual(await at(p), [2, 0], 'Enter moves to the next row');
  });

  t.test('changing the line number of a listed line copies the line', async (p) => {
    await line(p, '10 PRINT "COPY"');
    await clear(p);
    await cmd(p, 'LIST');
    await p.key('ArrowUp'); await p.key('ArrowUp');
    await p.type('3');
    await p.key('Enter');
    p.assert.deepEqual(await progLines(p), ['10 PRINT "COPY"', '30 PRINT "COPY"']);
  });

  t.test('Enter in the middle of an unchanged line reads the whole line', async (p) => {
    await p.type('PRINT 12+30');
    for (let i = 0; i < 6; i++) await p.key('ArrowLeft');
    await p.key('Enter');
    await idle(p);
    await waitOk(p);
    p.assert.deepEqual(await out(p, 'PRINT 12+30'), [' 42']);
  });

  t.test('re-executing a direct command already on screen by moving up and pressing Enter', async (p) => {
    await cmd(p, 'PRINT "AGAIN"');
    await p.key('ArrowUp'); await p.key('ArrowUp'); await p.key('ArrowUp');
    p.assert.deepEqual(await at(p), [0, 0]);
    await p.key('Enter');
    await idle(p);
    await waitOk(p);
    const L = await rows(p);
    p.assert.deepEqual(L.slice(0, 3), ['PRINT "AGAIN"', 'AGAIN', 'Ok']);
  });

  t.test('Insert mode inserts characters and shifts the rest right', async (p) => {
    await p.type('PRINT 15');
    await p.key('ArrowLeft');
    await p.key('Insert');
    p.assert.equal(await p.ev('RC.app.console.insert'), true);
    await p.type('2');
    p.assert.equal(await row(p, 0), 'PRINT 125');
    await p.key('Enter');
    await idle(p); await waitOk(p);
    p.assert.deepEqual(await out(p, 'PRINT 125'), [' 125']);
  });

  t.test('pressing Insert again returns to overwrite mode', async (p) => {
    await p.type('ABCD');
    await p.key('Home');
    await p.key('Insert');
    await p.type('X');
    await p.key('Insert');
    p.assert.equal(await p.ev('RC.app.console.insert'), false);
    await p.type('Y');
    p.assert.equal(await row(p, 0), 'XYBCD');
  });

  t.test('inserting into a LISTed program line updates the program', async (p) => {
    await line(p, '10 PRINT "AC"');
    await clear(p);
    await cmd(p, 'LIST');
    await p.key('ArrowUp'); await p.key('ArrowUp');
    for (let i = 0; i < 11; i++) await p.key('ArrowRight', { after: 0 });
    await p.key('Insert');
    await p.type('B\n');
    p.assert.deepEqual(await progLines(p), ['10 PRINT "ABC"']);
  });

  t.test('Backspace deletes the character left of the cursor', async (p) => {
    await p.type('PRINT 123');
    await p.key('ArrowLeft');
    await p.key('Backspace');
    p.assert.equal(await row(p, 0), 'PRINT 13');
    p.assert.deepEqual(await at(p), [0, 7]);
  });

  t.test('Backspace at column 0 of an ordinary row does nothing', async (p) => {
    await cmd(p, 'PRINT 1');
    const before = await rows(p);
    await p.key('Backspace');
    p.assert.deepEqual(await rows(p), before);
    p.assert.equal((await cur(p)).col, 0);
  });

  t.test('Delete removes the character under the cursor', async (p) => {
    await p.type('PRINT 123');
    await p.key('ArrowLeft'); await p.key('ArrowLeft');
    await p.key('Delete');
    p.assert.equal(await row(p, 0), 'PRINT 13');
    p.assert.deepEqual(await at(p), [0, 7]);
  });

  t.test('Ctrl+End erases from the cursor to the end of the line', async (p) => {
    await p.type('PRINT 1:PRINT 2');
    for (let i = 0; i < 8; i++) await p.key('ArrowLeft');
    await p.key('End', { ctrl: true });
    p.assert.equal(await row(p, 0), 'PRINT 1');
    await p.key('Enter');
    await idle(p); await waitOk(p);
    p.assert.deepEqual(await out(p, 'PRINT 1'), [' 1']);
  });

  t.test('Ctrl+E also erases to the end of the line', async (p) => {
    await p.type('ABCDEF');
    await p.key('ArrowLeft'); await p.key('ArrowLeft');
    await p.key('e', { ctrl: true });
    p.assert.equal(await row(p, 0), 'ABCD');
  });

  t.test('Escape erases the whole current line', async (p) => {
    await p.type('PRINT "GONE"');
    await p.key('ArrowLeft'); await p.key('ArrowLeft');
    await p.key('Escape');
    p.assert.equal(await row(p, 0), '');
    p.assert.deepEqual(await at(p), [0, 0]);
  });

  t.test('Enter after Escape executes nothing', async (p) => {
    await p.type('10 PRINT "NO"');
    await p.key('Escape');
    await p.key('Enter');
    p.assert.equal(await prog(p), '');
    p.assert.deepEqual(await at(p), [1, 0]);
    p.assert.equal(await row(p, 0), '');
  });

  t.test('Escape on a wrapped line erases all its rows', async (p) => {
    await p.type('PRINT "' + 'W'.repeat(90) + '"');
    p.assert.equal((await cur(p)).row, 1);
    await p.key('Escape');
    p.assert.equal(await row(p, 0), '');
    p.assert.equal(await row(p, 1), '');
    p.assert.deepEqual(await at(p), [0, 0]);
  });

  t.test('Ctrl+Home clears the screen but keeps the KEY line', async (p) => {
    await cmd(p, 'PRINT "SOMETHING"');
    await p.key('Home', { ctrl: true });
    const L = await rows(p);
    p.assert.ok(L.slice(0, 24).every((s) => s === ''));
    p.assert.match(L[24], /^1LIST/);
    p.assert.deepEqual(await at(p), [0, 0]);
  });

  t.test('Ctrl+L clears the screen', async (p) => {
    await cmd(p, 'PRINT "SOMETHING"');
    await p.key('l', { ctrl: true });
    p.assert.doesNotMatch(await p.screen(), /SOMETHING/);
    p.assert.deepEqual(await at(p), [0, 0]);
  });

  t.test('Tab advances to the next 8-column stop', async (p) => {
    await p.key('Tab');
    p.assert.equal((await cur(p)).col, 8);
    await p.type('AB');
    await p.key('Tab');
    p.assert.equal((await cur(p)).col, 16);
    await p.type('C');
    p.assert.equal(await row(p, 0), '        AB      C');
  });

  t.test('Tab-indented direct statement still executes', async (p) => {
    await p.key('Tab');
    await p.type('PRINT 9\n');
    await idle(p); await waitOk(p);
    p.assert.deepEqual(await out(p, '        PRINT 9'), [' 9']);
  });

  // ---- wrapped logical lines ------------------------------------------------------------------------------------------
  t.test('typing past column 80 continues on the next row', async (p) => {
    await p.type('X'.repeat(85));
    p.assert.equal(await row(p, 0), 'X'.repeat(80));
    p.assert.equal(await row(p, 1), 'XXXXX');
    p.assert.deepEqual(await at(p), [1, 5]);
  });

  t.test('a wrapped direct statement executes as one logical line', async (p) => {
    const s = 'PRINT "' + 'A'.repeat(50) + '";"' + 'B'.repeat(40) + '"';
    await p.type(s + '\n');
    await idle(p); await waitOk(p);
    const L = await rows(p);
    p.assert.equal(L[2], 'A'.repeat(50) + 'B'.repeat(30));
    p.assert.equal(L[3], 'B'.repeat(10));
    p.assert.equal(L[4], 'Ok');
  });

  t.test('a wrapped numbered line is stored as a single program line', async (p) => {
    const content = 'PRINT "' + 'L'.repeat(85) + '"';
    await line(p, '10 ' + content);
    p.assert.deepEqual(await progLines(p), ['10 ' + content]);
    p.assert.deepEqual(await at(p), [2, 0]);
  });

  t.test('Enter on the second row of a wrapped line reads the whole logical line', async (p) => {
    const content = 'REM ' + 'Q'.repeat(85);
    await p.type('20 ' + content);
    await p.key('ArrowUp');
    await p.key('Enter');
    p.assert.deepEqual(await progLines(p), ['20 ' + content]);
  });

  t.test('Backspace at the start of a continuation row deletes the last character of the row above', async (p) => {
    await p.type('Y'.repeat(79) + 'Z' + 'W');
    await p.key('ArrowLeft');
    p.assert.deepEqual(await at(p), [1, 0]);
    await p.key('Backspace');
    p.assert.equal(await row(p, 0), 'Y'.repeat(79));
    p.assert.deepEqual(await at(p), [0, 79]);
  });

  t.test('End on a wrapped line goes to the end of its last row', async (p) => {
    await p.type('K'.repeat(90));
    await p.key('Home');
    await p.key('End');
    p.assert.deepEqual(await at(p), [1, 10]);
  });

  // ---- function keys ------------------------------------------------------------------------------------------------------
  t.test('F1 types "LIST " without executing it', async (p) => {
    await p.key('F1');
    p.assert.equal(await row(p, 0), 'LIST');
    p.assert.deepEqual(await at(p), [0, 5]);
  });

  t.test('F1 followed by a line number and Enter lists that line', async (p) => {
    await typeProgram(p, ['10 PRINT "A"', '20 PRINT "B"']);
    await p.key('F1');
    await p.type('20\n');
    await waitOk(p);
    p.assert.deepEqual(await out(p, 'LIST 20'), ['20 PRINT "B"']);
  });

  t.test('F2 runs the program', async (p) => {
    await line(p, '10 PRINT "F2 RAN"');
    await p.key('F2');
    await idle(p); await waitOk(p);
    p.assert.deepEqual(await out(p, 'RUN'), ['F2 RAN']);
  });

  t.test('F3 types LOAD" and a name completes the command', async (p) => {
    await cmd(p, 'CHDIR "C:\\"');
    await writeFile(p, 'C:\\FKEY.BAS', '10 PRINT "VIA F3"\n');
    await p.key('F3');
    p.assert.equal(await row(p, (await cur(p)).row), 'LOAD"');
    await p.type('FKEY\n');
    await waitOk(p);
    p.assert.deepEqual(await progLines(p), ['10 PRINT "VIA F3"']);
  });

  t.test('F4 in the console types its soft key SAVE" (GW-BASIC) instead of an IDE action', async (p) => {
    await p.key('F4');
    p.assert.equal(await p.ev("document.getElementById('app').classList.contains('screen-max')"), false, 'no IDE full-size toggle');
    p.assert.equal(await p.ev("RC.app.runner.display.textLines().map(s => RC.fromCP437(s, false)).some(l => /^SAVE\"\\s*$/.test(l.trimEnd()))"), true, 'SAVE" typed on the screen');
    await p.key('Escape');
  });

  t.test('F5 types CONT and executes it', async (p) => {
    await p.key('F5');
    await waitOk(p);
    p.assert.deepEqual(await out(p, 'CONT'), ["Can't continue"]);
  });

  t.test('F5 continues a program stopped with STOP', async (p) => {
    await typeProgram(p, ['10 STOP', '20 PRINT "RESUMED"']);
    await cmd(p, 'RUN');
    await p.key('F5');
    await idle(p); await waitOk(p);
    p.assert.deepEqual(await out(p, 'CONT'), ['RESUMED']);
  });

  t.test('F6 types ,"LPT1:" and presses Enter', async (p) => {
    await p.key('F6');
    await waitOk(p);
    p.assert.equal(await row(p, 0), ',"LPT1:"');
  });

  t.test('F7 executes TRON and F8 executes TROFF', async (p) => {
    await p.key('F7');
    await waitOk(p);
    p.assert.deepEqual((await rows(p)).slice(0, 2), ['TRON', 'Ok']);
    await p.key('F8');
    await waitOk(p);
    p.assert.deepEqual((await rows(p)).slice(2, 4), ['TROFF', 'Ok']);
  });

  t.test('F9 types "KEY "', async (p) => {
    await p.key('F9');
    p.assert.equal(await row(p, 0), 'KEY');
    p.assert.deepEqual(await at(p), [0, 4]);
  });

  t.test('F10 executes SCREEN 0,0,0', async (p) => {
    await cmd(p, 'SCREEN 1');
    await p.key('F10');
    await idle(p); await waitOk(p);
    p.assert.equal(await p.ev('RC.app.runner.display.mode'), 0);
  });

  t.test('function-key text is inserted at the cursor in Insert mode', async (p) => {
    await typeProgram(p, ['10 PRINT 1']);
    await clear(p);
    await p.type('10');
    await p.key('Home');
    await p.key('Insert');
    await p.key('F1');
    p.assert.equal(await row(p, 0), 'LIST 10');
    await p.key('Enter');
    await waitOk(p);
    p.assert.deepEqual(await out(p, 'LIST 10'), ['10 PRINT 1']);
  });

  // ---- break ----------------------------------------------------------------------------------------------------------------------
  t.test('Ctrl+C stops a running program with Break in NN', async (p) => {
    await typeProgram(p, ['10 A=1', '20 GOTO 20']);
    await line(p, 'RUN');
    await p.waitState('running');
    await p.key('c', { ctrl: true });
    await p.waitState('paused');
    await waitOk(p);
    p.assert.match(await p.screen(), /Break in 20 *\nOk/);
  });

  t.test('Ctrl+Break also stops a running program', async (p) => {
    await line(p, '10 GOTO 10');
    await line(p, 'RUN');
    await p.waitState('running');
    await p.key('Pause', { ctrl: true });
    await p.waitState('paused');
    await waitOk(p);
    p.assert.match(await p.screen(), /Break in 10/);
  });

  t.test('Break reports the line inside a subroutine', async (p) => {
    await typeProgram(p, ['10 GOSUB 100', '20 END', '100 GOTO 100']);
    await line(p, 'RUN');
    await p.waitState('running');
    await p.key('c', { ctrl: true });
    await p.waitState('paused');
    await waitOk(p);
    p.assert.match(await p.screen(), /Break in 100/);
  });

  t.test('Ctrl+C while a program waits for INPUT breaks it', async (p) => {
    await typeProgram(p, ['10 INPUT "NAME";N$', '20 PRINT N$']);
    await line(p, 'RUN');
    await p.waitState('waiting');
    await p.key('c', { ctrl: true });
    await p.waitState('paused');
    await waitOk(p);
    p.assert.match(await p.screen(), /Break in 10/);
  });

  t.test('Ctrl+C at the Ok prompt abandons the typed line', async (p) => {
    await p.type('10 PRINT "HALF');
    await p.key('c', { ctrl: true });
    p.assert.equal(await prog(p), '');
    const L = await rows(p);
    p.assert.equal(L[0], '10 PRINT "HALF');
    p.assert.equal(L[1], 'Ok');
    p.assert.deepEqual(await at(p), [2, 0]);
  });

  t.test('keys typed while the program waits for INPUT go to the program', async (p) => {
    await typeProgram(p, ['10 INPUT "NAME";N$', '20 PRINT "HI ";N$']);
    await line(p, 'RUN');
    await p.waitState('waiting');
    await p.type('ADA\n');
    await idle(p); await waitOk(p);
    p.assert.match(await p.screen(), /NAME\? ADA *\nHI ADA *\nOk/);
    p.assert.deepEqual(await progLines(p), ['10 INPUT "NAME";N$', '20 PRINT "HI ";N$']);
  });

  t.test('a program that ends prints Ok and the console takes keys again', async (p) => {
    await line(p, '10 PRINT "END"');
    await cmd(p, 'RUN');
    await cmd(p, 'PRINT 5');
    p.assert.deepEqual(await out(p, 'PRINT 5'), [' 5']);
  });

  // ---- paste --------------------------------------------------------------------------------------------------------------------------
  t.test('pasting numbered lines stores them in the program', async (p) => {
    await paste(p, '20 PRINT "P2"\n10 PRINT "P1"\n');
    p.assert.deepEqual(await progLines(p), ['10 PRINT "P1"', '20 PRINT "P2"']);
    p.assert.deepEqual((await rows(p)).slice(0, 2), ['20 PRINT "P2"', '10 PRINT "P1"']);
  });

  t.test('pasted CRLF text is treated as separate lines', async (p) => {
    await paste(p, '10 A=1\r\n20 B=2\r\n');
    p.assert.deepEqual(await progLines(p), ['10 A=1', '20 B=2']);
  });

  t.test('pasting a program followed by RUN runs it', async (p) => {
    await paste(p, '10 PRINT "PASTED"\n20 PRINT 6*7\nRUN\n');
    await idle(p); await waitOk(p);
    p.assert.deepEqual(await out(p, 'RUN'), ['PASTED', ' 42']);
  });

  t.test('pasting text without a newline leaves it on the line for editing', async (p) => {
    await paste(p, 'PRINT "WAIT"');
    p.assert.equal(await row(p, 0), 'PRINT "WAIT"');
    p.assert.deepEqual(await at(p), [0, 12]);
    await p.key('Enter');
    await idle(p); await waitOk(p);
    p.assert.deepEqual(await out(p, 'PRINT "WAIT"'), ['WAIT']);
  });

  t.test('pasting after a Ctrl+C break goes to the console', async (p) => {
    await line(p, '10 GOTO 10');
    await line(p, 'RUN');
    await p.waitState('running');
    await p.key('c', { ctrl: true });
    await p.waitState('paused');
    await waitOk(p);
    await paste(p, '20 REM PASTED\n');
    p.assert.deepEqual(await progLines(p), ['10 GOTO 10', '20 REM PASTED']);
  });
};
