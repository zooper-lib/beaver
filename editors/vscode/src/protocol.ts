// The editor side of the stdin protocol (docs/stdin-protocol.md), free of VS Code types so
// it can be tested on its own.

/** Protocol version this extension speaks; must equal `beaver --version`'s. */
export const PROTOCOL_VERSION = 1;

/** 0-based position, as editors count (UTF-16 columns). */
export interface Position {
  line: number;
  character: number;
}

/** `--range` value: 1-based, end exclusive, from 0-based editor positions. */
export function protocolRange(start: Position, end: Position): string {
  return `${start.line + 1}:${start.character + 1}-${end.line + 1}:${end.character + 1}`;
}

/** The single replacement turning [before] into [after]: the common prefix
 * and suffix are left alone, so an edit near the end stays local. */
export function minimalEdit(
  before: string,
  after: string,
): { start: number; end: number; text: string } | null {
  if (before === after) return null;
  let start = 0;
  const limit = Math.min(before.length, after.length);
  while (start < limit && before.charCodeAt(start) === after.charCodeAt(start)) start++;
  let suffix = 0;
  while (
    suffix < limit - start &&
    before.charCodeAt(before.length - 1 - suffix) === after.charCodeAt(after.length - 1 - suffix)
  ) {
    suffix++;
  }
  // Never split a surrogate pair at either edge.
  if (start > 0 && isHigh(before.charCodeAt(start - 1))) start--;
  if (suffix > 0 && isLow(before.charCodeAt(before.length - suffix))) suffix--;
  return { start, end: before.length - suffix, text: after.substring(start, after.length - suffix) };
}

const isHigh = (c: number) => c >= 0xd800 && c <= 0xdbff;
const isLow = (c: number) => c >= 0xdc00 && c <= 0xdfff;

/** Parses `beaver <version> (protocol <n>)`. */
export function parseVersion(output: string): { version: string; protocol: number } | null {
  const match = /^beaver (\S+) \(protocol (\d+)\)\s*$/.exec(output.trim());
  return match ? { version: match[1], protocol: Number(match[2]) } : null;
}

/** Exit codes the CLI reports. */
export const exitMeaning: Record<number, string> = {
  64: 'usage error',
  65: 'the file does not parse or has invalid ignore directives',
  66: 'input not found',
  70: 'internal error: the formatted output failed verification',
  78: 'invalid configuration',
};
