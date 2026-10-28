import 'dart:io';

import 'package:zooper_beaver/src/cli/cli.dart';

Future<void> main(List<String> arguments) async {
  final code = await runCli(arguments);
  await Future.wait([stdout.flush(), stderr.flush()]);
  exit(code);
}
