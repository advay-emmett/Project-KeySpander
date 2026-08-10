import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/hashmap_provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeySpander',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  final Set<String> _visibleKeys = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await ref.read(hashmapProvider.notifier).load();
    } catch (e) {
      if (!mounted) return;
      debugPrint(e.toString());

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hashmap = ref.watch(hashmapProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('KeySpander'),
        actions: [
          IconButton(
            tooltip:
                '- Press Shift+Enter to change line\n- Press Enter to save',
            onPressed: () {},
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),

      body: hashmap.isEmpty
          ? const Center(child: Text('No keys added yet. Click + to add.'))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: hashmap.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final entry = hashmap.entries.elementAt(index);

                return _HashmapTile(
                  index: index,
                  keyName: entry.key,
                  value: entry.value,
                  isVisible: _visibleKeys.contains(entry.key),
                  onToggleVisibility: () {
                    setState(() {
                      if (_visibleKeys.contains(entry.key)) {
                        _visibleKeys.remove(entry.key);
                      } else {
                        _visibleKeys.add(entry.key);
                      }
                    });
                  },
                  onEdit: () =>
                      _editEntry(oldKey: entry.key, oldValue: entry.value),
                  onSave: _saveEntry,
                  onDelete: () => _deleteEntry(entry.key),
                );
              },
            ),

      floatingActionButton: FloatingActionButton(
        tooltip: 'Add',
        onPressed: _addEntry,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addEntry() async {
    final result = await _showEntryDialog(title: 'Add key');

    if (result == null) return;

    final key = result.key.trim();
    final value = result.value.trim();

    final hashmap = ref.read(hashmapProvider);

    if (hashmap.containsKey(key)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A key with this name already exists.')),
      );

      return;
    }

    try {
      await ref.read(hashmapProvider.notifier).add(key, value);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add key: $e')));
    }
  }

  Future<void> _editEntry({
    required String oldKey,
    required String oldValue,
  }) async {
    final result = await _showEntryDialog(
      title: 'Edit $oldKey',
      initialKey: oldKey,
      initialValue: oldValue,
    );

    if (result == null) return;

    final newKey = result.key.trim();
    final newValue = result.value.trim();

    final hashmap = ref.read(hashmapProvider);

    if (newKey != oldKey && hashmap.containsKey(newKey)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A key with this name already exists.')),
      );

      return;
    }

    try {
      await ref.read(hashmapProvider.notifier).update(oldKey, newKey, newValue);

      if (!mounted) return;

      setState(() {
        if (_visibleKeys.remove(oldKey)) {
          _visibleKeys.add(newKey);
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update key: $e')));
    }
  }

  Future<void> _deleteEntry(String key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete key?'),
          content: Text('Are you sure you want to delete "$key"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ref.read(hashmapProvider.notifier).delete(key);

      if (!mounted) return;

      setState(() {
        _visibleKeys.remove(key);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete key: $e')));
    }
  }

  Future<void> _saveEntry() async {
    try {
      await ref.read(hashmapProvider.notifier).save();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data saved.'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save data: $e')));
    }
  }

  Future<_EntryResult?> _showEntryDialog({
    required String title,
    String initialKey = '',
    String initialValue = '',
  }) async {
    final keyController = TextEditingController(text: initialKey);
    final valueController = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<_EntryResult>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: keyController,
                    autofocus: true,
                    maxLength: 20,
                    decoration: const InputDecoration(
                      labelText: 'Key',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Value cannot be empty';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: valueController,
                    maxLength: 1000,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Value',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Value cannot be empty';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                Navigator.pop(
                  context,
                  _EntryResult(
                    key: keyController.text,
                    value: valueController.text,
                  ),
                );
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save'),
            ),
          ],
        );
      },
    );
    return result;
  }
}

class _EntryResult {
  const _EntryResult({required this.key, required this.value});

  final String key;
  final String value;
}

class _HashmapTile extends StatelessWidget {
  const _HashmapTile({
    required this.index,
    required this.keyName,
    required this.value,
    required this.isVisible,
    required this.onToggleVisibility,
    required this.onEdit,
    required this.onSave,
    required this.onDelete,
  });

  final int index;
  final String keyName;
  final String value;
  final bool isVisible;

  final VoidCallback onToggleVisibility;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.withOpacity(0.3), width: 2),
        borderRadius: .circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 5),
      leading: Text('${index + 1}.', style: const TextStyle(fontSize: 14)),
      titleAlignment: .center,
      title: Text(keyName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: TextField(
          controller: TextEditingController(text: value),
          readOnly: true,
          obscureText: !isVisible,
        ),
      ),
      trailing: Wrap(
        spacing: 2,
        children: [
          IconButton(
            tooltip: isVisible ? 'Hide value' : 'Show value',
            onPressed: onToggleVisibility,
            icon: Icon(
              isVisible
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            tooltip: 'Save',
            onPressed: onSave,
            icon: const Icon(Icons.save_rounded),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_forever_rounded),
          ),
        ],
      ),
    );
  }
}
