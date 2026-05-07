import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor openLocalDatabaseConnection() {
  return LazyDatabase(() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final databaseFile = File(p.join(documentsDirectory.path, 'khata_local.sqlite'));
    return NativeDatabase.createInBackground(databaseFile);
  });
}
