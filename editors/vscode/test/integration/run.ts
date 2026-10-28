// Launches VS Code with the extension and a scratch workspace, and runs the
// suite in ./suite.ts inside it. Needs BEAVER_BINARY (a built `beaver`) and a
// display (use xvfb-run on Linux CI).
import * as fs from 'node:fs';
import * as os from 'node:os';
import * as path from 'node:path';
import { runTests } from '@vscode/test-electron';

async function main() {
  const binary = process.env.BEAVER_BINARY;
  if (!binary) throw new Error('Set BEAVER_BINARY to a built beaver executable.');
  const workspace = fs.mkdtempSync(path.join(os.tmpdir(), 'beaver-vscode-it-'));
  fs.writeFileSync(path.join(workspace, 'pubspec.yaml'), 'name: it\n');
  fs.mkdirSync(path.join(workspace, '.vscode'));
  fs.writeFileSync(
    path.join(workspace, '.vscode', 'settings.json'),
    JSON.stringify({
      'beaver.executablePath': binary,
      '[dart]': { 'editor.defaultFormatter': 'zooper.beaver', 'editor.formatOnSave': true },
    }),
  );
  await runTests({
    extensionDevelopmentPath: path.resolve(__dirname, '../../..'),
    extensionTestsPath: path.resolve(__dirname, 'suite'),
    launchArgs: [workspace, '--disable-extensions'],
    extensionTestsEnv: { BEAVER_BINARY: binary, BEAVER_WORKSPACE: workspace },
  });
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
