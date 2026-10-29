/// The `beaver` command line: file selection, modes, the stdin
/// protocol and exit-code aggregation. The only part of the package that
/// touches the file system.
library;

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;

import '../config/loader.dart';
import '../config/resolve.dart';
import '../config/schema.dart';
import '../directives/directives.dart';
import '../format.dart';
import '../parse/parse.dart';
import '../range/range.dart';
import '../verify/verification_failure.dart';
import '../version.dart';
import 'diff.dart';

/// sysexits-style exit codes.
abstract final class ExitCode {
  static const success = 0;
  static const changes = 1;
  static const usage = 64;
  static const data = 65;
  static const noInput = 66;
  static const software = 70;
  static const config = 78;

  /// Most severe first.
  static const _severity = [software, config, usage, data, noInput, changes];

  static int worst(int a, int b) {
    for (final code in _severity) {
      if (a == code || b == code) return code;
    }
    return success;
  }
}

ArgParser _parser() {
  final parser = ArgParser()
    ..addFlag(
      'check',
      negatable: false,
      help: 'List files that would change; exit 1 if any.',
    )
    ..addFlag(
      'diff',
      negatable: false,
      help: 'Print a unified diff for files that would change; exit 1 if any.',
    )
    ..addFlag(
      'stdin',
      negatable: false,
      help: 'Format the document on stdin and write it to stdout.',
    )
    ..addOption(
      'stdin-name',
      valueHelp: 'path',
      help:
          'Path of the stdin document, for configuration and exclusions; never read.',
    )
    ..addOption(
      'range',
      valueHelp: 'L1:C1-L2:C2',
      help:
          'With --stdin: format only the units covering this range (1-based, UTF-16 columns, end exclusive).',
    )
    ..addOption(
      'config',
      valueHelp: 'file',
      help: 'Use this configuration file instead of discovering .beaver.yaml.',
    )
    ..addFlag(
      'verbose',
      negatable: false,
      help: 'List skipped files and the pattern excluding each.',
    )
    ..addFlag(
      'version',
      negatable: false,
      help: 'Print the formatter and protocol versions.',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');
  parser.addCommand(
    'config',
    ArgParser()
      ..addFlag(
        'print',
        negatable: false,
        help:
            'Print the resolved configuration and where each value comes from.',
      )
      ..addOption(
        'for',
        valueHelp: 'file',
        help: 'Resolve as if formatting this file.',
      ),
  );
  parser.addCommand('init');
  return parser;
}

String _usage(ArgParser parser) => '''
Usage: beaver [options] <paths...>
       beaver --stdin [--stdin-name <path>] [--range <range>]
       beaver config --print [--for <file>]
       beaver init

Paths may be files, directories (searched recursively for .dart files) or globs.

${parser.usage}

Commands:
  config --print [--for <file>]   Print the resolved configuration with provenance.
  init                            Write a starter .beaver.yaml (never overwrites).

Exit codes: 0 ok, 1 changes found (--check/--diff), 64 usage, 65 unparseable input
or invalid directives, 66 missing input, 70 internal error, 78 invalid configuration.''';

/// Runs the CLI. [input] defaults to stdin; output goes to [output] and
/// diagnostics to [errors] (stdout and stderr by default). Returns the exit code.
Future<int> runCli(
  List<String> arguments, {
  Stream<List<int>>? input,
  IOSink? output,
  IOSink? errors,
}) async {
  final out = output ?? stdout;
  final err = errors ?? stderr;
  final parser = _parser();
  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    err.writeln('${e.message}\n\n${_usage(parser)}');
    return ExitCode.usage;
  }

  if (args.flag('help')) {
    out.writeln(_usage(parser));
    return ExitCode.success;
  }
  if (args.flag('version')) {
    out.writeln('beaver $beaverVersion (protocol $protocolVersion)');
    return ExitCode.success;
  }

  int usage(String message) {
    err.writeln('$message\n\nRun "beaver --help" for usage.');
    return ExitCode.usage;
  }

  final command = args.command;
  if (command != null) {
    if (command.name == 'init') return _init(out, err);
    if (!command.flag('print')) return usage('Use "beaver config --print".');
    return _printConfig(command.option('for'), args.option('config'), out, err);
  }

  final stdinMode = args.flag('stdin');
  final range = args.option('range');
  final paths = args.rest;
  if (range != null && !stdinMode) return usage('--range requires --stdin.');
  if (args.option('stdin-name') != null && !stdinMode) {
    return usage('--stdin-name requires --stdin.');
  }
  if (stdinMode && paths.isNotEmpty) {
    return usage('--stdin takes no path arguments.');
  }
  if (stdinMode && (args.flag('check') || args.flag('diff'))) {
    return usage('--check and --diff do not apply to --stdin.');
  }
  if (args.flag('check') && args.flag('diff')) {
    return usage('Use either --check or --diff.');
  }
  if (!stdinMode && paths.isEmpty) return usage('No paths given.');

  final explicitConfig = args.option('config');
  if (explicitConfig != null) {
    // An invalid --config is fatal before any file is processed.
    try {
      resolveConfig(
        Directory.current.path,
        read: _read,
        explicit: explicitConfig,
        isDirectory: true,
      );
    } on ConfigException catch (e) {
      err.writeln(e.message);
      return ExitCode.config;
    }
  }

  if (stdinMode) {
    return _stdin(
      input ?? stdin,
      out,
      err,
      name: args.option('stdin-name'),
      range: range,
      explicitConfig: explicitConfig,
    );
  }

  return _files(
    paths,
    out,
    err,
    mode: args.flag('check')
        ? _Mode.check
        : args.flag('diff')
        ? _Mode.diff
        : _Mode.write,
    verbose: args.flag('verbose'),
    explicitConfig: explicitConfig,
  );
}

