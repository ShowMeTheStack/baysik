// Build: inline CSS + all JS (in manifest order) into a single self-contained index.html.
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync } from 'node:child_process';

const root = dirname(fileURLToPath(import.meta.url));
execSync('node tools/gen-samples.mjs', { cwd: dirname(fileURLToPath(import.meta.url)), stdio: 'inherit' });
const src = (p) => readFileSync(join(root, 'src', p), 'utf8');
const manifest = JSON.parse(src('manifest.json'));

let version = '0.1.0';
try { version = JSON.parse(readFileSync(join(root, 'package.json'), 'utf8')).version; } catch (e) { /* ignore */ }
let commit = '';
try { commit = execSync('git rev-parse --short HEAD', { cwd: root }).toString().trim(); } catch (e) { /* ignore */ }

const js = [...manifest.core, ...manifest.ide]
  .map((f) => `// ==== ${f} ====\n${src(f)}`)
  .join('\n')
  .replace(/<\/script/gi, '<\\/script');
const css = manifest.css.map((f) => src(f)).join('\n');

let html = src('shell.html');
html = html.replace('/*@@CSS@@*/', () => css);
html = html.replace('//@@JS@@', () => js);
html = html.replace(/@@VERSION@@/g, version + (commit ? ' (' + commit + ')' : ''));
writeFileSync(join(root, 'index.html'), html);
console.log(`index.html: ${(html.length / 1024).toFixed(1)} KB`);
