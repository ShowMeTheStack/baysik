// GW-BASIC classic console, part A: entering/leaving, banner, KEY line, program document sync,
// numbered line entry, direct-mode statements and error messages.
import { enter, focus, rows, row, cur, prog, progLines, idle, waitOk, cmd, line, out, clear, typeProgram, attrAt, lastRow } from './60-console-lib.mjs';

const KEYLINE = '1LIST   2RUN←   3LOAD"  4SAVE"  5CONT←  6,"LPT1 7TRON←  8TROFF← 9KEY    0SCREEN';

export default (t) => {
  t.beforeEach(async (p) => { await p.fresh(); });

  // ---- entering / leaving -------------------------------------------------------------------------------
  t.test('View > GW-BASIC Classic Console enters the console and focuses the screen', async (p) => {
    p.assert.equal(await p.ev('RC.app.console.active'), false);
    await p.menu('View', 'GW-BASIC Classic Console');
    p.assert.equal(await p.ev('RC.app.console.active'), true);
    p.assert.equal(await p.ev("document.getElementById('screenTitle').textContent"), 'GW-BASIC Console');
    p.assert.equal(await p.ev("document.getElementById('app').classList.contains('console')"), true);
    p.assert.equal(await p.focusedId(), 'screen');
  });

  t.test('View menu shows the console item checked while the console is active', async (p) => {
    await p.click('.menu-btn', 'View');
    await p.wait("!!document.querySelector('.menu-pop')");
    let item = (await p.menuItems()).find((i) => i.label === 'GW-BASIC Classic Console');
    p.assert.equal(item.checked, false);
    await p.closeMenus();
    await enter(p);
    await p.click('.menu-btn', 'View');
    await p.wait("!!document.querySelector('.menu-pop')");
    item = (await p.menuItems()).find((i) => i.label === 'GW-BASIC Classic Console');
    p.assert.equal(item.checked, true);
    await p.closeMenus();
  });

  t.test('choosing the View menu item again leaves the console', async (p) => {
    await p.menu('View', 'GW-BASIC Classic Console');
    await p.menu('View', 'GW-BASIC Classic Console');
    p.assert.equal(await p.ev('RC.app.console.active'), false);
    p.assert.equal(await p.ev("document.getElementById('screenTitle').textContent"), 'Output');
    p.assert.equal(await p.ev("document.getElementById('app').classList.contains('console')"), false);
  });

  t.test('screen header GW-BASIC button enters the console', async (p) => {
    await p.click('#screenActions button[title="GW-BASIC classic console"]');
    p.assert.equal(await p.ev('RC.app.console.active'), true);
    p.assert.match(await row(p, 0), /^Baysik GW-BASIC compatible console$/);
  });

  t.test('screen header GW-BASIC button pressed again leaves the console', async (p) => {
    await p.click('#screenActions button[title="GW-BASIC classic console"]');
    await p.click('#screenActions button[title="GW-BASIC classic console"]');
    p.assert.equal(await p.ev('RC.app.console.active'), false);
    p.assert.equal(await row(p, 24), '', 'soft-key line removed');
  });

  t.test('typing SYSTEM leaves the console and removes the KEY line', async (p) => {
    await enter(p);
    await line(p, 'SYSTEM');
    await p.wait('RC.app.console.active === false');
    p.assert.equal(await row(p, 24), '');
    p.assert.match(await p.status(), /Left GW-BASIC console/);
    p.assert.equal(await p.ev("document.getElementById('screenTitle').textContent"), 'Output');
  });

  t.test('a program executing SYSTEM leaves the console', async (p) => {
    await enter(p);
    await line(p, '10 PRINT "BYE"');
    await line(p, '20 SYSTEM');
    await line(p, 'RUN');
    await p.wait('RC.app.console.active === false');
    p.assert.match(await p.screen(), /BYE/);
  });

  t.test('status bar explains how to use and leave the console', async (p) => {
    await enter(p);
    p.assert.match(await p.status(), /GW-BASIC console .*SYSTEM/);
  });

  t.test('re-entering the console clears the screen and shows the banner again', async (p) => {
    await enter(p);
    await cmd(p, 'PRINT "LEFTOVER"');
    await line(p, 'SYSTEM');
    await p.wait('RC.app.console.active === false');
    await enter(p);
    const s = await p.screen();
    p.assert.doesNotMatch(s, /LEFTOVER/);
    p.assert.equal((await rows(p))[0], 'Baysik GW-BASIC compatible console');
  });

  t.test('after leaving, keys on the screen no longer reach the console', async (p) => {
    await enter(p);
    await line(p, 'SYSTEM');
    await p.wait('RC.app.console.active === false');
    await focus(p);
    await p.type('10 PRINT 1\n');
    p.assert.equal((await prog(p)).trim(), '');
  });

  // ---- banner & Ok prompt ---------------------------------------------------------------------------------
  t.test('banner text lines are printed on entry', async (p) => {
    await enter(p);
    const L = await rows(p);
    p.assert.equal(L[0], 'Baysik GW-BASIC compatible console');
    p.assert.match(L[1] + L[2], /^Type a numbered line to add it to the program; LIST, RUN, NEW, LOAD "x", SAVE "x",$/);
    p.assert.equal(L[3], 'FILES, AUTO, RENUM, EDIT n, CONT and SYSTEM (to leave) work as in GW-BASIC.');
  });

  t.test('empty program shows 60300 Bytes free then Ok', async (p) => {
    await enter(p);
    const L = await rows(p);
    p.assert.equal(L[4], '60300 Bytes free');
    p.assert.equal(L[5], 'Ok');
  });

  t.test('Bytes free accounts for an open numbered program', async (p) => {
    const text = '10 PRINT "HELLO"\n20 GOTO 10\n';
    await p.newFile('C:\\MYPROGS\\NUM.BAS', text);
    await enter(p);
    p.assert.equal((await rows(p))[4], String(60300 - text.length) + ' Bytes free');
  });

  t.test('cursor waits at column 0 on the row below Ok', async (p) => {
    await enter(p);
    p.assert.deepEqual(await cur(p), { row: 6, col: 0 });
  });

  t.test('console screen is 80x25 text with grey on black', async (p) => {
    await enter(p);
    p.assert.equal(await p.ev('RC.app.runner.display.mode'), 0);
    p.assert.equal(await p.ev('RC.app.runner.display.textCols()'), 80);
    p.assert.equal(await p.ev('RC.app.runner.display.textRows()'), 25);
    p.assert.equal(await attrAt(p, 0, 0), 7);
  });

  t.test('entering the console after a graphics program resets to SCREEN 0', async (p) => {
    await p.runProgram('SCREEN 1\nPSET (5,5),3');
    p.assert.equal(await p.ev('RC.app.runner.display.mode'), 1);
    await enter(p);
    p.assert.equal(await p.ev('RC.app.runner.display.mode'), 0);
    p.assert.equal((await rows(p))[0], 'Baysik GW-BASIC compatible console');
  });

  // ---- KEY line -----------------------------------------------------------------------------------------------
  t.test('row 25 shows the ten soft-key labels', async (p) => {
    await enter(p);
    p.assert.equal(await row(p, 24), KEYLINE);
  });

  t.test('KEY line stays on row 25 while output scrolls', async (p) => {
    await enter(p);
    await cmd(p, 'FOR I=1 TO 40:PRINT "ROW";I:NEXT');
    const L = await rows(p);
    p.assert.equal(L[24], KEYLINE);
    p.assert.equal(L[22], 'Ok');
    p.assert.equal(L[21], 'ROW 40');
  });

  t.test('KEY OFF blanks row 25 and frees it for text', async (p) => {
    await enter(p);
    await cmd(p, 'KEY OFF');
    p.assert.equal(await row(p, 24), '');
    p.assert.equal(await p.ev('RC.app.runner.display.viewBottom'), 24);
  });

  t.test('KEY ON brings the soft-key line back', async (p) => {
    await enter(p);
    await cmd(p, 'KEY OFF');
    await cmd(p, 'KEY ON');
    p.assert.equal(await row(p, 24), KEYLINE);
  });

  t.test('KEY n,"text" changes the label shown on row 25', async (p) => {
    await enter(p);
    await cmd(p, 'KEY 1,"FILES"+CHR$(13)');
    p.assert.match(await row(p, 24), /^1FILES← 2RUN← {3}3LOAD"/);
  });

  t.test('F1 types the text assigned with KEY 1', async (p) => {
    await enter(p);
    await cmd(p, 'KEY 1,"PRINT 7*6"+CHR$(13)');
    await p.key('F1');
    await idle(p);
    await waitOk(p);
    p.assert.deepEqual(await out(p, 'PRINT 7*6'), [' 42']);
  });

  t.test('SCREEN 1 shows five soft keys on the 40-column key line', async (p) => {
    await enter(p);
    await cmd(p, 'SCREEN 1');
    p.assert.equal(await p.ev('RC.app.runner.display.textCols()'), 40);
    p.assert.equal(await row(p, 24), '1LIST   2RUN←   3LOAD"  4SAVE"  5CONT←');
  });

  // ---- console program document ---------------------------------------------------------------------------
  t.test('with an unnumbered program active the console opens C:\\GW\\PROGRAM.BAS', async (p) => {
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\HELLO.BAS');
    await enter(p);
    p.assert.equal(await p.activePath(), 'C:\\GW\\PROGRAM.BAS');
    p.assert.equal(await p.ev('RC.app.console.docPath'), 'C:\\GW\\PROGRAM.BAS');
    p.assert.match(await p.text('#editorTabs .tab.active'), /PROGRAM\.BAS/);
  });

  t.test('a typed numbered line appears in the editor tab', async (p) => {
    await enter(p);
    await line(p, '10 PRINT "SYNC"');
    p.assert.equal(await p.code(), '10 PRINT "SYNC"\n');
    p.assert.equal(await p.activePath(), 'C:\\GW\\PROGRAM.BAS');
  });

  t.test('the program tab is marked dirty after typing a line', async (p) => {
    await enter(p);
    await line(p, '10 PRINT 1');
    await p.wait("!!document.querySelector('#editorTabs .tab.active .dirty')");
  });

  t.test('edits made in the editor are what LIST shows in the console', async (p) => {
    await enter(p);
    await line(p, '10 PRINT 1');
    await p.setCode('10 PRINT 1\n20 PRINT "FROM EDITOR"\n');
    await focus(p);
    await clear(p);
    await cmd(p, 'LIST');
    p.assert.deepEqual(await out(p, 'LIST'), ['10 PRINT 1', '20 PRINT "FROM EDITOR"']);
  });

  t.test('an open numbered program becomes the console program', async (p) => {
    await p.newFile('C:\\MYPROGS\\NUM.BAS', '10 PRINT "NUMBERED"\n20 END\n');
    await enter(p);
    p.assert.equal(await p.ev('RC.app.console.docPath'), 'C:\\MYPROGS\\NUM.BAS');
    await cmd(p, 'LIST');
    p.assert.deepEqual(await out(p, 'LIST'), ['10 PRINT "NUMBERED"', '20 END']);
  });

  t.test('an empty active document becomes the console program', async (p) => {
    await p.newFile('C:\\MYPROGS\\EMPTY.BAS', '');
    await enter(p);
    p.assert.equal(await p.ev('RC.app.console.docPath'), 'C:\\MYPROGS\\EMPTY.BAS');
    await line(p, '10 PRINT 1');
    p.assert.equal(await p.code(), '10 PRINT 1\n');
  });

  t.test('NEW empties the editor tab', async (p) => {
    await enter(p);
    await line(p, '10 PRINT 1');
    await line(p, '20 PRINT 2');
    await cmd(p, 'NEW');
    p.assert.equal(await p.code(), '');
  });

  t.test('RUN saves the console program to disk', async (p) => {
    await enter(p);
    await line(p, '10 PRINT "SAVED"');
    await cmd(p, 'RUN');
    p.assert.equal(await p.ev("RC.app.decodeText(RC.app.vfs.readFile('C:\\\\GW\\\\PROGRAM.BAS'))").then((s) => s.replace(/\r/g, '')), '10 PRINT "SAVED"\n');
    p.assert.equal(await p.exists('#editorTabs .tab.active .dirty'), false);
  });

  // ---- numbered line entry ----------------------------------------------------------------------------------
  t.test('lines typed out of order are kept in numeric order', async (p) => {
    await enter(p);
    await typeProgram(p, ['30 PRINT "C"', '10 PRINT "A"', '20 PRINT "B"']);
    p.assert.deepEqual(await progLines(p), ['10 PRINT "A"', '20 PRINT "B"', '30 PRINT "C"']);
  });

  t.test('a line inserted between existing lines lands in order', async (p) => {
    await enter(p);
    await typeProgram(p, ['10 A=1', '20 B=2', '15 C=3', '5 D=4']);
    p.assert.deepEqual(await progLines(p), ['5 D=4', '10 A=1', '15 C=3', '20 B=2']);
  });

  t.test('retyping a line number replaces that line', async (p) => {
    await enter(p);
    await typeProgram(p, ['10 PRINT "OLD"', '20 END', '10 PRINT "NEW"']);
    p.assert.deepEqual(await progLines(p), ['10 PRINT "NEW"', '20 END']);
  });

  t.test('a line number alone deletes that line', async (p) => {
    await enter(p);
    await typeProgram(p, ['10 A=1', '20 B=2', '30 C=3', '20']);
    p.assert.deepEqual(await progLines(p), ['10 A=1', '30 C=3']);
  });

  t.test('deleting a line that does not exist says Undefined line number', async (p) => {
    await enter(p);
    await line(p, '10 A=1');
    await cmd(p, '99');
    p.assert.deepEqual(await out(p, '99'), ['Undefined line number']);
    p.assert.deepEqual(await progLines(p), ['10 A=1']);
  });

  t.test('line number 65529 is accepted', async (p) => {
    await enter(p);
    await line(p, '65529 PRINT "LAST"');
    p.assert.deepEqual(await progLines(p), ['65529 PRINT "LAST"']);
  });

  t.test('line numbers above 65529 give Syntax error and are not stored', async (p) => {
    await enter(p);
    await cmd(p, '65530 PRINT "TOO BIG"');
    p.assert.deepEqual(await out(p, '65530 PRINT "TOO BIG"'), ['Syntax error']);
    p.assert.equal((await prog(p)).trim(), '');
  });

  t.test('storing a line prints no Ok', async (p) => {
    await enter(p);
    await line(p, '10 PRINT 1');
    const c = await cur(p);
    p.assert.deepEqual(c, { row: 7, col: 0 });
    p.assert.equal(await row(p, 6), '10 PRINT 1');
    p.assert.equal(await row(p, 7), '');
  });

  t.test('leading spaces before the line number are ignored', async (p) => {
    await enter(p);
    await line(p, '   40 PRINT "INDENTED"');
    p.assert.deepEqual(await progLines(p), ['40 PRINT "INDENTED"']);
  });

  t.test('a line typed without a space after the number is stored normalised', async (p) => {
    await enter(p);
    await line(p, '10PRINT 5');
    p.assert.deepEqual(await progLines(p), ['10 PRINT 5']);
    await cmd(p, 'RUN');
    p.assert.deepEqual(await out(p, 'RUN'), [' 5']);
  });

  t.test('lowercase program lines run', async (p) => {
    await enter(p);
    await line(p, '10 print "lower"; 2*3');
    await cmd(p, 'RUN');
    p.assert.deepEqual(await out(p, 'RUN'), ['lower 6']);
  });

  // ---- direct statements ----------------------------------------------------------------------------------
  t.test('PRINT an expression in direct mode', async (p) => {
    await enter(p);
    await cmd(p, 'PRINT 2+3');
    p.assert.deepEqual(await out(p, 'PRINT 2+3'), [' 5']);
  });

  t.test('? is shorthand for PRINT in direct mode', async (p) => {
    await enter(p);
    await cmd(p, '? "Q";10/4');
    p.assert.deepEqual(await out(p, '? "Q";10/4'), ['Q 2.5']);
  });

  t.test('direct FOR loop prints all iterations', async (p) => {
    await enter(p);
    await cmd(p, 'FOR I=1 TO 3:PRINT I;:NEXT');
    p.assert.deepEqual(await out(p, 'FOR I=1 TO 3:PRINT I;:NEXT'), [' 1  2  3']);
  });

  t.test('variables assigned in direct mode keep their value', async (p) => {
    await enter(p);
    await cmd(p, 'A=5');
    await cmd(p, 'B$="X"');
    await cmd(p, 'PRINT A*2;B$');
    p.assert.deepEqual(await out(p, 'PRINT A*2;B$'), [' 10 X']);
  });

  t.test('variables set by a program can be printed after RUN', async (p) => {
    await enter(p);
    await line(p, '10 X=5: Y$="HI"');
    await cmd(p, 'RUN');
    await cmd(p, 'PRINT X+1;Y$');
    p.assert.deepEqual(await out(p, 'PRINT X+1;Y$'), [' 6 HI']);
  });

  t.test('CLS clears the screen and Ok appears at the top', async (p) => {
    await enter(p);
    await cmd(p, 'CLS');
    const L = await rows(p);
    p.assert.equal(L[0], 'Ok');
    p.assert.ok(L.slice(1, 24).every((s) => s === ''));
    p.assert.equal(L[24], KEYLINE);
  });

  t.test('COLOR changes the attribute of following text', async (p) => {
    await enter(p);
    await cmd(p, 'COLOR 14,1');
    await cmd(p, 'PRINT "YEL"');
    const r = await lastRow(p, /^YEL$/);
    p.assert.equal(await attrAt(p, r, 0), 0x1E);
  });

  t.test('SCREEN 1 with PSET and LINE draws graphics in direct mode', async (p) => {
    await enter(p);
    await cmd(p, 'SCREEN 1');
    await cmd(p, 'PSET (100,100),3');
    await cmd(p, 'LINE (0,0)-(50,0),2');
    p.assert.equal(await p.ev('RC.app.runner.display.mode'), 1);
    p.assert.equal(await p.pixel(100, 100), 3);
    p.assert.equal(await p.pixel(25, 0), 2);
  });

  t.test('SCREEN 0 returns from graphics to 80-column text', async (p) => {
    await enter(p);
    await cmd(p, 'SCREEN 1');
    await cmd(p, 'SCREEN 0:WIDTH 80');
    p.assert.equal(await p.ev('RC.app.runner.display.mode'), 0);
    p.assert.equal(await p.ev('RC.app.runner.display.textCols()'), 80);
  });

  t.test('INPUT in direct mode waits for typed input', async (p) => {
    await enter(p);
    await line(p, 'INPUT "N";N');
    await p.waitState('waiting');
    p.assert.match(await p.screen(), /^N\?$/m);
    await p.type('7\n');
    await idle(p);
    await waitOk(p);
    await cmd(p, 'PRINT N*3');
    p.assert.deepEqual(await out(p, 'PRINT N*3'), [' 21']);
  });

  t.test('INPUT in direct mode works after a program was stopped with Ctrl+C', async (p) => {
    await enter(p);
    await line(p, '10 GOTO 10');
    await line(p, 'RUN');
    await p.waitState('running');
    await p.key('c', { ctrl: true });
    await p.waitState('paused');
    await line(p, 'INPUT A');
    await p.wait("RC.app.runner.state === 'waiting'", 3000);
    await p.type('42\n');
    await idle(p);
    await cmd(p, 'PRINT A*2');
    p.assert.deepEqual(await out(p, 'PRINT A*2'), [' 84']);
  });

  t.test('LOCATE in direct mode positions the next PRINT', async (p) => {
    await enter(p);
    await cmd(p, 'LOCATE 20,30:PRINT "HERE"');
    p.assert.equal((await rows(p))[19], ' '.repeat(29) + 'HERE');
  });

  t.test('GOTO in direct mode runs the program from that line', async (p) => {
    await enter(p);
    await typeProgram(p, ['10 PRINT "TEN"', '20 PRINT "TWENTY"']);
    await cmd(p, 'GOTO 20');
    p.assert.deepEqual(await out(p, 'GOTO 20'), ['TWENTY']);
  });

  // ---- errors -------------------------------------------------------------------------------------------------
  t.test('a malformed direct statement prints Syntax error then Ok', async (p) => {
    await enter(p);
    await cmd(p, 'PRINT (');
    p.assert.deepEqual(await out(p, 'PRINT ('), ['Syntax error']);
  });

  t.test('an unknown word in direct mode prints Syntax error', async (p) => {
    await enter(p);
    await cmd(p, 'HELLO');
    p.assert.deepEqual(await out(p, 'HELLO'), ['Syntax error']);
  });

  t.test('a program syntax error prints "Syntax error in 30" and lists the line for editing', async (p) => {
    await enter(p);
    await typeProgram(p, ['10 PRINT 1', '20 PRINT 2', '30 PRINT +']);
    await clear(p);
    await line(p, 'RUN');
    await idle(p);
    await p.waitScreen(/Syntax error in 30 *\nOk *\n30 PRINT \+ *\n/);
    const r = await lastRow(p, /^30 PRINT \+$/);
    p.assert.deepEqual(await cur(p), { row: r, col: 0 });
    p.assert.doesNotMatch(await p.screen(), /^ 1$/m, 'nothing ran');
  });

  t.test('the screen keeps keyboard focus after "Syntax error in NN" so the listed line can be edited', async (p) => {
    await enter(p);
    await typeProgram(p, ['10 PRINT 1', '30 PRINT +']);
    await line(p, 'RUN');
    await p.waitScreen(/Syntax error in 30/);
    await p.sleep(100);
    p.assert.equal(await p.focusedId(), 'screen');
  });

  t.test('fixing the listed syntax-error line on screen and pressing Enter stores it', async (p) => {
    await enter(p);
    await typeProgram(p, ['10 PRINT 1', '30 PRINT +']);
    await line(p, 'RUN');
    await p.waitScreen(/Syntax error in 30/);
    await p.sleep(100);
    await focus(p); // click the screen again before typing
    await p.key('End');
    await p.type('5\n');
    p.assert.deepEqual(await progLines(p), ['10 PRINT 1', '30 PRINT +5']);
    await clear(p);
    await cmd(p, 'RUN');
    p.assert.deepEqual(await out(p, 'RUN'), [' 1', ' 5']);
  });

  t.test('Division by zero in 20 is reported followed by Ok', async (p) => {
    await enter(p);
    await typeProgram(p, ['10 PRINT "A"', '20 X=1/0', '30 PRINT "NOT REACHED"']);
    await cmd(p, 'RUN');
    p.assert.deepEqual(await out(p, 'RUN'), ['A', 'Division by zero in 20']);
  });

  t.test('a runtime error in a direct statement prints Division by zero and Ok', async (p) => {
    await enter(p);
    await cmd(p, 'PRINT 1/0', 3000);
    p.assert.deepEqual(await out(p, 'PRINT 1/0'), ['Division by zero']);
  });

  t.test('Subscript out of range in 20 is reported', async (p) => {
    await enter(p);
    await typeProgram(p, ['10 DIM A(5)', '20 A(10)=1']);
    await cmd(p, 'RUN');
    p.assert.deepEqual(await out(p, 'RUN'), ['Subscript out of range in 20']);
  });

  t.test('RETURN without GOSUB in 10 is reported', async (p) => {
    await enter(p);
    await line(p, '10 RETURN');
    await cmd(p, 'RUN');
    p.assert.deepEqual(await out(p, 'RUN'), ['RETURN without GOSUB in 10']);
  });

  t.test('the console keeps working after a runtime error', async (p) => {
    await enter(p);
    await line(p, '10 X=1/0');
    await cmd(p, 'RUN');
    await line(p, '10 PRINT "FIXED"');
    await clear(p);
    await cmd(p, 'RUN');
    p.assert.deepEqual(await out(p, 'RUN'), ['FIXED']);
  });
};