enum _Mode { write, check, diff }

String? _read(String path) {
  final file = File(path);
  try {
    return file.existsSync() ? file.readAsStringSync() : null;
  } on FileSystemException {
    return null;
  }
}

/// A relative path for messages, from the working directory.
String _display(String path) => p.relative(path);

Future<int> _files(
  List<String> arguments,
  IOSink out,
  IOSink err, {
  required _Mode mode,
  required bool verbose,
  String? explicitConfig,
}) async {
  var exitCode = ExitCode.success;
  void fail(int code, String message) {
    err.writeln(message);
    exitCode = ExitCode.worst(exitCode, code);
  }

  final files = <String>{};
  for (final argument in arguments) {
    final type = FileSystemEntity.typeSync(argument);
    if (type == FileSystemEntityType.file) {
      files.add(p.normalize(p.absolute(argument)));
    } else if (type == FileSystemEntityType.directory) {
      _collect(Directory(argument), files);
    } else if (_isGlob(argument)) {
      for (final entity in Glob(argument).listSync(followLinks: false)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          files.add(p.normalize(p.absolute(entity.path)));
        }
      }
    } else {
      fail(ExitCode.noInput, '$argument: file not found.');
    }
  }

  // Configuration per directory; each distinct error reported once.
  final configs = <String, Object>{};
  final reported = <String>{};
  for (final path in files.toList()..sort()) {
    final directory = p.dirname(path);
    final resolved = configs[directory] ??= () {
      try {
        return resolveConfig(path, read: _read, explicit: explicitConfig);
      } on ConfigException catch (e) {
        return e;
      }
    }();
    if (resolved is ConfigException) {
      if (reported.add(resolved.message)) {
        fail(ExitCode.config, resolved.message);
      }
      continue;
    }
    resolved as ResolvedConfig;
    final pattern = resolved.excludedBy(path);
    if (pattern != null) {
      if (verbose) err.writeln('Skipped ${_display(path)} ($pattern)');
      continue;
    }

    final String source;
    try {
      source = File(path).readAsStringSync();
    } on FileSystemException catch (e) {
      fail(ExitCode.noInput, '${_display(path)}: cannot read: ${e.message}.');
      continue;
    }

    final String output;
    try {
      output = format(source, config: resolved.config);
    } on ParseFailure catch (e) {
      for (final error in e.errors) {
        fail(ExitCode.data, '${_display(path)}:$error');
      }
      continue;
    } on DirectiveException catch (e) {
      fail(ExitCode.data, '${_display(path)}: $e');
      continue;
    } on VerificationFailure catch (e) {
      fail(
        ExitCode.software,
        '${_display(path)}: $e. The file was not changed.',
      );
      continue;
    }
    if (output == source) continue;

    switch (mode) {
      case _Mode.write:
        try {
          _writeAtomically(path, output);
        } on FileSystemException catch (e) {
          fail(
            ExitCode.noInput,
            '${_display(path)}: cannot write: ${e.message}.',
          );
        }
      case _Mode.check:
        out.writeln(_display(path));
        exitCode = ExitCode.worst(exitCode, ExitCode.changes);
      case _Mode.diff:
        final name = _display(path);
        out.write(unifiedDiff(source, output, fromName: name, toName: name));
        exitCode = ExitCode.worst(exitCode, ExitCode.changes);
    }
  }
  return exitCode;
}

bool _isGlob(String argument) => argument.contains(RegExp(r'[*?\[{]'));

/// `.dart` files under [directory], not following links and never entering
/// protected directories.
void _collect(Directory directory, Set<String> files) {
  for (final entity in directory.listSync(followLinks: false)) {
    final name = p.basename(entity.path);
    if (entity is Directory) {
      if (!protectedDirectories.contains(name)) _collect(entity, files);
    } else if (entity is File && name.endsWith('.dart')) {
      files.add(p.normalize(p.absolute(entity.path)));
    }
  }
}

void _writeAtomically(String path, String contents) {
  final temp = File('$path.beaver-$pid.tmp');
  temp.writeAsStringSync(contents, flush: true);
  temp.renameSync(path);
}

