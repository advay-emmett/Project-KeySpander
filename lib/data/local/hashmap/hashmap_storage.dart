import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class HashMapStorage {
  HashMapStorage();

  Map<String, String> _data = {};
  File? _file;

  Map<String, String> get data => Map.unmodifiable(_data);

  int get length => _data.length;

  String? get(String key) => _data[key];

  bool containsKey(String key) => _data.containsKey(key);

  Future<void> init() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();

    final keySpanderDirectory = Directory(
      '${documentsDirectory.path}/KeySpander',
    );

    await keySpanderDirectory.create(recursive: true);

    final jsonFile = File('${keySpanderDirectory.path}/keyspander.json');
    _file = jsonFile;

    if (!await jsonFile.exists()) {
      _data = {};
      await _write();
    } else {
      await _read();
    }

    final exeExtension = Platform.isWindows ? '.exe' : '';
    final assetName = 'keyspander_backend$exeExtension';

    final executableFile = File('${keySpanderDirectory.path}/$assetName');

    if (!await executableFile.exists()) {
      final byteData = await rootBundle.load('assets/$assetName');

      await executableFile.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
        flush: true,
      );
    }

    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', executableFile.path]);
    }
  }

  Future<bool> put(String key, String value) async {
    key = key.trim();

    if (key.isEmpty || _data.containsKey(key)) {
      return false;
    }

    _data[key] = value;
    await _write();

    return true;
  }

  Future<bool> update(String oldKey, String newKey, String value) async {
    oldKey = oldKey.trim();
    newKey = newKey.trim();

    if (oldKey.isEmpty || newKey.isEmpty) {
      return false;
    }

    if (!_data.containsKey(oldKey)) {
      return false;
    }

    if (oldKey != newKey && _data.containsKey(newKey)) {
      return false;
    }

    _data.remove(oldKey);
    _data[newKey] = value;

    await _write();

    return true;
  }

  Future<bool> remove(String key) async {
    if (!_data.containsKey(key)) {
      return false;
    }

    _data.remove(key);
    await _write();

    return true;
  }

  Future<void> clear() async {
    _data.clear();
    await _write();
  }

  Future<void> _read() async {
    final file = _file;

    if (file == null) {
      throw StateError('HashMapStorage.init() must be called first.');
    }

    try {
      final contents = await file.readAsString();

      if (contents.trim().isEmpty) {
        _data = {};
        return;
      }

      final decoded = jsonDecode(contents);

      if (decoded is! Map) {
        throw const FormatException('Invalid JSON format. Expected an object.');
      }

      _data = decoded.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } on FormatException {
      _data = {};
    }
  }

  Future<void> _write() async {
    final file = _file;

    if (file == null) {
      throw StateError('HashMapStorage.init() must be called first.');
    }

    final contents = const JsonEncoder.withIndent('  ').convert(_data);

    await file.writeAsString(contents, flush: true);
  }
}

Future<void> runPythonExe() async {
  try {
    final documentsDirectory = await getApplicationDocumentsDirectory();

    final targetFolder = '${documentsDirectory.path}/KeySpander';

    final exeExtension = Platform.isWindows ? '.exe' : '';
    final assetName = 'keyspander_backend$exeExtension';

    final executableFile = File('$targetFolder/$assetName');

    await Directory(targetFolder).create(recursive: true);

    if (!await executableFile.exists()) {
      final byteData = await rootBundle.load('assets/$assetName');

      await executableFile.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
        flush: true,
      );
    }

    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', executableFile.path]);
    }

    final process = await Process.start(executableFile.path, [
      '--arg1',
      'value1',
    ], workingDirectory: targetFolder);

    process.stdout.transform(utf8.decoder).listen((data) {
      print('Python Output: $data');
    });

    process.stderr.transform(utf8.decoder).listen((data) {
      print('Python Error: $data');
    });
  } catch (e, stackTrace) {
    print('Failed to execute Python binary: $e');
    print(stackTrace);
  }
}
