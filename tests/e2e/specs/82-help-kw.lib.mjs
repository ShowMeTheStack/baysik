// Shared helpers for the keyword help specs.
import vm from 'node:vm';
import fs from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
export const KEYWORDS = (() => {
  const RC = {};
  vm.runInNewContext(fs.readFileSync(join(here, '..', '..', '..', 'src', 'lang', 'basic', 'helpdata.js'), 'utf8'), { RC });
  return JSON.parse(JSON.stringify(RC.BASIC_HELP.KEYWORDS));
})();
export async function closeAll(p) {
  for (let i = 0; i < 5 && await p.modalOpen(); i++) { await p.key('Escape'); await p.sleep(60); }
  await p.closeMenus();
}
/** Make sure the reference is open (opened with the toolbar Help button) with an empty search. */
export async function ensureHelp(p) {
  if (await p.modalOpen() && (await p.modalTitle()) === 'BASIC Language Reference') return;
  await closeAll(p);
  await p.click('#tbHelp');
  p.assert.equal(await p.waitModal(), 'BASIC Language Reference');
}
export const navSel = (name) => `.modal .help-nav div[data-key="${name.replace(/"/g, '\\"')}"]`;
export const tryPath = (name) => 'C:\\MYPROGS\\TRY_' + name.replace(/[^A-Z0-9]/gi, '').slice(0, 4) + '.BAS';