Future<int> _stdin(
  Stream<List<int>> input,
  IOSink out,
  IOSink err, {
  required String? name,
  required String? range,
  required String? explicitConfig,
}) async {
  final bytes = await input.fold(<int>[], (all, chunk) => all..addAll(chunk));
  final String source;
  try {
    source = utf8.decode(bytes);
  } on FormatException {
    err.writeln('${name ?? 'stdin'}: input is not valid UTF-8.');
    return ExitCode.data;
  }

  final ResolvedConfig resolved;
  try {
    resolved = name == null
        ? resolveConfig(
            Directory.current.path,
            read: _read,
            explicit: explicitConfig,
            isDirectory: true,
          )
        : resolveConfig(
            p.normalize(p.absolute(name)),
            read: _read,
            explicit: explicitConfig,
          );
  } on ConfigException catch (e) {
    err.writeln(e.message);
    return ExitCode.config;
  }
  if (name != null &&
      resolved.excludedBy(p.normalize(p.absolute(name))) != null) {
    // Excluded: echo unchanged, never parsed.
    out.write(source);
    return ExitCode.success;
  }

  final label = name ?? 'stdin';
  try {
    final output = range == null
        ? format(source, config: resolved.config)
        : formatRange(source, parseRange(range), config: resolved.config);
    out.write(output);
    return ExitCode.success;
  } on RangeException catch (e) {
    err.writeln('--range: ${e.message}');
    return ExitCode.usage;
  } on ParseFailure catch (e) {
    for (final error in e.errors) {
      err.writeln('$label:$error');
    }
    return ExitCode.data;
  } on DirectiveException catch (e) {
    err.writeln('$label: $e');
    return ExitCode.data;
  } on VerificationFailure catch (e) {
    err.writeln('$label: $e');
    return ExitCode.software;
  }
}

Future<int> _printConfig(
  String? forFile,
  String? explicitConfig,
  IOSink out,
  IOSink err,
) async {
  final ResolvedConfig resolved;
  try {
    resolved = forFile == null
        ? resolveConfig(
            Directory.current.path,
            read: _read,
            explicit: explicitConfig,
            isDirectory: true,
          )
        : resolveConfig(
            p.normalize(p.absolute(forFile)),
            read: _read,
            explicit: explicitConfig,
          );
  } on ConfigException catch (e) {
    err.writeln(e.message);
    return ExitCode.config;
  }
  out.writeln('# Chain: ${resolved.chain.map(_origin).join(' → ')}');
  out.writeln('# Exclusion root: ${_display(resolved.root)}');
  for (final key in schema.keys) {
    final value = resolved.config.values[key];
    out.writeln(
      '$key: ${value is List ? jsonEncode(value) : value}'
      '  # ${resolved.provenance[key]!.split(', ').map(_origin).join(', ')}',
    );
  }
  return ExitCode.success;
}

String _origin(String origin) =>
    origin.startsWith('preset ') ? origin : _display(origin);

Future<int> _init(IOSink out, IOSink err) async {
  final file = File(configFileName);
  if (file.existsSync()) {
    err.writeln('$configFileName already exists; not overwriting it.');
    return ExitCode.usage;
  }
  file.writeAsStringSync(_starter);
  out.writeln('Wrote $configFileName.');
  return ExitCode.success;
}

const _starter = '''
# Beaver configuration. Every key is optional; unset keys come from `extends`.
# Run `beaver config --print` to see the resolved values and their origin.
extends: dart

# line_length: 80
# indent:
#   size: 2
#   style: spaces            # spaces | tabs
#   continuation: 4
#   switch_cases: true
#   align:
#     arguments: false
#     parameters: false
#     chained_calls: false
# wrap:                       # never | if_long | chop_if_long | chop_always
#   arguments: chop_if_long
#   parameters: chop_if_long
#   collection_literals: chop_if_long
#   binary_expressions: chop_if_long
#   conditional_expressions: chop_if_long
#   before_operator: false
#   chained_calls:
#     policy: chop_if_long
#     min_calls: 0             # 0 disables count-based chopping
#     keep_single_line_if_fits: true
#   keep_existing_line_breaks: true
#   chop_on_trailing_comma: true
#   simple_blocks_on_one_line: false
#   simple_lambdas_on_one_line: false
#   chop_on_named_arguments: []    # e.g. [child, children]
# trailing_commas: add_when_wrapped   # preserve | remove | add_when_wrapped
# spaces:
#   around_assignment: true
#   around_binary_operators: true
#   around_arrow: true
#   after_comma: true
#   before_comma: false
#   after_colon_in_named_argument: true
#   inside_parentheses: false
#   inside_brackets: false
#   inside_braces: false
#   before_control_parentheses: true
#   in_empty_braces: false
#   after_cast: true
# blank_lines:
#   max_consecutive: 1
#   after_imports: 1
#   between_members: 1
#   before_first_member: 0
#   around_class_declarations: 1
# braces:
#   else_on_new_line: false
# strings:
#   quotes: preserve           # preserve | single | double
# exclude:                     # added to the inherited exclusions
#   - "**/*.pb.dart"
''';
