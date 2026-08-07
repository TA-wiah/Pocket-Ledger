import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:pocket_ledger/main.dart';
import 'package:pocket_ledger/services/hive_service.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  final String path;
  _FakePathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('pocket_ledger_test');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    await HiveService.init();
  });

  testWidgets('App boots and shows dashboard tab', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: PocketLedgerApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
  });
}
