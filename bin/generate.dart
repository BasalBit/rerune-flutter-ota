import 'dart:io';

const _defaultArbDir = 'lib/l10n';
const _defaultLocalizationFile = 'app_localizations.dart';
const _defaultLocalizationClass = 'AppLocalizations';

class _L10nConfig {
  const _L10nConfig({
    this.arbDir = _defaultArbDir,
    this.outputDir,
    this.outputLocalizationFile = _defaultLocalizationFile,
    this.outputClass = _defaultLocalizationClass,
  });

  final String arbDir;
  final String? outputDir;
  final String outputLocalizationFile;
  final String outputClass;

  String get effectiveOutputDir => outputDir ?? arbDir;
}

void main(List<String> args) {
  runGenerate(args);
}

void runGenerate(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final options = _parseArgs(args);
  if (options == null) {
    _printUsage();
    exitCode = 64;
    return;
  }

  final l10nConfig = _readL10nConfig();
  final inputPath = options['input'] ?? _defaultInputPath(l10nConfig);
  if (inputPath == null) {
    stderr.writeln('Could not locate app_localizations.dart automatically.');
    stderr.writeln(
      'Pass --input <path-to-app_localizations.dart> or check l10n.yaml.',
    );
    exitCode = 66;
    return;
  }

  final outputPath =
      options['output'] ??
      _defaultOutputPath(inputPath: inputPath, l10nConfig: l10nConfig);
  final className = options['class'] ?? l10nConfig.outputClass;
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

_L10nConfig _readL10nConfig() {
  final file = File('l10n.yaml');
  if (!file.existsSync()) {
    return const _L10nConfig();
  }

  var arbDir = _defaultArbDir;
  String? outputDir;
  var outputLocalizationFile = _defaultLocalizationFile;
  var outputClass = _defaultLocalizationClass;

  for (final rawLine in file.readAsStringSync().split('\n')) {
    final entry = _parseTopLevelYamlScalar(rawLine);
    if (entry == null) {
      continue;
    }

    switch (entry.key) {
      case 'arb-dir':
        arbDir = _normalizePath(entry.value);
        break;
      case 'output-dir':
        outputDir = _normalizePath(entry.value);
        break;
      case 'output-localization-file':
        outputLocalizationFile = _normalizePath(entry.value);
        break;
      case 'output-class':
        outputClass = entry.value;
        break;
    }
  }

  return _L10nConfig(
    arbDir: arbDir,
    outputDir: outputDir,
    outputLocalizationFile: outputLocalizationFile,
    outputClass: outputClass,
  );
}

MapEntry<String, String>? _parseTopLevelYamlScalar(String rawLine) {
  if (rawLine.trim().isEmpty) {
    return null;
  }

  final trimmedLeft = rawLine.trimLeft();
  if (trimmedLeft.startsWith('#')) {
    return null;
  }

  if (trimmedLeft.length != rawLine.length) {
    return null;
  }

  final separator = trimmedLeft.indexOf(':');
  if (separator <= 0) {
    return null;
  }

  final key = trimmedLeft.substring(0, separator).trim();
  if (key.isEmpty) {
    return null;
  }

  var value = trimmedLeft.substring(separator + 1).trim();
  value = _trimYamlInlineComment(value);
  value = _stripYamlQuotes(value);
  value = value.trim();
  if (value.isEmpty) {
    return null;
  }
  return MapEntry(key, value);
}

String _trimYamlInlineComment(String value) {
  var inSingleQuote = false;
  var inDoubleQuote = false;

  for (var i = 0; i < value.length; i++) {
    final char = value[i];
    if (char == "'" && !inDoubleQuote) {
      inSingleQuote = !inSingleQuote;
      continue;
    }
    if (char == '"' && !inSingleQuote) {
      inDoubleQuote = !inDoubleQuote;
      continue;
    }
    if (char == '#' && !inSingleQuote && !inDoubleQuote) {
      if (i == 0 || value[i - 1] == ' ' || value[i - 1] == '\t') {
        return value.substring(0, i).trimRight();
      }
    }
  }

  return value;
}

String _stripYamlQuotes(String value) {
  if (value.length >= 2 && value.startsWith("'") && value.endsWith("'")) {
    return value.substring(1, value.length - 1);
  }
  if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
    return value.substring(1, value.length - 1);
  }
  return value;
}

