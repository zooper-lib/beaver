// Finds the beaver executable: setting → PATH → bundled, each probed with
// `--version`. A configured or PATH binary that is unusable is an error, never
// a silent fallback to the next source.
import { PROTOCOL_VERSION, parseVersion } from './protocol';

export type Source = 'setting' | 'PATH' | 'bundled';

export interface Binary {
  path: string;
  source: Source;
  version: string;
  protocol: number;
}

export interface Probe {
  /** The executable named [name] on PATH, or null. */
  which(name: string): string | null;
  /** Whether a file exists at [path]. */
  exists(path: string): boolean;
  /** Runs `<path> --version` and returns stdout, or throws. */
  version(path: string): Promise<string>;
}

export class BinaryError extends Error {}

export async function resolveBinary(
  setting: string,
  bundledPath: string,
  probe: Probe,
): Promise<Binary> {
  let path: string | null;
  let source: Source;
  if (setting.trim() !== '') {
    path = setting.trim();
    source = 'setting';
  } else if ((path = probe.which(process.platform === 'win32' ? 'beaver.exe' : 'beaver'))) {
    source = 'PATH';
  } else if (probe.exists(bundledPath)) {
    path = bundledPath;
    source = 'bundled';
  } else {
    throw new BinaryError(
      'No beaver executable found: set beaver.executablePath, put beaver on PATH, or install the platform-specific extension.',
    );
  }

  let output: string;
  try {
    output = await probe.version(path);
  } catch (e) {
    throw new BinaryError(`beaver from ${source} (${path}) does not run: ${(e as Error).message}`);
  }
  const parsed = parseVersion(output);
  if (!parsed) {
    throw new BinaryError(`beaver from ${source} (${path}) printed an unexpected version: ${output.trim()}`);
  }
  if (parsed.protocol !== PROTOCOL_VERSION) {
    throw new BinaryError(
      `beaver from ${source} (${path}) speaks protocol ${parsed.protocol}; this extension needs protocol ${PROTOCOL_VERSION}.`,
    );
  }
  return { path, source, ...parsed };
}
