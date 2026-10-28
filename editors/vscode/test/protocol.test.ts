import * as assert from 'node:assert/strict';
import * as fs from 'node:fs';
import * as os from 'node:os';
import * as path from 'node:path';
import { test } from 'node:test';
import { BinaryError, Probe, resolveBinary } from '../src/binary';
import { minimalEdit, parseVersion, protocolRange } from '../src/protocol';
import { run } from '../src/run';

// Integration with the real CLI uses BEAVER_BINARY (a built `beaver`).
const beaver = process.env.BEAVER_BINARY;

test('0-based editor range becomes a 1-based protocol range', () => {
  assert.equal(protocolRange({ line: 2, character: 4 }, { line: 4, character: 10 }), '3:5-5:11');
});

test('a change near the end yields a local edit', () => {
  const before = 'var a = 1;\nvar b = 2;\nvar  c=3;\n';
  const after = 'var a = 1;\nvar b = 2;\nvar c = 3;\n';
  const edit = minimalEdit(before, after)!;
  assert.equal(before.substring(0, edit.start) + edit.text + before.substring(edit.end), after);
  assert.ok(edit.start >= 22, 'the first two lines are untouched');
  assert.ok(edit.text.length <= 4);
  assert.equal(minimalEdit(before, before), null);
});

test('an edit never splits a surrogate pair', () => {
  const edit = minimalEdit('x😀a', 'x😁a')!;
  assert.equal('x😀a'.substring(0, edit.start) + edit.text + 'x😀a'.substring(edit.end), 'x😁a');
  assert.equal(edit.start, 1);
});

test('version output parses', () => {
  assert.deepEqual(parseVersion('beaver 0.1.0 (protocol 1)\n'), { version: '0.1.0', protocol: 1 });
  assert.equal(parseVersion('something else'), null);
});

function fakeProbe(binaries: Record<string, string>, onPath?: string): Probe {
  return {
    which: () => onPath ?? null,
    exists: (p) => p in binaries,
    version: async (p) => {
      if (!(p in binaries)) throw new Error('ENOENT');
      return binaries[p];
    },
  };
}

test('PATH is preferred over the bundled binary', async () => {
  const probe = fakeProbe({ '/usr/bin/beaver': 'beaver 0.2.0 (protocol 1)', '/ext/bin/beaver': 'beaver 0.1.0 (protocol 1)' }, '/usr/bin/beaver');
  const binary = await resolveBinary('', '/ext/bin/beaver', probe);
  assert.equal(binary.source, 'PATH');
  assert.equal(binary.version, '0.2.0');
});

test('the bundled binary is used when nothing else is configured', async () => {
  const probe = fakeProbe({ '/ext/bin/beaver': 'beaver 0.1.0 (protocol 1)' });
  assert.equal((await resolveBinary('', '/ext/bin/beaver', probe)).source, 'bundled');
});

test('an incompatible explicit path is an error, with no fallback', async () => {
  const probe = fakeProbe({ '/opt/beaver': 'beaver 9.0.0 (protocol 2)', '/ext/bin/beaver': 'beaver 0.1.0 (protocol 1)' });
  await assert.rejects(resolveBinary('/opt/beaver', '/ext/bin/beaver', probe), (e: unknown) =>
    e instanceof BinaryError && /protocol 2/.test(e.message),
  );
});

test('an incompatible PATH binary is an error, with no fallback', async () => {
  const probe = fakeProbe({ '/usr/bin/beaver': 'beaver 9.0.0 (protocol 2)', '/ext/bin/beaver': 'beaver 0.1.0 (protocol 1)' }, '/usr/bin/beaver');
  await assert.rejects(resolveBinary('', '/ext/bin/beaver', probe), BinaryError);
});

test('Format Document through the real CLI', { skip: !beaver }, async () => {
  const result = await run(beaver!, ['--stdin'], 'var  a=1;\n', undefined);
  assert.deepEqual([result.code, result.stdout], [0, 'var a = 1;\n']);
});

test('Format Selection through the real CLI', { skip: !beaver }, async () => {
  // Selecting part of the second line (0-based line 1) formats that statement only.
  const range = protocolRange({ line: 1, character: 0 }, { line: 1, character: 3 });
  const result = await run(beaver!, ['--stdin', '--range', range], 'var  a=1;\nvar  b=2;\n', undefined);
  assert.equal(result.stdout, 'var  a=1;\nvar b = 2;\n');
});

test('the buffer is formatted, not the file on disk (unsaved edits)', { skip: !beaver }, async () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'beaver-vscode-'));
  const file = path.join(dir, 'a.dart');
  fs.writeFileSync(file, 'var  disk=1;\n');
  const result = await run(beaver!, ['--stdin', '--stdin-name', file], 'var  buffer=2;\n', dir);
  assert.equal(result.stdout, 'var buffer = 2;\n');
  fs.rmSync(dir, { recursive: true });
});

test('a syntax error (exit 65) produces no edit', { skip: !beaver }, async () => {
  const result = await run(beaver!, ['--stdin'], 'var = ;', undefined);
  assert.equal(result.code, 65);
  assert.equal(result.stdout, '');
});

test('saving an excluded .g.dart file echoes it with exit 0 (no edit, no error)', { skip: !beaver }, async () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'beaver-vscode-'));
  fs.writeFileSync(path.join(dir, 'pubspec.yaml'), 'name: x\n');
  const source = 'var  generated=1;\n';
  const result = await run(beaver!, ['--stdin', '--stdin-name', path.join(dir, 'a.g.dart')], source, dir);
  assert.equal(result.code, 0);
  assert.equal(minimalEdit(source, result.stdout), null);
  fs.rmSync(dir, { recursive: true });
});

test('cancellation kills the process', { skip: !beaver }, async () => {
  let kill: (() => void) | undefined;
  const big = 'var  a=1;\n'.repeat(200000);
  const pending = run(beaver!, ['--stdin'], big, undefined, (k) => (kill = k));
  kill!();
  const result = await pending;
  assert.notEqual(result.code, 0);
});
