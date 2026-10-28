/// The formatting pipeline. The only place verification runs.
library;

import 'package:analyzer/dart/ast/ast.dart';

import 'comments/attach.dart';
import 'directives/directives.dart';
import 'config/config.dart';
import 'emit/emit.dart';
import 'ir/doc.dart';
import 'ir/printer.dart';
import 'parse/parse.dart';
import 'rules/builder.dart';
import 'verify/verify.dart';

/// Test-only: alters the formatted text before verification, to prove that
/// a formatting defect is caught.
String Function(String output)? debugCorruptOutput;

/// Formats a whole compilation unit. Every line gets [leadingIndent] extra
/// spaces (harness setting for golden `(indent N)` cases).
String format(
  String source, {
  BeaverConfig? config,
  int leadingIndent = 0,
  List<String> experiments = const [],
}) {
  config ??= BeaverConfig.dart;
  final parsed = parse(source, experiments: experiments);
  final (output, regions) = _layout(
    parsed,
    config,
    leadingIndent,
    (builder) => builder.visit(parsed.unit),
  );
  final result = debugCorruptOutput?.call(output) ?? output;
  verify(
    parsed,
    result,
    config: config,
    regions: regions,
    experiments: experiments,
  );
  return result;
}

const _statementPrefix = 'void __beaver__() {\n';

/// Formats [source] as a statement (or several): the test entry point for
/// `.stmt` golden files. The statement is parsed inside a synthetic function
/// whose text never reaches the output.
String formatStatement(
  String source, {
  BeaverConfig? config,
  int leadingIndent = 0,
  List<String> experiments = const [],
}) {
  config ??= BeaverConfig.dart;
  final wrapped = '$_statementPrefix$source\n}\n';
  final parsed = parse(wrapped, experiments: experiments);
  final function = parsed.unit.declarations.single as FunctionDeclaration;
  final block = (function.functionExpression.body as BlockFunctionBody).block;
  final (output, regions) = _layout(parsed, config, leadingIndent, (builder) {
    final dangling = builder.danglingLines(block.rightBracket);
    return concat([
      builder.sequence(block.statements),
      if (dangling != null) ...[
        if (block.statements.isNotEmpty) hardline,
        dangling,
      ],
    ]);
  });
  final result = debugCorruptOutput?.call(output) ?? output;
  // Verified inside the same wrapper, which is identical on both sides.
  verify(
    parsed,
    '$_statementPrefix$result\n}\n',
    config: config,
    regions: regions,
    experiments: experiments,
  );
  return result;
}

/// [parsed]'s source with [units] (consecutive items of one list) formatted
/// at [leadingLevels] indentation and every other byte unchanged; the whole
/// result is verified. The range-formatting back end.
String formatUnits(
  ParsedSource parsed,
  List<AstNode> units, {
  required BeaverConfig config,
  required int leadingLevels,
  List<String> experiments = const [],
}) {
  final source = parsed.source;
  late final int start;
  late final int end;
  final (text, regions) = _layout(
    parsed,
    config,
    0,
    (builder) {
      start = builder.startWithComments(units.first);
      end = [
        units.last.end,
        for (final c
            in builder.comments.trailing[units.last] ?? <SourceComment>[])
          c.end,
      ].reduce((a, b) => a > b ? a : b);
      return builder.sequence(units);
    },
    leadingLevels: leadingLevels,
    printedRange: () => (start, end),
  );
  // The line's indentation before the first unit and the line ending after
  // the last one are outside the replaced bytes.
  final formatted = text.trimLeft().replaceFirst(RegExp(r'\r?\n$'), '');
  final output = source.replaceRange(start, end, formatted);
  final result = debugCorruptOutput?.call(output) ?? output;
  verify(
    parsed,
    result,
    config: config,
    regions: regions,
    experiments: experiments,
  );
  return result;
}

/// Builds, prints and emits; returns the text and the ignored regions.
(String, List<(int, int)>) _layout(
  ParsedSource parsed,
  BeaverConfig config,
  int leadingIndent,
  Doc Function(DocBuilder) build, {
  int leadingLevels = 0,
  (int, int) Function()? printedRange,
}) {
  final source = parsed.source;
  final comments = attachComments(parsed.unit, source);
  final directives = findDirectives(comments, parsed);
  final builder = DocBuilder(source, config, comments, directives);
  final doc = build(builder);
  // Range formatting prints only the comments in its range.
  final range = printedRange?.call();
  final unprinted = builder.unprinted
      .where(
        (c) => range == null || (c.offset >= range.$1 && c.end <= range.$2),
      )
      .toList();
  if (unprinted.isNotEmpty) {
    throw VerificationFailure(
      'comments',
      'Comments not placed: ${unprinted.map((c) => c.text).join(', ')}.',
    );
  }
  final commands = printDoc(
    doc,
    lineLength: config.lineLength,
    indentSize: config.indentSize,
    leadingIndent: leadingIndent,
    leadingLevels: leadingLevels,
  );
  final output = emit(
    commands,
    style: config.indentStyle,
    indentSize: config.indentSize,
    lineEnding: detectLineEnding(source),
    source: source,
  );
  return (output, directives.regions);
}
