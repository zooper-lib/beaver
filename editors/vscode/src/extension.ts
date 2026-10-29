// Beaver for VS Code: document and range formatting through `beaver --stdin`
// Runs where the files are (workspace extension), so a remote or
// container workspace uses the binary inside it.
import * as fs from 'fs';
import * as path from 'path';
import * as vscode from 'vscode';
import { Binary, BinaryError, Probe, resolveBinary } from './binary';
import { exitMeaning, minimalEdit, protocolRange } from './protocol';
import { run } from './run';

const probe: Probe = {
  which(name) {
    for (const dir of (process.env.PATH ?? '').split(path.delimiter)) {
      if (!dir) continue;
      const candidate = path.join(dir, name);
      if (fs.existsSync(candidate)) return candidate;
    }
    return null;
  },
  exists: (p) => fs.existsSync(p),
  async version(p) {
    const result = await run(p, ['--version'], '', undefined);
    if (result.code !== 0) throw new Error(result.stderr.trim() || `exit ${result.code}`);
    return result.stdout;
  },
};

export function activate(context: vscode.ExtensionContext): void {
  const output = vscode.window.createOutputChannel('Beaver');
  const bundled = context.asAbsolutePath(path.join('bin', process.platform === 'win32' ? 'beaver.exe' : 'beaver'));
  // Unpacking a VSIX does not reliably keep the executable bit.
  if (process.platform !== 'win32' && fs.existsSync(bundled)) {
    try {
      fs.chmodSync(bundled, 0o755);
    } catch {
      // Read-only install location: resolution reports it if it cannot run.
    }
  }
  let binary: Promise<Binary> | undefined;
  let reported = false;

  const getBinary = () =>
    (binary ??= resolveBinary(
      vscode.workspace.getConfiguration('beaver').get<string>('executablePath', ''),
      bundled,
      probe,
    ));

  context.subscriptions.push(
    output,
    vscode.workspace.onDidChangeConfiguration((e) => {
      if (e.affectsConfiguration('beaver')) {
        binary = undefined;
        reported = false;
      }
    }),
  );

  async function format(
    document: vscode.TextDocument,
    range: vscode.Range | undefined,
    token: vscode.CancellationToken,
  ): Promise<vscode.TextEdit[]> {
    let beaver: Binary;
    try {
      beaver = await getBinary();
    } catch (e) {
      // Reported once until the configuration changes, not on every save.
      if (!reported) {
        reported = true;
        void vscode.window.showErrorMessage((e as Error).message);
      }
      output.appendLine((e as Error).message);
      return [];
    }

    const args = ['--stdin'];
    if (document.uri.scheme === 'file') args.push('--stdin-name', document.uri.fsPath);
    if (range) args.push('--range', protocolRange(range.start, range.end));
    const version = document.version;
    const text = document.getText();
    const folder = vscode.workspace.getWorkspaceFolder(document.uri);
    const cwd = folder?.uri.fsPath ?? (document.uri.scheme === 'file' ? path.dirname(document.uri.fsPath) : undefined);

    const result = await run(beaver.path, args, text, cwd, (kill) => token.onCancellationRequested(kill));
    // Typing during formatting makes the result stale: discard it.
    if (token.isCancellationRequested || document.version !== version) return [];
    if (result.code !== 0) {
      const meaning = exitMeaning[result.code] ?? `exit ${result.code}`;
      output.appendLine(`${document.uri.fsPath}: ${meaning}\n${result.stderr}`);
      vscode.window.setStatusBarMessage(`Beaver: not formatted (${meaning})`, 5000);
      return [];
    }
    const edit = minimalEdit(text, result.stdout);
    if (!edit) return [];
    return [
      vscode.TextEdit.replace(new vscode.Range(document.positionAt(edit.start), document.positionAt(edit.end)), edit.text),
    ];
  }

  const selector: vscode.DocumentSelector = { language: 'dart' };
  context.subscriptions.push(
    vscode.languages.registerDocumentFormattingEditProvider(selector, {
      provideDocumentFormattingEdits: (document, _options, token) => format(document, undefined, token),
    }),
    vscode.languages.registerDocumentRangeFormattingEditProvider(selector, {
      provideDocumentRangeFormattingEdits: (document, range, _options, token) => format(document, range, token),
    }),
    vscode.commands.registerCommand('beaver.showInformation', async () => {
      const lines: string[] = [];
      const manifest = context.extension.packageJSON.beaver;
      lines.push(`Extension: ${context.extension.packageJSON.version} (bundles formatter ${manifest.formatterVersion}, protocol ${manifest.protocolVersion})`);
      lines.push(`Platform: ${process.platform}-${process.arch}`);
      try {
        const beaver = await getBinary();
        lines.push(`Formatter: ${beaver.version}`, `Protocol: ${beaver.protocol}`, `Source: ${beaver.source}`, `Path: ${beaver.path}`);
        const document = vscode.window.activeTextEditor?.document;
        const forFile = document?.uri.scheme === 'file' ? ['--for', document.uri.fsPath] : [];
        const folder = document ? vscode.workspace.getWorkspaceFolder(document.uri) : vscode.workspace.workspaceFolders?.[0];
        const config = await run(beaver.path, ['config', '--print', ...forFile], '', folder?.uri.fsPath);
        lines.push('', 'Resolved configuration:', config.code === 0 ? config.stdout : config.stderr);
      } catch (e) {
        lines.push(`Formatter: unavailable: ${e instanceof BinaryError ? e.message : String(e)}`);
      }
      const text = lines.join('\n');
      output.clear();
      output.appendLine(text);
      output.show(true);
      // Returned as well, for callers and tests.
      return text;
    }),
  );
}

export function deactivate(): void {}
