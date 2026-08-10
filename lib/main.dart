import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_spander/screens/home_screen.dart';
import 'package:window_manager/window_manager.dart';

import 'data/local/hashmap/hashmap_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();

    await runPythonExe();

    const windowOptions = WindowOptions(
      size: Size(500, 600),
      minimumSize: Size(400, 500),
      maximumSize: Size(600, 700),
      center: true,
      title: 'KeySpander',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const ProviderScope(child: MyApp()));
}
