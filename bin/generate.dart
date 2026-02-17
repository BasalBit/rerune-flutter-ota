import 'dart:io';

void main(List<String> args) {
  final options = _parseArgs(args);
  if (options == null) {
    _printUsage();
    exitCode = 64;
    return;
  }

  final inputPath = options['input'] ?? _defaultInputPath();
  if (inputPath == null) {
    stderr.writeln('Could not locate app_localizations.dart automatically.');
    stderr.writeln('Pass --input <path-to-app_localizations.dart>.');
    exitCode = 66;
    return;
  }

  final outputPath =
      options['output'] ?? 'lib/l10n/rerune_app_localizations.dart';
  final className = options['class'] ?? 'AppLocalizations';
  final appLocalizationsImport = _resolveAppLocalizationsImport(
    inputPath: inputPath,
    outputPath: outputPath,
  );
  final generated = _generateWrapper(
    inputPath: inputPath,
    className: className,
    appLocalizationsImport: appLocalizationsImport,
  );
  if (generated == null) {
    stderr.writeln('Failed to parse $className in $inputPath.');
    exitCode = 65;
    return;
  }

  final outputFile = File(outputPath);
  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsStringSync(generated);
  stdout.writeln('Generated OTA wrapper: $outputPath');
}

Map<String, String>? _parseArgs(List<String> args) {
  final options = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--help' || arg == '-h') {
      return null;
    }
    if (!arg.startsWith('--')) {
      stderr.writeln('Unexpected argument: $arg');
      return null;
    }
    if (i + 1 >= args.length) {
      stderr.writeln('Missing value for $arg');
      return null;
    }
    options[arg.substring(2)] = args[++i];
  }
  return options;
}

String? _defaultInputPath() {
  const candidates = [
    'lib/l10n/app_localizations.dart',
    '.dart_tool/flutter_gen/gen_l10n/app_localizations.dart',
  ];
  for (final path in candidates) {
    if (File(path).existsSync()) {
      return path;
    }
  }
  return null;
}

void _printUsage() {
  stdout.writeln('Generate a typed Rerune OTA wrapper for AppLocalizations.');
  stdout.writeln('');
  stdout.writeln('Usage:');
  stdout.writeln('  dart run rerune_flutter_ota:generate [options]');
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln('  --input <path>   Path to app_localizations.dart');
  stdout.writeln('  --output <path>  Output Dart file path');
  stdout.writeln(
    '  --class <name>   Localization class name (default AppLocalizations)',
  );
}

String? _generateWrapper({
  required String inputPath,
  required String className,
  required String appLocalizationsImport,
}) {
  final source = File(inputPath).readAsStringSync();
  final abstractMatch = RegExp(
    'abstract\\s+class\\s+$className\\s*\\{([\\s\\S]*?)^}',
    multiLine: true,
  ).firstMatch(source);
  if (abstractMatch == null) {
    return null;
  }

  final body = abstractMatch.group(1)!;
  final getters = RegExp(
    r'^\s*String\s+get\s+(\w+)\s*;',
    multiLine: true,
  ).allMatches(body).map((m) => m.group(1)!).toList(growable: false);

  final methods =
      RegExp(r'^\s*String\s+(\w+)\s*\(([^;]*)\)\s*;', multiLine: true)
          .allMatches(body)
          .map((m) {
            final name = m.group(1)!;
            final params = m.group(2)!.trim();
            return _MethodSpec(
              name: name,
              params: params,
              parsed: _parseParams(params),
            );
          })
          .toList(growable: false);

  final buffer = StringBuffer();
  buffer.writeln("import 'package:flutter/widgets.dart';");
  buffer.writeln(
    "import 'package:rerune_flutter_ota/rerune_flutter_ota.dart';",
  );
  buffer.writeln('');
  buffer.writeln("import '$appLocalizationsImport';");
  buffer.writeln('');
  buffer.writeln(
    'class Rerune${className}Delegate extends LocalizationsDelegate<$className> {',
  );
  buffer.writeln(
    '  const Rerune${className}Delegate({required this.controller, required this.revision});',
  );
  buffer.writeln('');
  buffer.writeln('  final OtaLocalizationController controller;');
  buffer.writeln('  final int revision;');
  buffer.writeln('');
  buffer.writeln('  @override');
  buffer.writeln(
    '  bool isSupported(Locale locale) => $className.delegate.isSupported(locale);',
  );
  buffer.writeln('');
  buffer.writeln('  @override');
  buffer.writeln('  Future<$className> load(Locale locale) async {');
  buffer.writeln('    final base = await $className.delegate.load(locale);');
  buffer.writeln('    return _Rerune$className(base, controller, locale);');
  buffer.writeln('  }');
  buffer.writeln('');
  buffer.writeln('  @override');
  buffer.writeln(
    '  bool shouldReload(covariant Rerune${className}Delegate old) {',
  );
  buffer.writeln(
    '    return old.revision != revision || old.controller != controller;',
  );
  buffer.writeln('  }');
  buffer.writeln('}');
  buffer.writeln('');
  buffer.writeln('class _Rerune$className extends $className {');
  buffer.writeln(
    '  _Rerune$className(this._base, this._controller, this._locale) : super(_base.localeName);',
  );
  buffer.writeln('');
  buffer.writeln('  final $className _base;');
  buffer.writeln('  final OtaLocalizationController _controller;');
  buffer.writeln('  final Locale _locale;');

  for (final getter in getters) {
    buffer.writeln('');
    buffer.writeln('  @override');
    buffer.writeln('  String get $getter {');
    buffer.writeln('    final fallback = _base.$getter;');
    buffer.writeln(
      "    return _controller.resolveText(_locale, key: '$getter', fallback: fallback);",
    );
    buffer.writeln('  }');
  }

  for (final method in methods) {
    final callArgs = method.parsed.callArgs.join(', ');
    final argsMap = method.parsed.paramNames
        .map((name) => "'$name': $name")
        .join(', ');
    buffer.writeln('');
    buffer.writeln('  @override');
    buffer.writeln('  String ${method.name}(${method.params}) {');
    if (callArgs.isEmpty) {
      buffer.writeln('    final fallback = _base.${method.name}();');
    } else {
      buffer.writeln('    final fallback = _base.${method.name}($callArgs);');
    }
    if (argsMap.isEmpty) {
      buffer.writeln(
        "    return _controller.resolveText(_locale, key: '${method.name}', fallback: fallback);",
      );
    } else {
      buffer.writeln(
        "    return _controller.resolveText(_locale, key: '${method.name}', fallback: fallback, args: {$argsMap});",
      );
    }
    buffer.writeln('  }');
  }
  buffer.writeln('}');
  buffer.writeln('');
  buffer.writeln('class Rerune${className}Setup {');
  buffer.writeln(
    '  static List<LocalizationsDelegate<dynamic>> localizationsDelegates(',
  );
  buffer.writeln('    LocalizationsDelegate<$className> otaDelegate,');
  buffer.writeln('  ) {');
  buffer.writeln('    return [');
  buffer.writeln('      otaDelegate,');
  buffer.writeln(
    '      ...$className.localizationsDelegates.where((delegate) => delegate.type != $className),',
  );
  buffer.writeln('    ];');
  buffer.writeln('  }');
  buffer.writeln('');
  buffer.writeln(
    '  static List<Locale> get supportedLocales => $className.supportedLocales;',
  );
  buffer.writeln('}');
  return buffer.toString();
}