String? _defaultInputPath(_L10nConfig l10nConfig) {
  final configuredPath = _joinPath(
    l10nConfig.effectiveOutputDir,
    l10nConfig.outputLocalizationFile,
  );
  final configuredLegacyPath = _joinPath(
    '.dart_tool/flutter_gen/gen_l10n',
    _basename(l10nConfig.outputLocalizationFile),
  );

  final candidates = [
    configuredPath,
    configuredLegacyPath,
    'lib/l10n/gen/app_localizations.dart',
    'lib/l10n/app_localizations.dart',
    '.dart_tool/flutter_gen/gen_l10n/app_localizations.dart',
  ];

  for (final path in candidates) {
    if (File(path).existsSync()) {
      return path;
    }
  }

  final desiredFileNames = {
    _basename(l10nConfig.outputLocalizationFile),
    _defaultLocalizationFile,
  };

  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    return null;
  }

  final discovered = libDir
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .map((file) => _normalizePath(file.path))
      .where((path) => desiredFileNames.contains(_basename(path)))
      .toList(growable: false);
  if (discovered.isEmpty) {
    return null;
  }

  final sorted = discovered.toList(growable: true)
    ..sort((a, b) {
      final scoreA = _inputPathScore(a, configuredPath: configuredPath);
      final scoreB = _inputPathScore(b, configuredPath: configuredPath);
      if (scoreA != scoreB) {
        return scoreA.compareTo(scoreB);
      }
      return a.length.compareTo(b.length);
    });
  return sorted.first;
}

int _inputPathScore(String path, {required String configuredPath}) {
  if (_normalizePath(path) == _normalizePath(configuredPath)) {
    return 0;
  }
  if (path.contains('/l10n/gen/')) {
    return 1;
  }
  if (path.contains('/l10n/')) {
    return 2;
  }
  if (path.startsWith('.dart_tool/')) {
    return 3;
  }
  return 4;
}

String _defaultOutputPath({
  required String inputPath,
  required _L10nConfig l10nConfig,
}) {
  final inputFileName = _basename(inputPath);
  final wrapperFileName = 'rerune_$inputFileName';
  final normalized = _normalizePath(inputPath);

  if (normalized.startsWith('.dart_tool/')) {
    return _joinPath(l10nConfig.effectiveOutputDir, wrapperFileName);
  }

  final slash = normalized.lastIndexOf('/');
  if (slash <= 0) {
    return wrapperFileName;
  }

  final directory = normalized.substring(0, slash);
  return '$directory/$wrapperFileName';
}

String _normalizePath(String value) {
  var normalized = value.replaceAll('\\', '/');
  while (normalized.contains('//')) {
    normalized = normalized.replaceAll('//', '/');
  }
  return normalized;
}

String _joinPath(String left, String right) {
  final normalizedRight = _normalizePath(right);
  if (_isAbsolutePath(normalizedRight)) {
    return normalizedRight;
  }
  final normalizedLeft = _normalizePath(left);
  if (normalizedLeft.isEmpty) {
    return normalizedRight;
  }
  if (normalizedLeft.endsWith('/')) {
    return '$normalizedLeft$normalizedRight';
  }
  return '$normalizedLeft/$normalizedRight';
}

bool _isAbsolutePath(String value) {
  if (value.startsWith('/')) {
    return true;
  }
  return RegExp(r'^[A-Za-z]:/').hasMatch(value);
}

String _basename(String path) {
  final normalized = _normalizePath(path);
  final slash = normalized.lastIndexOf('/');
  if (slash < 0 || slash == normalized.length - 1) {
    return normalized;
  }
  return normalized.substring(slash + 1);
}

