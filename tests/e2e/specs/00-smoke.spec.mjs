// Smoke tests: the IDE boots cleanly and the harness works.
export default (t) => {
  t.test('IDE boots with title Baysik', async (p) => {
    p.assert.match(await p.ev('document.title'), /Baysik/);
  });
  t.test('no welcome modal when firstRun is false', async (p) => {
    p.assert.equal(await p.modalOpen(), false);
  });
  t.test('HELLO.BAS is opened on first start', async (p) => {
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\HELLO.BAS');
  });
  t.test('running a program prints to the screen', async (p) => {
    await p.runProgram('PRINT "E2E OK"; 6 * 7');
    p.assert.match(await p.screen(), /E2E OK 42/);
  });
  t.test('welcome dialog appears on a true first run', async (p) => {
    p.assert.equal(await p.waitModal(), 'Welcome!');
  }, { fresh: { firstRun: true } });
};
