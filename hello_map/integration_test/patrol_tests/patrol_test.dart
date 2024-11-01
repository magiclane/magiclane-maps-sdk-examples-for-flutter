import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';
import 'package:patrol/patrol.dart';

import 'position_service_test.dart';

void main() {
  runPositionServiceTests();

  patrolTest(
    'should call on touch callback when tapping the map',
    ($) async {
      await GemKit.initialize(appAuthorization: const String.fromEnvironment('GEM_TOKEN'));

      final mapControllerCompleter = Completer<GemMapController>();
      const mapKey = ValueKey('gemMap');

      await $.pumpWidgetAndSettle(
        MaterialApp(
          home: GemMap(
            key: mapKey,
            onMapCreated: (controller) => mapControllerCompleter.complete(controller),
          ),
        ),
      );

      final controller = await mapControllerCompleter.future;
      final mapFinder = find.byKey(mapKey);
      expect(mapFinder, findsOneWidget);

      final tapCompleter = Completer<void>();

      controller.registerTouchCallback((pos) {
        tapCompleter.complete();
      });

      await $.tester.tap(mapFinder);

      await tapCompleter.future;

      expect(tapCompleter.future, completes, reason: 'future is not completed.');
    },
  );
}
