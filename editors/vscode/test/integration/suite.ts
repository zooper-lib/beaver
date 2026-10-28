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

    test('a change near the end yields one local edit', async () => {
      const editor = await open('d.dart', 'var a = 1;\nvar b = 2;\nvar  c=3;\n');
      const edits = await vscode.commands.executeCommand<vscode.TextEdit[]>(
        'vscode.executeFormatDocumentProvider',
        editor.document.uri,
        { tabSize: 2, insertSpaces: true },
      );
      assert.equal(edits.length, 1);
      assert.equal(edits[0].range.start.line, 2);
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

    test('Show Formatter Information runs', async () => {
      await open('j.dart', 'var a = 1;\n');
      await vscode.commands.executeCommand('beaver.showInformation');
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
