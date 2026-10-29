// Formatting from Dart code. Most projects use the `beaver` command instead:
// `dart install zooper_beaver`, then `beaver .` in the project.
import 'package:zooper_beaver/zooper_beaver.dart';

void main() {
  const source = 'void main(){print( "hi" );}';

  // The built-in `dart` preset.
  print(format(source));

  // The same settings a `.beaver.yaml` holds, as dotted keys.
  final config = BeaverConfig.dart.merge({
    'line_length': 100,
    'strings.quotes': 'single',
  });
  print(format(source, config: config));
}
