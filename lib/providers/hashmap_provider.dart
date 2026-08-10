import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_spander/utils/json_loader.dart';

final hashmapProvider =
    NotifierProvider<HashmapNotifier, LinkedHashMap<String, String>>(
      HashmapNotifier.new,
    );

class HashmapNotifier extends Notifier<LinkedHashMap<String, String>> {
  @override
  LinkedHashMap<String, String> build() {
    return LinkedHashMap<String, String>();
  }

  Future<void> load() async {
    final data = await loadJsonData();

    state = LinkedHashMap<String, String>.from(data);
  }

  Future<void> add(String key, String value) async {
    final copy = LinkedHashMap<String, String>.from(state);

    if (copy.containsKey(key)) {
      throw Exception(
        'Shortcut "$key" already exists. '
        'Please choose another key.',
      );
    }

    copy[key] = value;

    state = copy;

    await saveJsonData(copy);
  }

  Future<void> update(String oldKey, String newKey, String newValue) async {
    final copy = LinkedHashMap<String, String>.from(state);

    if (!copy.containsKey(oldKey)) {
      throw Exception('Shortcut "$oldKey" does not exist.');
    }

    if (oldKey != newKey && copy.containsKey(newKey)) {
      throw Exception('Shortcut "$newKey" already exists.');
    }

    copy.remove(oldKey);
    copy[newKey] = newValue;

    state = copy;

    await saveJsonData(copy);
  }

  Future<void> delete(String key) async {
    final copy = LinkedHashMap<String, String>.from(state);

    if (!copy.containsKey(key)) {
      return;
    }

    copy.remove(key);

    state = copy;

    await saveJsonData(copy);
  }

  Future<void> save() async {
    await saveJsonData(Map<String, String>.from(state));
  }
}
