import 'package:aun_postman/app/app.dart';
import 'package:aun_postman/data/local/hive_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open all Hive boxes before the first frame.
  await initHive();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
