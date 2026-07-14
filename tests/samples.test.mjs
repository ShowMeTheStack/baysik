// Runs every sample program headlessly with scripted keys; fails on compile/runtime errors.
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';
import { loadRC, runBasic } from './harness.mjs';
const RC = loadRC();
const root = new URL('../samples/', import.meta.url).pathname;
const files = [];
const walk = (d) => { for (const f of readdirSync(d)) { const p = join(d, f); if (statSync(p).isDirectory()) walk(p); else files.push(p); } };
walk(root);
// Put all samples on a VFS so CHAIN/$INCLUDE work
const vfs = new RC.VFS();
for (const p of files) {
  const rel = relative(root, p).split('/');
  let cur = 'C:';
  for (let i = 0; i < rel.length - 1; i++) { cur += '\\' + rel[i]; if (!vfs.exists(cur)) vfs.mkdir(cur); }
  vfs.writeFile('C:\\' + rel.join('\\'), RC.strToBytes(RC.toCP437(readFileSync(p, 'utf8'))));
}
const inputs = { 'GUESS.BAS': '50\n25\n75\n12\n37\n62\n87\n6\n18\n31\n43\n56\n68\n81\n93\n3\n9\n15\n21\n28\n34\n40\n46\n53\n59\n65\n71\n78\n84\n90\n96\n1\n2\n4\n5\n7\n8\n10\n11\n13\n14\n16\n17\n19\n20\n22\n23\n24\n26\n27\n29\n30\n32\n33\n35\n36\n38\n39\n41\n42\n44\n45\n47\n48\n49\n51\n52\n54\n55\n57\n58\n60\n61\n63\n64\n66\n67\n69\n70\n72\n73\n74\n76\n77\n79\n80\n82\n83\n85\n86\n88\n89\n91\n92\n94\n95\n97\n98\n99\n100\n',
  'HELLO.BAS': 'Ada\n', 'CLASSIC.BAS': 'Paris\nOsaka\nNairobi\nLima\nOttawa\n', 'PHONEBK.BAS': '2\nAlice\n555-1234\n1\n \n3\nali\n \n4\n', 'DIARY.BAS': 'first entry\n' };
let bad = 0;
for (const p of files.filter((f) => /\.BAS$/i.test(f))) {
  const rel = relative(root, p);
  const name = rel.split('/').pop();
  const path = 'C:\\' + rel.replace(/\//g, '\\');
  const src = RC.fromCP437(RC.bytesToStr(vfs.readFile(path))).replace(/\r\n?/g, '\n');
  vfs.chdir(path.replace(/\\[^\\]*$/, '') || 'C:\\');
  const r = runBasic(RC, src, { vfs, input: (inputs[name] || '') + '          ', timeLimit: 2500, host: {} });
  // drive CHAIN manually
  let status;
  if (r.compileError) { status = 'COMPILE ERROR ' + r.compileError.message + ' @' + (r.compileError.pos ? r.compileError.pos.line + 1 : '?'); bad++; }
  else if (r.error) { status = 'RUNTIME ERROR ' + r.error.code + ' ' + r.error.message + ' @' + (r.error.pos ? r.error.pos.line + 1 : '?'); bad++; }
  else status = r.state + ' (' + r.vm.statementsExecuted + ' stmts, SCREEN ' + r.display.mode + ')';
  console.log(rel.padEnd(22), status);
}
process.exit(bad ? 1 : 0);