class _MethodSpec {
  _MethodSpec({required this.name, required this.params, required this.parsed});

  final String name;
  final String params;
  final _ParsedParams parsed;
}

class _ParsedParams {
  _ParsedParams({required this.paramNames, required this.callArgs});

  final List<String> paramNames;
  final List<String> callArgs;
}

_ParsedParams _parseParams(String params) {
  if (params.trim().isEmpty) {
    return _ParsedParams(paramNames: const [], callArgs: const []);
  }
  final names = <String>[];
  final callArgs = <String>[];
  var mode = _ParamMode.positional;
  for (final segment in _splitTopLevel(params)) {
    var part = segment.trim();
    if (part.isEmpty) {
      continue;
    }
    if (part.contains('{')) {
      mode = _ParamMode.named;
    } else if (part.contains('[')) {
      mode = _ParamMode.optionalPositional;
    }
    part = part.replaceAll('{', '').replaceAll('}', '');
    part = part.replaceAll('[', '').replaceAll(']', '');
    part = part.trim();
    if (part.isEmpty) {
      continue;
    }
    if (part.startsWith('required ')) {
      part = part.substring('required '.length).trim();
    }
    final declaration = part.split('=').first.trim();
    if (declaration.isEmpty) {
      continue;
    }
    final tokens = declaration.split(RegExp(r'\s+'));
    if (tokens.isEmpty) {
      continue;
    }
    final name = tokens.last.trim();
    if (name.isEmpty) {
      continue;
    }
    names.add(name);
    if (mode == _ParamMode.named) {
      callArgs.add('$name: $name');
    } else {
      callArgs.add(name);
    }
  }
  return _ParsedParams(paramNames: names, callArgs: callArgs);
}

List<String> _splitTopLevel(String input) {
  final parts = <String>[];
  final buffer = StringBuffer();
  var angle = 0;
  var paren = 0;
  var brace = 0;
  var bracket = 0;
  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    if (char == '<') {
      angle++;
    } else if (char == '>') {
      if (angle > 0) {
        angle--;
      }
    } else if (char == '(') {
      paren++;
    } else if (char == ')') {
      if (paren > 0) {
        paren--;
      }
    } else if (char == '{') {
      brace++;
    } else if (char == '}') {
      if (brace > 0) {
        brace--;
      }
    } else if (char == '[') {
      bracket++;
    } else if (char == ']') {
      if (bracket > 0) {
        bracket--;
      }
    }
    if (char == ',' && angle == 0 && paren == 0 && brace == 0 && bracket == 0) {
      parts.add(buffer.toString());
      buffer.clear();
      continue;
    }
    buffer.write(char);
  }
  if (buffer.isNotEmpty) {
    parts.add(buffer.toString());
  }
  return parts;
}

enum _ParamMode { positional, optionalPositional, named }

String _resolveAppLocalizationsImport({
  required String inputPath,
  required String outputPath,
}) {
  final normalizedInput = inputPath.replaceAll('\\\\', '/');
  if (normalizedInput.contains('.dart_tool/flutter_gen/gen_l10n/')) {
    return 'package:flutter_gen/gen_l10n/app_localizations.dart';
  }
  return _relativeImport(fromFile: outputPath, toFile: inputPath);
}

String _relativeImport({required String fromFile, required String toFile}) {
  final from = fromFile.replaceAll('\\\\', '/').split('/');
  final to = toFile.replaceAll('\\\\', '/').split('/');
  if (from.length < 2 || to.isEmpty) {
    return toFile;
  }

  final fromDir = from.sublist(0, from.length - 1);
  var common = 0;
  while (common < fromDir.length && common < to.length) {
    if (fromDir[common] != to[common]) {
      break;
    }
    common++;
  }

  final segments = <String>[
    ...List.filled(fromDir.length - common, '..'),
    ...to.sublist(common),
  ];
  if (segments.isEmpty) {
    return to.last;
  }
  return segments.join('/');
}
