// Runs beaver over a buffer through the stdin protocol.
import { spawn } from 'child_process';

export interface RunResult {
  code: number;
  stdout: string;
  stderr: string;
}

/** Runs [binary] with [args], writing [input] to stdin. [onCancel] receives a
 * function that kills the process. */
export function run(
  binary: string,
  args: string[],
  input: string,
  cwd: string | undefined,
  onCancel?: (kill: () => void) => void,
): Promise<RunResult> {
  return new Promise((resolve, reject) => {
    const child = spawn(binary, args, { cwd, windowsHide: true });
    const stdout: Buffer[] = [];
    const stderr: Buffer[] = [];
    child.stdout.on('data', (d: Buffer) => stdout.push(d));
    child.stderr.on('data', (d: Buffer) => stderr.push(d));
    child.on('error', reject);
    child.on('close', (code) =>
      resolve({
        code: code ?? -1,
        stdout: Buffer.concat(stdout).toString('utf8'),
        stderr: Buffer.concat(stderr).toString('utf8'),
      }),
    );
    onCancel?.(() => child.kill());
    // The process may exit (or be killed) before reading all of stdin.
    child.stdin.on('error', () => {});
    child.stdin.end(input, 'utf8');
  });
}
