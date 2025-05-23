// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/services.dart';

import 'package:gem_kit/content_store.dart';
import 'package:gem_kit/core.dart';

// Singleton class for persisting update related state and logic between instances of MapsPage
class StylesProvider {
  CurrentStylesStatus _currentStylesStatus = CurrentStylesStatus.unknown;

  ContentUpdater? _contentUpdater;
  void Function(int?)? _onContentUpdaterProgressChanged;

  StylesProvider._privateConstructor();
  static final StylesProvider instance = StylesProvider._privateConstructor();

  Future<void> init() {
    final completer = Completer<void>();

    SdkSettings.setAllowInternetConnection(true);

    // Keep track of the new styles status
    SdkSettings.offBoardListener.registerOnWorldwideRoadMapSupportStatus((
      status,
    ) async {
      print("MapsProvider: Maps status updated: $status");
    });

    SdkSettings.offBoardListener.registerOnAvailableContentUpdate((
      type,
      status,
    ) {
      if (type == ContentType.viewStyleHighRes ||
          type == ContentType.viewStyleLowRes) {
        _currentStylesStatus = CurrentStylesStatus.fromStatus(status);
      }
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    // // Keep track of the new styles status - deprecated
    // SdkSettings.setAllowConnection(
    //   true,
    //   onWorldwideRoadMapSupportStatusCallback: (status) async {
    //     print("MapsProvider: Maps status updated: $status");
    //   },
    //   onAvailableContentUpdateCallback: (type, status) {
    //     if (type == ContentType.viewStyleHighRes ||
    //         type == ContentType.viewStyleLowRes) {
    //       _currentStylesStatus = CurrentStylesStatus.fromStatus(status);
    //     }
    //     if (!completer.isCompleted) {
    //       completer.complete();
    //     }
    //   },
    // );

    // Force trying the style update process
    // The user will be notified via onAvailableContentUpdateCallback

    final code = ContentStore.checkForUpdate(ContentType.viewStyleHighRes);
    print("MapsProvider: checkForUpdate resolved with code $code");

    return completer.future;
  }

  CurrentStylesStatus get stylesStatus => _currentStylesStatus;

  bool get isUpToDate => _currentStylesStatus == CurrentStylesStatus.upToDate;

  bool get canUpdateStyles =>
      _currentStylesStatus == CurrentStylesStatus.expiredData ||
      _currentStylesStatus == CurrentStylesStatus.oldData;

  GemError updateStyles({
    void Function(ContentUpdaterStatus)? onContentUpdaterStatusChanged,
    void Function(int?)? onContentUpdaterProgressChanged,
  }) {
    if (_contentUpdater != null) return GemError.inUse;

    final result = ContentStore.createContentUpdater(
      ContentType.viewStyleHighRes,
    );
    // If successfully created a new content updater
    // or one already exists
    if (result.second == GemError.success || result.second == GemError.exist) {
      _contentUpdater = result.first;
      _onContentUpdaterProgressChanged = onContentUpdaterProgressChanged;
      _onContentUpdaterProgressChanged?.call(0);

      // Call the update method
      _contentUpdater!.update(
        true,
        onStatusUpdated: (status) {
          print("StylesProvider: onNotifyStatusChanged with code $status");
          // fully ready - for all old maps the new styles are downloaded
          // partially ready - only a part of the new styles were downloaded because of memory constraints
          if (status.isReady) {
            // newer maps are downloaded and everything is set to
            // - delete old maps and keep the new ones
            // - update map version to the new version
            final err = _contentUpdater!.apply();
            print("StylesProvider: apply resolved with code ${err.code}");

            if (err == GemError.success) {
              _currentStylesStatus = CurrentStylesStatus.upToDate;
            }

            _onContentUpdaterProgressChanged?.call(null);
            _onContentUpdaterProgressChanged = null;
            _contentUpdater = null;
          }

          onContentUpdaterStatusChanged?.call(status);
        },
        onProgressUpdated: (progress) {
          _onContentUpdaterProgressChanged?.call(progress);
          print('Progress: $progress');
        },
        onCompleteCallback: (error) {
          if (error == GemError.success) {
            print('StylesProvider: Successful update');
          } else {
            print('StylesProvider: Update finished with error $error');
          }
        },
      );
    } else {
      print(
        "StylesProvider: There was an erorr creating the content updater: ${result.second}",
      );
    }

    return result.second;
  }

  void cancelUpdateStyles() {
    _contentUpdater?.cancel();

    _onContentUpdaterProgressChanged?.call(null);
    _onContentUpdaterProgressChanged = null;

    _contentUpdater = null;
  }

  // Method to load the online styles list
  static Future<List<ContentStoreItem>> getOnlineStyles() async {
    final stylesListCompleter = Completer<List<ContentStoreItem>>();

    ContentStore.asyncGetStoreContentList(ContentType.viewStyleHighRes, (
      err,
      items,
      isCached,
    ) {
      if (err == GemError.success && items != null) {
        stylesListCompleter.complete(items);
      } else {
        stylesListCompleter.complete([]);
      }
    });

    return stylesListCompleter.future;
  }

  // Method to load the downloaded styles list
  static List<ContentStoreItem> getOfflineStyles() {
    final localStyles = ContentStore.getLocalContentList(
      ContentType.viewStyleHighRes,
    );

    final result = <ContentStoreItem>[];

    for (final map in localStyles) {
      if (map.status == ContentStoreItemStatus.completed) {
        result.add(map);
      }
    }

    return result;
  }

  // Method to compute update size (sum of all style sizes)
  static int computeUpdateSize() {
    final localStyles = ContentStore.getLocalContentList(
      ContentType.viewStyleHighRes,
    );

    int sum = 0;

    for (final localMap in localStyles) {
      if (localMap.isUpdatable &&
          localMap.status == ContentStoreItemStatus.completed) {
        sum += localMap.updateSize;
      }
    }

    return sum;
  }
}

enum CurrentStylesStatus {
  expiredData, // more than one version behind
  oldData, // one version behind maps
  upToDate, // updated maps
  unknown; // not received any notification yet

  static CurrentStylesStatus fromStatus(MapStatus status) {
    switch (status) {
      case MapStatus.expiredData:
        return CurrentStylesStatus.expiredData;
      case MapStatus.oldData:
        return CurrentStylesStatus.oldData;
      case MapStatus.upToDate:
        return CurrentStylesStatus.upToDate;
    }
  }
}

extension VersionExtension on Version {
  String get str => '$major.$minor';
}

extension ContentStoreItemExtension on ContentStoreItem {
  // Map style image preview
  Uint8List? getStyleImage(Size? size) => imgPreview.getRenderableImageBytes(
        size: size,
        format: ImageFileFormat.png,
      );

  bool get isDownloadingOrWaiting => [
        ContentStoreItemStatus.downloadQueued,
        ContentStoreItemStatus.downloadRunning,
        ContentStoreItemStatus.downloadWaitingNetwork,
        ContentStoreItemStatus.downloadWaitingFreeNetwork,
        ContentStoreItemStatus.downloadWaitingNetwork,
      ].contains(status);
}

extension ContentUpdaterStatusExtension on ContentUpdaterStatus {
  bool get isReady =>
      this == ContentUpdaterStatus.partiallyReady ||
      this == ContentUpdaterStatus.fullyReady;
}
