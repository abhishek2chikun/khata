import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Returns the file the local SQLite cache is written to.
Future<File> localDatabaseFile() async {
  final documentsDirectory = await getApplicationDocumentsDirectory();
  return File(p.join(documentsDirectory.path, 'khata_local.sqlite'));
}

QueryExecutor openLocalDatabaseConnection() {
  return LazyDatabase(() async {
    final databaseFile = await localDatabaseFile();
    return NativeDatabase.createInBackground(databaseFile);
  });
}
