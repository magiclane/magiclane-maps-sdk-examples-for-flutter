// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

// ignore_for_file: avoid_print

import 'package:gem_kit/content_store.dart';
import 'package:gem_kit/core.dart';

// Singleton class for persisting update related state and logic between instances of MapsPage
class UpdatePersistence {
  ContentUpdater? _contentUpdater;
  bool isOldData = false;

  void Function(int?)? onProgress;
  void Function(ContentUpdaterStatus)? onStatusChanged;

  UpdatePersistence._privateConstructor();
  static final UpdatePersistence instance =
      UpdatePersistence._privateConstructor();

  GemError checkForUpdate() {
    //The user will be notified via registerOnWorldwideRoadMapSupportStatus
    final code = ContentStore.checkForUpdate(ContentType.roadMap);
    print("UpdatePersistence: checkForUpdate resolved with code $code");
    return code;
  }

  GemError update() {
    _contentUpdater = ContentStore.createContentUpdater(ContentType.roadMap);

    final err = _contentUpdater!.update(
      true,
      onStatusUpdated: (status) {
        print("UpdatePersistence: onNotifyStatusChanged with code $status");
        if (status == ContentUpdaterStatus.fullyReady ||
            status == ContentUpdaterStatus.partiallyReady) {
          isOldData = false;

          final err = _contentUpdater!.apply();
          print("UpdatePersistence: apply resolved with code ${err.code}");
        }

        onProgress?.call(null);
        onStatusChanged?.call(status);
      },
      onProgressUpdated: (progress) {
        onProgress?.call(progress);
      },
    );
    print("UpdatePersistence: update resolved with code ${err.code}");
    return err;
  }

  void cancel() {
    _contentUpdater!.cancel();

    onProgress?.call(null);
  }
}