void _printUsage() {
  stdout.writeln('Generate a typed Rerune OTA wrapper for AppLocalizations.');
  stdout.writeln('');
  stdout.writeln('Usage:');
  stdout.writeln('  flutter pub run rerune [options]');
  stdout.writeln('  dart run rerune [options]');
  stdout.writeln('  Auto-detect follows Flutter l10n.yaml defaults.');
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln(
    '  --input <path>   Path to app_localizations.dart (auto if omitted)',
  );
  stdout.writeln(
    '  --output <path>  Output file path (same folder by default)',
  );
  stdout.writeln(
    '  --class <name>   Localization class name (l10n.yaml or AppLocalizations)',
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
  buffer.writeln("import 'package:rerune/rerune.dart';");
  buffer.writeln('');
  buffer.writeln("import '$appLocalizationsImport';");
  buffer.writeln('');
  buffer.writeln(
    'class Rerune${className}Delegate extends LocalizationsDelegate<$className> {',
  );
  buffer.writeln(
    '  const Rerune${className}Delegate({required this.controller});',
  );
  buffer.writeln('');
  buffer.writeln('  final OtaLocalizationController controller;');
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
  buffer.writeln('    return old.controller != controller;');
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
  buffer.writeln('class ReRune {');
  buffer.writeln('  static OtaLocalizationController? _controller;');
  buffer.writeln('');
  buffer.writeln('  static void setup({');
  buffer.writeln('    String? projectId,');
  buffer.writeln('    String? apiKey,');
  buffer.writeln('    Uri? manifestUrl,');
  buffer.writeln('    CacheStore? cacheStore,');
  buffer.writeln('    OtaUpdatePolicy? updatePolicy,');
  buffer.writeln('  }) {');
  buffer.writeln('    final controller = OtaLocalizationController(');
  buffer.writeln('      supportedLocales: $className.supportedLocales,');
  buffer.writeln('      projectId: projectId,');
  buffer.writeln('      apiKey: apiKey,');
  buffer.writeln('      manifestUrl: manifestUrl,');
  buffer.writeln('      cacheStore: cacheStore,');
  buffer.writeln('      updatePolicy: updatePolicy,');
  buffer.writeln('    );');
  buffer.writeln('    _controller?.removeListener(_handleControllerChange);');
  buffer.writeln('    _controller = controller;');
  buffer.writeln('    controller.addListener(_handleControllerChange);');
  buffer.writeln('    controller.initialize();');
  buffer.writeln('  }');
  buffer.writeln('');
  buffer.writeln(
    '  static OtaLocalizationController get controller => _requireController();',
  );
  buffer.writeln('');
  buffer.writeln('  static Future<OtaUpdateResult> checkForUpdates() {');
  buffer.writeln('    return _requireController().checkForUpdates();');
  buffer.writeln('  }');
  buffer.writeln('');
  buffer.writeln(
    '  static List<LocalizationsDelegate<dynamic>> get localizationsDelegates {',
  );
  buffer.writeln('    final controller = _requireController();');
  buffer.writeln('    return [');
  buffer.writeln('      Rerune${className}Delegate(controller: controller),');
  buffer.writeln(
    '      ...$className.localizationsDelegates.where((delegate) => delegate.type != $className),',
  );
  buffer.writeln('    ];');
  buffer.writeln('  }');
  buffer.writeln('');
  buffer.writeln(
    '  static List<Locale> get supportedLocales => $className.supportedLocales;',
  );
  buffer.writeln('');
  buffer.writeln('  static OtaLocalizationController _requireController() {');
  buffer.writeln('    final current = _controller;');
  buffer.writeln('    if (current != null) {');
  buffer.writeln('      return current;');
  buffer.writeln('    }');
  buffer.writeln('    throw StateError(');
  buffer.writeln(
    "      'ReRune.setup(...) must be called before accessing ReRune delegates/locales.',",
  );
  buffer.writeln('    );');
  buffer.writeln('  }');
  buffer.writeln('');
  buffer.writeln('  static void _handleControllerChange() {');
  buffer.writeln('    final root = WidgetsBinding.instance.rootElement;');
  buffer.writeln('    if (root == null) {');
  buffer.writeln('      return;');
  buffer.writeln('    }');
  buffer.writeln('    root.markNeedsBuild();');
  buffer.writeln('    WidgetsBinding.instance.scheduleFrame();');
  buffer.writeln('  }');
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
    final fileName = _basename(normalizedInput);
    return 'package:flutter_gen/gen_l10n/$fileName';
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
