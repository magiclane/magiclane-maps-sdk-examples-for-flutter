// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offline_routing/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Launch Test', () {
    testWidgets('Map loads successful test', (WidgetTester tester) async {
      // Start the app
      runApp(MyApp());

      // Wait for the app to load
      await tester.pumpAndSettle();

      await Future<void>.delayed(Duration(seconds: 2));

      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      await Future<void>.delayed(Duration(seconds: 2));

      // Find a widget and interact with it
      final map = find.byKey(Key('GemMap'));
      expect(map, findsOneWidget);
    });
  });
}
