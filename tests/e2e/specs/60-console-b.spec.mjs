// GW-BASIC classic console, part B: program commands typed at the Ok prompt
// (LIST, LLIST, RUN, NEW, LOAD, SAVE, MERGE, FILES, KILL, RENUM, DELETE, AUTO, EDIT, CONT).
import { enter, rows, cur, prog, progLines, idle, waitOk, cmd, line, out, clear, typeProgram, writeFile, exists, readFile, resolveSave } from './60-console-lib.mjs';

const P5 = ['10 PRINT "A"', '20 PRINT "B"', '30 PRINT "C"', '40 PRINT "D"', '50 PRINT "E"'];

export default (t) => {
  // the console changes into its program's folder; these tests work from the root, so they CHDIR there first
  t.beforeEach(async (p) => { await p.fresh(); await enter(p); await cmd(p, 'CHDIR "C:\\"'); });

  t.test('the console starts in its program\'s folder: FILES lists it and SAVE writes there', async (p) => {
    await p.fresh();
    await p.newFile('C:\\MYPROGS\\NEXT.BAS', '10 PRINT "NEXT"\n');
    await enter(p);
    p.assert.equal(await p.ev('RC.app.vfs.cwd()'), 'C:\\MYPROGS');
    await clear(p);
    await cmd(p, 'FILES');
    p.assert.match((await out(p, 'FILES')).join('\n'), /NEXT +\.BAS/);
    await cmd(p, 'SAVE "COPY1"');
    p.assert.equal(await exists(p, 'C:\\MYPROGS\\COPY1.BAS'), true);
  });

  // ---- LIST ---------------------------------------------------------------------------------------------------
  t.test('LIST shows the whole program', async (p) => {
    await typeProgram(p, P5);
    await clear(p);
    await cmd(p, 'LIST');
    p.assert.deepEqual(await out(p, 'LIST'), P5);
  });

  t.test('LIST n shows one line', async (p) => {
    await typeProgram(p, P5);
    await cmd(p, 'LIST 30');
    p.assert.deepEqual(await out(p, 'LIST 30'), ['30 PRINT "C"']);
  });

  t.test('LIST n- shows from n to the end', async (p) => {
    await typeProgram(p, P5);
    await cmd(p, 'LIST 30-');
    p.assert.deepEqual(await out(p, 'LIST 30-'), P5.slice(2));
  });

  t.test('LIST -n shows from the start to n', async (p) => {
    await typeProgram(p, P5);
    await cmd(p, 'LIST -20');
    p.assert.deepEqual(await out(p, 'LIST -20'), P5.slice(0, 2));
  });

  t.test('LIST n-m shows the inclusive range', async (p) => {
    await typeProgram(p, P5);
    await cmd(p, 'LIST 20-40');
    p.assert.deepEqual(await out(p, 'LIST 20-40'), P5.slice(1, 4));
  });

  t.test('LIST n-m with bounds between line numbers', async (p) => {
    await typeProgram(p, P5);
    await cmd(p, 'LIST 15-35');
    p.assert.deepEqual(await out(p, 'LIST 15-35'), P5.slice(1, 3));
  });

  t.test('LIST . shows the line most recently listed', async (p) => {
    await typeProgram(p, P5);
    await cmd(p, 'LIST 20-40');
    await cmd(p, 'LIST .');
    p.assert.deepEqual(await out(p, 'LIST .'), ['40 PRINT "D"']);
  });

  t.test('LIST . after EDIT shows the edited line', async (p) => {
    await typeProgram(p, P5);
    await line(p, 'EDIT 20');
    await p.key('Escape');
    await cmd(p, 'LIST .');
    p.assert.deepEqual(await out(p, 'LIST .'), ['20 PRINT "B"']);
  });

  t.test('LIST of an empty program prints only Ok', async (p) => {
    await cmd(p, 'LIST');
    p.assert.deepEqual(await out(p, 'LIST'), []);
  });

  t.test('LIST of a missing line prints nothing', async (p) => {
    await typeProgram(p, P5);
    await cmd(p, 'LIST 35');
    p.assert.deepEqual(await out(p, 'LIST 35'), []);
  });

  t.test('long listings scroll the screen above the KEY line', async (p) => {
    for (let i = 1; i <= 30; i++) await line(p, `${i * 10} REM LINE ${i}`);
    await cmd(p, 'LIST');
    const L = await rows(p);
    p.assert.equal(L[21], '300 REM LINE 30');
    p.assert.equal(L[22], 'Ok');
    p.assert.match(L[24], /^1LIST/);
  });

  // ---- LLIST ----------------------------------------------------------------------------------------------------
  t.test('LLIST sends the listing to the Printer panel, not the screen', async (p) => {
    await typeProgram(p, P5.slice(0, 2));
    await clear(p);
    await cmd(p, 'LLIST');
    p.assert.deepEqual(await out(p, 'LLIST'), []);
    await p.panel('printer');
    p.assert.match(await p.panelText(), /10 PRINT "A"\n20 PRINT "B"/);
  });

  t.test('LLIST n-m prints only the range', async (p) => {
    await typeProgram(p, P5);
    await cmd(p, 'LLIST 20-30');
    p.assert.deepEqual(await p.ev('RC.app.panels.printerLines'), ['20 PRINT "B"', '30 PRINT "C"']);
  });

  // ---- RUN ------------------------------------------------------------------------------------------------------------
  t.test('RUN runs the program and returns to Ok', async (p) => {
    await typeProgram(p, P5.slice(0, 3));
    await clear(p);
    await cmd(p, 'RUN');
    p.assert.deepEqual(await out(p, 'RUN'), ['A', 'B', 'C']);
    p.assert.equal(await p.ev('RC.app.console.active'), true);
  });

  t.test('RUN n starts at line n', async (p) => {
    await typeProgram(p, P5.slice(0, 3));
    await cmd(p, 'RUN 20');
    p.assert.deepEqual(await out(p, 'RUN 20'), ['B', 'C']);
  });

  t.test('RUN with a missing line prints Undefined line number without an extra Ok', async (p) => {
    await typeProgram(p, P5.slice(0, 2));
    await cmd(p, 'RUN 15');
    p.assert.deepEqual(await out(p, 'RUN 15'), ['Undefined line number']);
  });

  t.test('RUN resets variables set in direct mode', async (p) => {
    await cmd(p, 'A=5');
    await line(p, '10 PRINT A');
    await cmd(p, 'RUN');
    p.assert.deepEqual(await out(p, 'RUN'), [' 0']);
  });

  t.test('RUN "file" loads and runs another program', async (p) => {
    await writeFile(p, 'C:\\OTHER.BAS', '10 PRINT "OTHER RAN"\n');
    await line(p, '10 PRINT "MINE"');
    await cmd(p, 'RUN "OTHER"');
    p.assert.deepEqual(await out(p, 'RUN "OTHER"'), ['OTHER RAN']);
    p.assert.equal(await p.activePath(), 'C:\\OTHER.BAS');
    p.assert.deepEqual(await progLines(p), ['10 PRINT "OTHER RAN"']);
  });

  t.test('RUN "missing" prints File not found', async (p) => {
    await cmd(p, 'RUN "NOSUCH"');
    p.assert.deepEqual(await out(p, 'RUN "NOSUCH"'), ['File not found']);
  });

  t.test('the toolbar Run button runs the console program', async (p) => {
    await line(p, '10 PRINT "TOOLBAR"');
    await p.click('#tbRun');
    await idle(p);
    await p.waitScreen(/TOOLBAR *\nOk/);
  });

  // ---- NEW --------------------------------------------------------------------------------------------------------
  t.test('NEW erases the program', async (p) => {
    await typeProgram(p, P5);
    await cmd(p, 'NEW');
    p.assert.equal(await prog(p), '');
    await cmd(p, 'LIST');
    p.assert.deepEqual(await out(p, 'LIST'), []);
  });

  t.test('NEW then CONT says Can\'t continue', async (p) => {
    await typeProgram(p, ['10 STOP', '20 PRINT "X"']);
    await cmd(p, 'RUN');
    await cmd(p, 'NEW');
    await cmd(p, 'CONT');
    p.assert.deepEqual(await out(p, 'CONT'), ["Can't continue"]);
  });

  // ---- LOAD -----------------------------------------------------------------------------------------------------
  t.test('LOAD "x" replaces the program with the file', async (p) => {
    await writeFile(p, 'C:\\LOADME.BAS', '10 PRINT "LOADED"\n20 END\n');
    await line(p, '5 PRINT "OLD"');
    await cmd(p, 'LOAD "LOADME.BAS"');
    p.assert.deepEqual(await out(p, 'LOAD "LOADME.BAS"'), []);
    p.assert.deepEqual(await progLines(p), ['10 PRINT "LOADED"', '20 END']);
  });

  t.test('LOAD adds the .BAS extension and opens the file in a tab', async (p) => {
    await writeFile(p, 'C:\\LOADME.BAS', '10 PRINT "LOADED"\n');
    await cmd(p, 'LOAD "LOADME"');
    p.assert.equal(await p.activePath(), 'C:\\LOADME.BAS');
    p.assert.match(await p.text('#editorTabs .tab.active'), /LOADME\.BAS/);
    p.assert.equal(await p.ev('RC.app.console.docPath'), 'C:\\LOADME.BAS');
  });

  t.test('LOAD "x",R loads and runs', async (p) => {
    await writeFile(p, 'C:\\LOADME.BAS', '10 PRINT "AUTO RUN"\n');
    await cmd(p, 'LOAD "LOADME",R');
    p.assert.deepEqual(await out(p, 'LOAD "LOADME",R'), ['AUTO RUN']);
  });

  t.test('LOAD of a missing file prints File not found and keeps the program', async (p) => {
    await line(p, '10 PRINT 1');
    await cmd(p, 'LOAD "NOSUCH"');
    p.assert.deepEqual(await out(p, 'LOAD "NOSUCH"'), ['File not found']);
    p.assert.deepEqual(await progLines(p), ['10 PRINT 1']);
  });

  t.test('LIST after LOAD shows the loaded lines', async (p) => {
    await writeFile(p, 'C:\\LOADME.BAS', '10 A=1\n20 B=2\n');
    await cmd(p, 'LOAD "LOADME"');
    await cmd(p, 'LIST');
    p.assert.deepEqual(await out(p, 'LIST'), ['10 A=1', '20 B=2']);
  });

  // ---- SAVE -------------------------------------------------------------------------------------------------------
  t.test('SAVE "x" writes the program to disk', async (p) => {
    const path = await resolveSave(p, 'MYPROG');
    p.assert.equal(await exists(p, path), false);
    await typeProgram(p, ['10 PRINT "SAVED"', '20 END']);
    await cmd(p, 'SAVE "MYPROG"');
    p.assert.equal(await exists(p, path), true);
    p.assert.equal((await readFile(p, path)).replace(/\r/g, ''), '10 PRINT "SAVED"\n20 END\n');
  });

  t.test('SAVE makes the saved file the console program', async (p) => {
    const path = await resolveSave(p, 'MYPROG');
    await line(p, '10 PRINT 1');
    await cmd(p, 'SAVE "MYPROG"');
    p.assert.equal(await p.activePath(), path);
    p.assert.equal(await p.ev('RC.app.console.docPath'), path);
    p.assert.equal(await p.exists('#editorTabs .tab.active .dirty'), false);
  });

  t.test('a saved file appears in the Files explorer', async (p) => {
    await line(p, '10 PRINT 1');
    await cmd(p, 'SAVE "SHOWME"');
    await p.wait("document.getElementById('explorerTree').innerText.includes('SHOWME.BAS')");
  });

  t.test('SAVE again under the same name saves later edits', async (p) => {
    const path = await resolveSave(p, 'MYPROG');
    await line(p, '10 PRINT 1');
    await cmd(p, 'SAVE "MYPROG"');
    await line(p, '20 PRINT 2');
    await cmd(p, 'SAVE "MYPROG"');
    p.assert.equal((await readFile(p, path)).replace(/\r/g, ''), '10 PRINT 1\n20 PRINT 2\n');
  });

  // ---- MERGE ------------------------------------------------------------------------------------------------------
  t.test('MERGE adds lines from a file and overrides equal numbers', async (p) => {
    await writeFile(p, 'C:\\PART.BAS', '15 PRINT "MERGED"\n20 PRINT "REPLACED"\n');
    await typeProgram(p, ['10 PRINT "A"', '20 PRINT "B"', '30 PRINT "C"']);
    await cmd(p, 'MERGE "PART"');
    p.assert.deepEqual(await progLines(p), ['10 PRINT "A"', '15 PRINT "MERGED"', '20 PRINT "REPLACED"', '30 PRINT "C"']);
  });

  t.test('MERGE of a missing file prints File not found', async (p) => {
    await cmd(p, 'MERGE "NOSUCH"');
    p.assert.deepEqual(await out(p, 'MERGE "NOSUCH"'), ['File not found']);
  });

  // ---- FILES / KILL -------------------------------------------------------------------------------------------------
  t.test('FILES lists the current directory and bytes free', async (p) => {
    await clear(p);
    await cmd(p, 'FILES');
    const o = await out(p, 'FILES');
    p.assert.equal(o[0], 'C:\\');
    p.assert.match(o.join('\n'), /MYPROGS +<DIR>/);
    p.assert.match(o[o.length - 1], /^ \d+ Bytes free$/);
  });

  t.test('FILES shows a newly saved program', async (p) => {
    await line(p, '10 PRINT 1');
    await cmd(p, 'SAVE "LISTED"');
    await clear(p);
    await cmd(p, 'FILES');
    p.assert.match((await out(p, 'FILES')).join('\n'), /LISTED +\.BAS/);
  });

  t.test('FILES "*.BAS" lists only matching files', async (p) => {
    await writeFile(p, 'C:\\ONE.BAS', '10 END\n');
    await writeFile(p, 'C:\\TWO.TXT', 'hello');
    await clear(p);
    await cmd(p, 'FILES "*.BAS"');
    const o = (await out(p, 'FILES "*.BAS"')).join('\n');
    p.assert.match(o, /ONE +\.BAS/);
    p.assert.doesNotMatch(o, /TWO/);
    p.assert.doesNotMatch(o, /<DIR>/);
  });

  t.test('FILES with no matching files prints File not found', async (p) => {
    await cmd(p, 'FILES "ZZZ*.*"', 3000);
    p.assert.deepEqual(await out(p, 'FILES "ZZZ*.*"'), ['C:\\', 'File not found']);
  });

  t.test('KILL deletes a file from disk', async (p) => {
    await writeFile(p, 'C:\\DOOMED.BAS', '10 END\n');
    await cmd(p, 'KILL "DOOMED.BAS"');
    p.assert.deepEqual(await out(p, 'KILL "DOOMED.BAS"'), []);
    p.assert.equal(await exists(p, 'C:\\DOOMED.BAS'), false);
  });

  t.test('KILL of a missing file prints File not found', async (p) => {
    await cmd(p, 'KILL "NOSUCH.BAS"', 3000);
    p.assert.deepEqual(await out(p, 'KILL "NOSUCH.BAS"'), ['File not found']);
  });

  // ---- RENUM ---------------------------------------------------------------------------------------------------------
  t.test('RENUM renumbers from 10 in steps of 10', async (p) => {
    await typeProgram(p, ['3 PRINT "A"', '7 PRINT "B"', '12 PRINT "C"']);
    await cmd(p, 'RENUM');
    p.assert.deepEqual(await progLines(p), ['10 PRINT "A"', '20 PRINT "B"', '30 PRINT "C"']);
  });

  t.test('RENUM new starts at the given number', async (p) => {
    await typeProgram(p, ['3 PRINT "A"', '7 PRINT "B"']);
    await cmd(p, 'RENUM 100');
    p.assert.deepEqual(await progLines(p), ['100 PRINT "A"', '110 PRINT "B"']);
  });

  t.test('RENUM new,,inc uses the increment', async (p) => {
    await typeProgram(p, ['3 PRINT "A"', '7 PRINT "B"', '9 PRINT "C"']);
    await cmd(p, 'RENUM 100,,5');
    p.assert.deepEqual(await progLines(p), ['100 PRINT "A"', '105 PRINT "B"', '110 PRINT "C"']);
  });

  t.test('RENUM new,old renumbers only from the old line on', async (p) => {
    await typeProgram(p, ['10 A=1', '20 B=2', '30 C=3', '40 D=4']);
    await cmd(p, 'RENUM 1000,30');
    p.assert.deepEqual(await progLines(p), ['10 A=1', '20 B=2', '1000 C=3', '1010 D=4']);
  });

  t.test('RENUM ,,inc keeps the start and changes the step', async (p) => {
    await typeProgram(p, ['10 A=1', '20 B=2', '30 C=3']);
    await cmd(p, 'RENUM ,,2');
    p.assert.deepEqual(await progLines(p), ['10 A=1', '12 B=2', '14 C=3']);
  });

  t.test('RENUM updates GOTO, GOSUB, THEN and ELSE references', async (p) => {
    await typeProgram(p, ['1 GOTO 3', '2 GOSUB 4', '3 IF X THEN 2 ELSE 5', '4 RETURN', '5 END']);
    await cmd(p, 'RENUM');
    p.assert.deepEqual(await progLines(p), ['10 GOTO 30', '20 GOSUB 40', '30 IF X THEN 20 ELSE 50', '40 RETURN', '50 END']);
  });

  t.test('RENUM updates ON ... GOTO lists and RESTORE', async (p) => {
    await typeProgram(p, ['1 ON X GOTO 2,3', '2 RESTORE 3', '3 DATA 1']);
    await cmd(p, 'RENUM 100,,100');
    p.assert.deepEqual(await progLines(p), ['100 ON X GOTO 200,300', '200 RESTORE 300', '300 DATA 1']);
  });

  t.test('renumbered program still runs correctly', async (p) => {
    await typeProgram(p, ['1 GOSUB 5', '2 PRINT "BACK"', '3 END', '5 PRINT "SUB"', '6 RETURN']);
    await cmd(p, 'RENUM');
    await clear(p);
    await cmd(p, 'RUN');
    p.assert.deepEqual(await out(p, 'RUN'), ['SUB', 'BACK']);
  });

  t.test('RENUM warns about references to missing lines', async (p) => {
    await typeProgram(p, ['10 GOTO 999', '20 END']);
    await cmd(p, 'RENUM 100');
    p.assert.deepEqual(await out(p, 'RENUM 100'), ['Undefined line 999 in 100']);
    p.assert.deepEqual(await progLines(p), ['100 GOTO 999', '110 END']);
  });

  t.test('RENUM that would reorder lines gives Illegal function call and changes nothing', async (p) => {
    await typeProgram(p, ['10 A=1', '20 B=2', '30 C=3']);
    await cmd(p, 'RENUM 15,30');
    p.assert.match((await out(p, 'RENUM 15,30'))[0], /^Illegal function call/);
    p.assert.deepEqual(await progLines(p), ['10 A=1', '20 B=2', '30 C=3']);
  });

  t.test('RENUM is reflected in the editor tab', async (p) => {
    await typeProgram(p, ['5 A=1', '6 B=2']);
    await cmd(p, 'RENUM');
    p.assert.equal(await p.code(), '10 A=1\n20 B=2\n');
  });

  // ---- DELETE ---------------------------------------------------------------------------------------------------------
  t.test('DELETE n removes one line', async (p) => {
    await typeProgram(p, P5);
    await cmd(p, 'DELETE 30');
    p.assert.deepEqual(await progLines(p), [P5[0], P5[1], P5[3], P5[4]]);
  });

  t.test('DELETE n-m removes the range', async (p) => {
    await typeProgram(p, P5);
    await cmd(p, 'DELETE 20-40');
    p.assert.deepEqual(await progLines(p), [P5[0], P5[4]]);
  });

  t.test('DELETE -n removes from the start', async (p) => {
    await typeProgram(p, P5);
    await cmd(p, 'DELETE -20');
    p.assert.deepEqual(await progLines(p), P5.slice(2));
  });

  t.test('DELETE n- removes to the end', async (p) => {
    await typeProgram(p, P5);
    await cmd(p, 'DELETE 40-');
    p.assert.deepEqual(await progLines(p), P5.slice(0, 3));
  });

  t.test('DELETE of a missing line prints Illegal function call', async (p) => {
    await typeProgram(p, P5);
    await cmd(p, 'DELETE 35');
    p.assert.deepEqual(await out(p, 'DELETE 35'), ['Illegal function call']);
    p.assert.deepEqual(await progLines(p), P5);
  });

  // ---- AUTO -----------------------------------------------------------------------------------------------------------
  t.test('AUTO offers 10, 20, 30 and stores typed lines', async (p) => {
    await line(p, 'AUTO');
    let c = await cur(p);
    p.assert.equal((await rows(p))[c.row], '10');
    p.assert.equal(c.col, 3);
    await line(p, 'PRINT "X"');
    c = await cur(p);
    p.assert.equal((await rows(p))[c.row], '20');
    await line(p, 'PRINT "Y"');
    p.assert.equal((await rows(p))[(await cur(p)).row], '30');
    p.assert.deepEqual(await progLines(p), ['10 PRINT "X"', '20 PRINT "Y"']);
  });

  t.test('AUTO start,inc uses the given numbering', async (p) => {
    await line(p, 'AUTO 100,5');
    await line(p, 'A=1');
    await line(p, 'B=2');
    p.assert.equal((await rows(p))[(await cur(p)).row], '110');
    p.assert.deepEqual(await progLines(p), ['100 A=1', '105 B=2']);
  });

  t.test('AUTO marks existing line numbers with *', async (p) => {
    await typeProgram(p, ['20 PRINT "KEEP"']);
    await line(p, 'AUTO');
    await line(p, 'A=1');
    const c = await cur(p);
    p.assert.equal((await rows(p))[c.row], '20*');
  });

  t.test('Enter on an empty AUTO line keeps the existing line', async (p) => {
    await typeProgram(p, ['10 PRINT "KEEP"']);
    await line(p, 'AUTO');
    await line(p, '');
    p.assert.equal((await rows(p))[(await cur(p)).row], '20');
    p.assert.deepEqual(await progLines(p), ['10 PRINT "KEEP"']);
  });

  t.test('typing after an AUTO * prompt replaces the existing line', async (p) => {
    await typeProgram(p, ['10 PRINT "OLD"']);
    await line(p, 'AUTO');
    await line(p, 'PRINT "NEW"');
    p.assert.deepEqual(await progLines(p), ['10 PRINT "NEW"']);
  });

  t.test('Ctrl+C stops AUTO with Ok and the prompt line is not stored', async (p) => {
    await line(p, 'AUTO');
    await line(p, 'A=1');
    await p.key('c', { ctrl: true });
    await waitOk(p);
    p.assert.equal(await p.ev('RC.app.console.auto'), null);
    await cmd(p, 'LIST');
    p.assert.deepEqual(await out(p, 'LIST'), ['10 A=1']);
  });

  t.test('AUTO started with a typed partial line keeps the AUTO numbering', async (p) => {
    await line(p, 'AUTO 50');
    await p.type('PRI');
    await p.key('Backspace');
    await p.type('INT 5\n');
    p.assert.deepEqual(await progLines(p), ['50 PRINT 5']);
  });

  // ---- EDIT --------------------------------------------------------------------------------------------------------------
  t.test('EDIT n displays the line with the cursor at its start', async (p) => {
    await typeProgram(p, P5);
    await clear(p);
    await line(p, 'EDIT 30');
    const c = await cur(p);
    p.assert.equal((await rows(p))[c.row], '30 PRINT "C"');
    p.assert.equal(c.col, 0);
  });

  t.test('EDIT then changing text and Enter updates the program', async (p) => {
    await typeProgram(p, P5.slice(0, 2));
    await line(p, 'EDIT 20');
    await p.key('End');
    await p.key('Backspace');
    await p.key('Backspace');
    await p.type('Z"\n');
    p.assert.deepEqual(await progLines(p), ['10 PRINT "A"', '20 PRINT "Z"']);
  });

  t.test('EDIT of a missing line prints Undefined line number', async (p) => {
    await typeProgram(p, P5.slice(0, 2));
    await cmd(p, 'EDIT 99');
    p.assert.deepEqual(await out(p, 'EDIT 99'), ['Undefined line number']);
  });

  // ---- CONT -----------------------------------------------------------------------------------------------------------------
  t.test('STOP prints Break in NN and CONT continues', async (p) => {
    await typeProgram(p, ['10 PRINT "BEFORE"', '20 STOP', '30 PRINT "AFTER"']);
    await clear(p);
    await cmd(p, 'RUN');
    p.assert.deepEqual(await out(p, 'RUN'), ['BEFORE', '', 'Break in 20']);
    p.assert.equal(await p.state(), 'paused');
    await cmd(p, 'CONT');
    p.assert.deepEqual(await out(p, 'CONT'), ['AFTER']);
  });

  t.test('Ctrl+C breaks a running program and CONT resumes it', async (p) => {
    await line(p, '10 I=I+1: GOTO 10');
    await line(p, 'RUN');
    await p.waitState('running');
    await p.key('c', { ctrl: true });
    await p.waitState('paused');
    await waitOk(p);
    p.assert.match(await p.screen(), /Break in 10/);
    await cmd(p, 'A=I');
    await line(p, 'CONT');
    await p.waitState('running');
    await p.sleep(150);
    await p.key('c', { ctrl: true });
    await p.waitState('paused');
    await waitOk(p);
    await cmd(p, 'PRINT I>A');
    p.assert.deepEqual(await out(p, 'PRINT I>A'), ['-1']);
  });

  t.test('variables can be inspected after a STOP', async (p) => {
    await typeProgram(p, ['10 X=42', '20 STOP']);
    await cmd(p, 'RUN');
    await cmd(p, 'PRINT X');
    p.assert.deepEqual(await out(p, 'PRINT X'), [' 42']);
  });

  t.test('variables changed during a break are used by CONT', async (p) => {
    await typeProgram(p, ['10 X=1', '20 STOP', '30 PRINT X*10']);
    await cmd(p, 'RUN');
    await cmd(p, 'X=7');
    await cmd(p, 'CONT');
    p.assert.deepEqual(await out(p, 'CONT'), [' 70']);
  });

  t.test("CONT with no program run prints Can't continue", async (p) => {
    await cmd(p, 'CONT');
    p.assert.deepEqual(await out(p, 'CONT'), ["Can't continue"]);
  });

  t.test("CONT after the program ended prints Can't continue", async (p) => {
    await line(p, '10 PRINT "DONE"');
    await cmd(p, 'RUN');
    await cmd(p, 'CONT');
    p.assert.deepEqual(await out(p, 'CONT'), ["Can't continue"]);
  });

  t.test("CONT after editing the program during a break prints Can't continue", async (p) => {
    await typeProgram(p, ['10 STOP', '20 PRINT "OLD CODE"']);
    await cmd(p, 'RUN');
    await line(p, '20 PRINT "NEW CODE"');
    await cmd(p, 'CONT');
    p.assert.deepEqual(await out(p, 'CONT'), ["Can't continue"]);
  });

  t.test('RUN after a break starts the program over', async (p) => {
    await typeProgram(p, ['10 PRINT "START"', '20 STOP', '30 PRINT "END"']);
    await cmd(p, 'RUN');
    await clear(p);
    await line(p, 'RUN');
    await p.waitScreen(/START *\n(?: *\n)?Break in 20 *\nOk/);
    p.assert.equal(await p.state(), 'paused');
  });

  t.test('RUN after a break prints no stray Ok before the program output', async (p) => {
    await typeProgram(p, ['10 PRINT "START"', '20 STOP']);
    await cmd(p, 'RUN');
    await clear(p);
    await line(p, 'RUN');
    await p.waitScreen(/Break in 20/);
    await waitOk(p);
    p.assert.deepEqual((await out(p, 'RUN')).filter((s) => s !== ''), ['START', 'Break in 20']);
  });

  t.test('TRON typed in direct mode traces line numbers when the program runs', async (p) => {
    await typeProgram(p, ['10 A=1', '20 PRINT "X"']);
    await cmd(p, 'TRON');
    await clear(p);
    await cmd(p, 'RUN');
    p.assert.match((await out(p, 'RUN')).join(''), /\[10\]\[20\]X/);
  });

  t.test('TRON inside a program traces the following lines', async (p) => {
    await typeProgram(p, ['10 TRON', '20 A=1', '30 PRINT "X"']);
    await clear(p);
    await cmd(p, 'RUN');
    p.assert.match((await out(p, 'RUN')).join(''), /\[20\]\[30\]X/);
  });
};
