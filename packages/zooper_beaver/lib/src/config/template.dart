/// The reference template printed by `beaver config --template`: every
/// canonical key with its `dart` preset value and allowed values.
library;

import 'dart:convert';

import 'config.dart';
import 'schema.dart';

/// Examples for list keys whose preset value is empty.
const _examples = {
  'wrap.chop_on_named_arguments': '[child, children]',
  'wrap.chop_on_calls': '[Row, Column]',
};

/// The template, generated from [schema] (in its order) and the preset.
String configTemplate() {
  final lists = {for (final list in listConstructs) 'wrap.${list.name}'};
  final out = StringBuffer(
    '# Every Beaver setting with its `dart` preset value and, in the comment,\n'
    '# the allowed values. Copy it to .beaver.yaml and delete the lines you\n'
    '# do not want to pin; unset keys come from the preset.\n',
  );
  var open = <String>[];
  for (final MapEntry(:key, value: type) in schema.entries) {
    final path = key.split('.');
    var shared = 0;
    while (shared < open.length &&
        shared < path.length - 1 &&
        open[shared] == path[shared]) {
      shared++;
    }
    for (var depth = shared; depth < path.length - 1; depth++) {
      final prefix = path.take(depth + 1).join('.');
      out.writeln(
        '${'  ' * depth}${path[depth]}:'
        '${lists.contains(prefix) ? '  # or the shorthand ${path[depth]}: <policy>' : ''}',
      );
    }
    open = path.sublist(0, path.length - 1);

    final pad = '  ' * (path.length - 1);
    final value = BeaverConfig.dart.settings[key];
    final example = _examples[key];
    final comment =
        '# ${type.describe()}${example == null ? '' : ', e.g. $example'}';
    if (value is List && value.isNotEmpty) {
      out.writeln('$pad${path.last}:  $comment');
      for (final item in value) {
        out.writeln('$pad  - ${jsonEncode(item)}');
      }
    } else {
      out.writeln(
        '$pad${path.last}: ${value is List ? '[]' : value}  $comment',
      );
    }
  }
  return '$out';
}
