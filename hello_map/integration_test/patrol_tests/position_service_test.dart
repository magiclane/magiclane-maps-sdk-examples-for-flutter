import 'package:flutter/material.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/position.dart';
import 'package:gem_kit/sense.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'dart:async';

void runPositionServiceTests() {
  group('[PositionService]', () {
    patrolSetUp(() async {
      await GemKit.initialize(appAuthorization: const String.fromEnvironment('GEM_TOKEN'));
      final isConnected = await ensureNetworkAccess();

      if (!isConnected) print('Could not connect to network.');
    });

    patrolTearDown(() async {
      PositionService.instance.removeDataSource();
      await GemKit.release();
    });

    patrolTest(
      'should set live data source after granting location permission',
      ($) async {
        Permission.locationWhenInUse.request();
        await Future.delayed(Durations.long2);

        if (await $.native.isPermissionDialogVisible()) {
          await $.native.grantPermissionWhenInUse();
        }

        final isLocationPermissionGranted = await Permission.locationWhenInUse.isGranted;
        expect(isLocationPermissionGranted, isTrue, reason: 'location permission is not granted.');

        final result = PositionService.instance.setLiveDataSource();

        expect(result == GemError.success || result == GemError.exist, isTrue,
            reason: 'setLiveDataSource did not return success or exist.');

        final completer = Completer<GemPosition>();
        PositionService.instance.addPositionListener((position) => completer.complete(position));

        final position = await expectAwaitCompletion(completer.future);

        expect(position.coordinates.isValid, isTrue, reason: 'coordinates are not valid.');
      },
    );

    patrolTest('should set external data source', ($) async {
      final dataSource = DataSource([DataType.position]);
      final positionCompleter = Completer<GemPosition>();

      final result = PositionService.instance.setExternalDataSource(dataSource);

      expect(result, GemError.success, reason: 'result was not success.');

      PositionService.instance.addPositionListener((position) => positionCompleter.complete(position));

      const latitude = 45.234;
      const longitude = 25.764;
      const altitude = 700.0;
      const heading = 20.0;
      const speed = 50.3;
      final timeStamp = DateTime.now().toUtc();

      dataSource.start();

      dataSource.pushData(
          positionData: ExternalPositionData(
              timestamp: timeStamp.millisecondsSinceEpoch,
              latitude: latitude,
              longitude: longitude,
              altitude: altitude,
              heading: heading,
              speed: speed));

      final position = await positionCompleter.future;

      expect(position.coordinates.isValid, isTrue, reason: 'coordinates are not valid.');
      expect(position.coordinates.latitude, latitude, reason: 'latitude does not match.');
      expect(position.coordinates.longitude, longitude, reason: 'longitude does not match.');
      expect(position.coordinates.altitude, altitude, reason: 'altitude does not match.');
      expect(position.timestamp.millisecondsSinceEpoch / 1000, timeStamp.millisecondsSinceEpoch / 1000,
          reason: 'timestamp does not match.');
      expect(position.speed, speed, reason: 'speed does not match.');
      expect(position.course, heading, reason: 'speed does not match.');
    });
  });
}

Future<T> expectAwaitCompletion<T>(
  Future<T> future, {
  Duration timeout = const Duration(seconds: 5),
  String reason = 'future did not complete in a timely manner.',
}) async {
  // Use future.timeout to add a timeout to the future
  final result = await future.timeout(timeout, onTimeout: () {
    throw TimeoutException(reason, timeout);
  });

  // Use expectLater to check if the future completes
  await expectLater(
    future,
    completes,
  );

  // Return the result of the future
  return result;
}

Future<bool> ensureNetworkAccess() async {
  bool isConnected = false;

  while (!isConnected) {
    await Future.delayed(const Duration(seconds: 2));
    isConnected = await awaitNetworkAccess();
  }

  return isConnected;
}

Future<bool> awaitNetworkAccess() async {
  final completer = Completer<bool>();

  SdkSettings.setAllowConnection(false);
  SdkSettings.setAllowConnection(true,
      onConnectionStatusUpdatedCallback: (isConnected) => completer.complete(isConnected));

  return completer.future.timeout(const Duration(seconds: 10), onTimeout: () {
    print(
        '\x1B[31mWARNING: awaitNetworkAccess took too long. Connection might not be established. \nTest might fail.\x1B[0m');
    return true;
  });
}
