import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const String _fileName = 'data.json';

Future<File> _getJsonFile() async {
  final directory = await getApplicationDocumentsDirectory();

  return File('${directory.path}/KeySpander/$_fileName');
}

Future<File> _getOrCreateJsonFile() async {
  final file = await _getJsonFile();
  if (!await file.exists()) {
    final jsonString = await rootBundle.loadString("assets/data.json");
    await file.writeAsString(jsonString);
  }

  return file;
}

Future<Map<String, String>> loadJsonData() async {
  final file = await _getOrCreateJsonFile();
  final jsonString = await file.readAsString();
  final decoded = jsonDecode(jsonString);

  if (decoded is! Map) {
    throw const FormatException('JSON root must be an object.');
  }

  final result = <String, String>{};

  for (final entry in decoded.entries) {
    if (entry.key is! String || entry.value is! String) {
      throw const FormatException(
        'JSON must contain only String keys and String values.',
      );
    }
    result[entry.key as String] = entry.value as String;
  }
  return result;
}

Future<void> saveJsonData(Map<String, String> data) async {
  final file = await _getOrCreateJsonFile();

  final jsonString = const JsonEncoder.withIndent('  ').convert(data);

  await file.writeAsString(jsonString, flush: true);
}

Future<void> addJsonData(String key, String value) async {
  final data = await loadJsonData();

  if (data.containsKey(key)) {
    throw Exception('Shortcut "$key" already exists.');
  }

  data[key] = value;

  await saveJsonData(data);
}

Future<void> updateJsonData(
  String oldKey,
  String newKey,
  String newValue,
) async {
  final data = await loadJsonData();

  if (!data.containsKey(oldKey)) {
    throw Exception('Shortcut "$oldKey" does not exist.');
  }

  if (oldKey != newKey && data.containsKey(newKey)) {
    throw Exception('Shortcut "$newKey" already exists.');
  }

  data.remove(oldKey);
  data[newKey] = newValue;

  await saveJsonData(data);
}

Future<void> deleteJsonData(String key) async {
  final data = await loadJsonData();

  data.remove(key);

  await saveJsonData(data);
}
