// Runs inside VS Code (see run.ts).
import * as assert from 'node:assert/strict';
import * as fs from 'node:fs';
import * as path from 'node:path';
import Mocha from 'mocha';
import * as vscode from 'vscode';

const workspace = process.env.BEAVER_WORKSPACE!;

async function open(name: string, contents: string): Promise<vscode.TextEditor> {
  const file = path.join(workspace, name);
  fs.writeFileSync(file, contents);
  const document = await vscode.workspace.openTextDocument(file);
  if (document.languageId !== 'dart') await vscode.languages.setTextDocumentLanguage(document, 'dart');
  return vscode.window.showTextDocument(document);
}

async function setText(editor: vscode.TextEditor, text: string) {
  const all = new vscode.Range(0, 0, editor.document.lineCount, 0);
  await editor.edit((e) => e.replace(all, text));
}

function tests() {
  suite('Beaver', () => {
    // Opening a Dart file activates the extension in the background; the
    // first format must not race the provider's registration.
    suiteSetup(async () => {
      await vscode.extensions.getExtension('zooper.beaver')!.activate();
    });

    test('Format Document', async () => {
      const editor = await open('a.dart', 'var  a=1;\n');
      await vscode.commands.executeCommand('editor.action.formatDocument');
      assert.equal(editor.document.getText(), 'var a = 1;\n');
    });

    test('Format Selection formats only the covering statement', async () => {
      const editor = await open('b.dart', 'var  a=1;\nvar  b=2;\n');
      editor.selection = new vscode.Selection(1, 0, 1, 3);
      await vscode.commands.executeCommand('editor.action.formatSelection');
      assert.equal(editor.document.getText(), 'var  a=1;\nvar b = 2;\n');
    });

    test('unsaved edits are formatted, not the file on disk', async () => {
      const editor = await open('c.dart', 'var  disk=1;\n');
      await setText(editor, 'var  buffer=2;\n');
      await vscode.commands.executeCommand('editor.action.formatDocument');
      assert.equal(editor.document.getText(), 'var buffer = 2;\n');
    });

    test('a change near the end yields only local edits', async () => {
      const editor = await open('d.dart', 'var a = 1;\nvar b = 2;\nvar  c=3;\n');
      const edits = await vscode.commands.executeCommand<vscode.TextEdit[]>(
        'vscode.executeFormatDocumentProvider',
        editor.document.uri,
        { tabSize: 2, insertSpaces: true },
      );
      // VS Code splits the provider's single edit into minimal ones; all of
      // them must stay on the changed line.
      assert.ok(edits.length > 0);
      for (const edit of edits) {
        assert.equal(edit.range.start.line, 2);
        assert.equal(edit.range.end.line, 2);
      }
    });

    test('typing during formatting discards the result', async () => {
      const editor = await open('e.dart', 'var  a=1;\n'.repeat(20000));
      const pending = vscode.commands.executeCommand<vscode.TextEdit[]>(
        'vscode.executeFormatDocumentProvider',
        editor.document.uri,
        { tabSize: 2, insertSpaces: true },
      );
      await editor.edit((e) => e.insert(new vscode.Position(0, 0), '// typed\n'));
      assert.deepEqual((await pending) ?? [], []);
    });

    test('a syntax error (exit 65) leaves the buffer unchanged', async () => {
      const editor = await open('f.dart', 'var = ;\n');
      await vscode.commands.executeCommand('editor.action.formatDocument');
      assert.equal(editor.document.getText(), 'var = ;\n');
    });

    test('saving an excluded .g.dart file shows no error and changes nothing', async () => {
      const editor = await open('g.g.dart', 'var  generated=1;\n');
      await setText(editor, 'var  generated=2;\n');
      await editor.document.save();
      assert.equal(editor.document.getText(), 'var  generated=2;\n');
    });

    test('format on save with the documented settings', async () => {
      const editor = await open('h.dart', 'var  a=1;\n');
      await setText(editor, 'var  saved=1;\n');
      await editor.document.save();
      assert.equal(fs.readFileSync(editor.document.uri.fsPath, 'utf8'), 'var saved = 1;\n');
    });

    test('an incompatible explicit path formats nothing', async () => {
      const fake = path.join(workspace, process.platform === 'win32' ? 'fake.cmd' : 'fake.sh');
      fs.writeFileSync(fake, process.platform === 'win32' ? '@echo beaver 9.0.0 (protocol 2)' : '#!/bin/sh\necho "beaver 9.0.0 (protocol 2)"\n');
      fs.chmodSync(fake, 0o755);
      const config = vscode.workspace.getConfiguration('beaver');
      await config.update('executablePath', fake, vscode.ConfigurationTarget.Workspace);
      try {
        const editor = await open('i.dart', 'var  a=1;\n');
        await vscode.commands.executeCommand('editor.action.formatDocument');
        assert.equal(editor.document.getText(), 'var  a=1;\n');
      } finally {
        await config.update('executablePath', process.env.BEAVER_BINARY, vscode.ConfigurationTarget.Workspace);
      }
    });

    // Task 17.3: end-to-end format on save on a representative file (541
    // lines), process start included. Reported, not asserted: CI machines
    // vary; docs/performance.md records the numbers.
    test('format-on-save latency', async () => {
      const source = fs.readFileSync(
        path.resolve(__dirname, '../../../../../packages/zooper_beaver/lib/src/cli/cli.dart'),
        'utf8',
      );
      const editor = await open('latency.dart', source);
      const times: number[] = [];
      for (let i = 0; i < 7; i++) {
        // Unformatted again: a doubled space after the first `import`.
        await setText(editor, source.replace('import ', 'import  '));
        const start = performance.now();
        await editor.document.save();
        times.push(performance.now() - start);
        assert.equal(editor.document.getText(), source);
      }
      // The binary is already resolved by earlier tests; the first save still
      // pays any one-off cost of this file.
      const sorted = times.slice(1).sort((a, b) => a - b);
      console.log(
        `BEAVER_LATENCY vscode first=${times[0].toFixed(1)}ms ` +
          `median=${sorted[Math.floor(sorted.length / 2)].toFixed(1)}ms max=${sorted[sorted.length - 1].toFixed(1)}ms ` +
          `runs=[${times.map((t) => t.toFixed(0)).join(', ')}]`,
      );
    });

    test('Show Formatter Information lists versions, source, path, platform and configuration', async () => {
      await open('j.dart', 'var a = 1;\n');
      const info = await vscode.commands.executeCommand<string>('beaver.showInformation');
      assert.match(info, /^Extension: \S+ \(bundles formatter \S+, protocol \d+\)$/m);
      assert.match(info, new RegExp(`^Platform: ${process.platform}-${process.arch}$`, 'm'));
      assert.match(info, /^Formatter: \d+\.\d+\.\d+\S*$/m);
      assert.match(info, /^Protocol: 1$/m);
      // The workspace sets beaver.executablePath.
      const lines = info.split('\n');
      assert.ok(lines.includes('Source: setting'), info);
      assert.ok(lines.includes(`Path: ${process.env.BEAVER_BINARY}`), info);
      assert.match(info, /^Resolved configuration:\n[\s\S]*^line_length: 80 {2}# preset dart$/m);
    });
  });
}

export function run(): Promise<void> {
  const mocha = new Mocha({ ui: 'tdd', timeout: 20000 });
  mocha.suite.emit('pre-require', globalThis, 'suite', mocha);
  tests();
  return new Promise((resolve, reject) =>
    mocha.run((failures) => (failures ? reject(new Error(`${failures} failed`)) : resolve())),
  );
}
