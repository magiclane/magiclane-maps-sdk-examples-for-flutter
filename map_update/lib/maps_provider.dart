// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import 'package:magiclane_maps_flutter/content_store.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

// Singleton class for persisting update related state and logic between instances of MapsPage
class MapsProvider {
  CurrentMapsStatus _currentMapsStatus = CurrentMapsStatus.unknown;

  ContentUpdater? _contentUpdater;
  void Function(int?)? _onContentUpdaterProgressChanged;

  MapsProvider._privateConstructor();
  static final MapsProvider instance = MapsProvider._privateConstructor();

  Future<void> init() async {
    // Keep track of the new maps status
    SdkSettings.offBoardListener.registerOnWorldwideRoadMapSupportStatus((
      status,
    ) async {
      print("MapsProvider: Maps status updated: $status");
      _currentMapsStatus = CurrentMapsStatus.fromStatus(status);
    });

    // Force trying the map update process
    // The user will be notified via onWorldwideRoadMapSupportStatusCallback
    final code = ContentStore.checkForUpdate(ContentType.roadMap);
    print("MapsProvider: checkForUpdate resolved with code $code");
  }

  CurrentMapsStatus get mapsStatus => _currentMapsStatus;

  bool get isUpToDate => _currentMapsStatus == CurrentMapsStatus.upToDate;

  bool get canUpdateMaps =>
      _currentMapsStatus == CurrentMapsStatus.expiredData ||
      _currentMapsStatus == CurrentMapsStatus.oldData;

  GemError updateMaps({
    void Function(ContentUpdaterStatus)? onContentUpdaterStatusChanged,
    void Function(int?)? onContentUpdaterProgressChanged,
  }) {
    if (_contentUpdater != null) return GemError.inUse;

    final result = ContentStore.createContentUpdater(ContentType.roadMap);
    // If successfully created a new content updater
    // or one already exists
    if (result.$2 == GemError.success || result.$2 == GemError.exist) {
      _contentUpdater = result.$1;
      _onContentUpdaterProgressChanged = onContentUpdaterProgressChanged;

      // Call the update method
      _contentUpdater!.update(
        true,
        onStatusUpdated: (status) {
          print("MapsProvider: onNotifyStatusChanged with code $status");
          // fully ready - for all old maps the new maps are downloaded
          // partially ready - only a part of the new maps were downloaded because of memory constraints
          if (isReady(status)) {
            // newer maps are downloaded and everything is set to
            // - delete old maps and keep the new ones
            // - update map version to the new version
            final err = _contentUpdater!.apply();
            print("MapsProvider: apply resolved with code ${err.code}");

            if (err == GemError.success) {
              _currentMapsStatus = CurrentMapsStatus.upToDate;
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
        onComplete: (error) {
          if (error == GemError.success) {
            print('MapsProvider: Successful uupdate');
          } else {
            print('MapsProvider: Update finished with error $error');
          }
        },
      );
    } else {
      print(
        "MapsProvider: There was an erorr creating the content updater: ${result.$2}",
      );
    }

    return result.$2;
  }

  void cancelUpdateMaps() {
    _contentUpdater?.cancel();

    _onContentUpdaterProgressChanged?.call(null);
    _onContentUpdaterProgressChanged = null;

    _contentUpdater = null;
  }

  // Method to load the online map list
  static Future<List<ContentStoreItem>> getOnlineMaps() async {
    final mapsListCompleter = Completer<List<ContentStoreItem>>();

    ContentStore.asyncGetStoreContentList(ContentType.roadMap, (
      err,
      items,
      isCached,
    ) {
      if (err == GemError.success && items.isNotEmpty) {
        mapsListCompleter.complete(items);
      } else {
        mapsListCompleter.complete([]);
      }
    });

    return mapsListCompleter.future;
  }

  // Method to load the downloaded map list
  static List<ContentStoreItem> getOfflineMaps() {
    final localMaps = ContentStore.getLocalContentList(ContentType.roadMap);

    final result = <ContentStoreItem>[];

    for (final map in localMaps) {
      if (map.status == ContentStoreItemStatus.completed) {
        result.add(map);
      }
    }

    return result;
  }

  // Method to compute update size (sum of all maps sizes)
  static int computeUpdateSize() {
    final localMaps = ContentStore.getLocalContentList(ContentType.roadMap);

    int sum = 0;

    for (final localMap in localMaps) {
      if (localMap.isUpdatable &&
          localMap.status == ContentStoreItemStatus.completed) {
        sum += localMap.updateSize;
      }
    }

    return sum;
  }
}

Future<void> loadOldMaps(AssetBundle assetBundle) async {
  const cmap = 'AndorraOSM_2021Q1.cmap';
  const worldMap = 'WM_7_406.map';

  final dirPath = await _getDirPath();
  final resFilePath = path.joinAll([dirPath.path, "Data", "Res"]);
  final mapsFilePath = path.joinAll([dirPath.path, "Data", "Maps"]);

  await _deleteAssets(resFilePath, RegExp(r'WM_\d_\d+\.map'));
  await _deleteAssets(mapsFilePath, RegExp(r'.+\.cmap'));

  await _loadAsset(assetBundle, cmap, mapsFilePath);
  await _loadAsset(assetBundle, worldMap, resFilePath);
}

Future<bool> _loadAsset(
  AssetBundle assetBundle,
  String assetName,
  String destinationDirectoryPath,
) async {
  final destinationFilePath = path.join(destinationDirectoryPath, assetName);

  File file = File(destinationFilePath);
  if (await file.exists()) {
    return false;
  }

  await file.create();

  final asset = await assetBundle.load('assets/$assetName');
  final buffer = asset.buffer;
  await file.writeAsBytes(
    buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes),
    flush: true,
  );
  print('INFO: Copied asset $destinationFilePath.');

  return true;
}

Future<Directory> _getDirPath() async {
  if (Platform.isAndroid) {
    return (await getExternalStorageDirectory())!;
  } else if (Platform.isIOS) {
    return await getApplicationDocumentsDirectory();
  } else {
    throw Exception('Platform not supported');
  }
}

Future<void> _deleteAssets(String directoryPath, RegExp pattern) async {
  final directory = Directory(directoryPath);

  if (!directory.existsSync()) {
    print('WARNING: Directory $directoryPath not found.');
  }

  for (final file in directory.listSync()) {
    final filename = path.basename(file.path);
    if (pattern.hasMatch(filename)) {
      try {
        //print('INFO DELETE ASSETS: deleting file ${file.path}');
        file.deleteSync();
      } catch (e) {
        print(
          'WARNING: Deleting file ${file.path} failed. Reason:\n${e.toString()}.',
        );
      }
    }
  }
}

enum CurrentMapsStatus {
  expiredData, // more than one version behind
  oldData, // one version behind maps
  upToDate, // updated maps
  unknown; // not received any notification yet

  static CurrentMapsStatus fromStatus(ContentStoreStatus status) {
    switch (status) {
      case ContentStoreStatus.expiredData:
        return CurrentMapsStatus.expiredData;
      case ContentStoreStatus.oldData:
        return CurrentMapsStatus.oldData;
      case ContentStoreStatus.upToDate:
        return CurrentMapsStatus.upToDate;
    }
  }
}

String getString(Version version) => '${version.major}.${version.minor}';

// Method that returns the image of the country associated with the road map item
Uint8List? getImage(ContentStoreItem contentItem) {
  Img? img = MapDetails.getCountryFlagImg(contentItem.countryCodes[0]);
  if (img == null) return null;
  if (!img.isValid) return null;
  return img.getRenderableImageBytes(size: Size(100, 100));
}

bool getIsDownloadingOrWaiting(ContentStoreItem contentItem) => [
  ContentStoreItemStatus.downloadQueued,
  ContentStoreItemStatus.downloadRunning,
  ContentStoreItemStatus.downloadWaitingNetwork,
  ContentStoreItemStatus.downloadWaitingFreeNetwork,
  ContentStoreItemStatus.downloadWaitingNetwork,
].contains(contentItem.status);

void restartDownloadIfNecessary(
  ContentStoreItem contentItem,
  void Function(GemError err) onCompleteCallback, {
  void Function(int progress)? onProgress,
}) {
  //If the map is downloading pause and start downloading again
  //so the progress indicator updates value from callback
  if (getIsDownloadingOrWaiting(contentItem)) {
    _pauseAndRestartDownload(
      contentItem,
      onCompleteCallback,
      onProgress: onProgress,
    );
  }
}

void _pauseAndRestartDownload(
  ContentStoreItem contentItem,

  void Function(GemError err) onCompleteCallback, {
  void Function(int progress)? onProgress,
}) {
  final errCode = contentItem.pauseDownload(
    onComplete: (err) {
      if (err == GemError.success) {
        // Download the map.
        contentItem.asyncDownload(
          onCompleteCallback,
          onProgress: onProgress,
          allowChargedNetworks: true,
        );
      } else {
        print(
          "Download pause for item ${contentItem.id} failed with code $err",
        );
      }
    },
  );

  if (errCode != GemError.success) {
    print(
      "Download pause for item ${contentItem.id} failed with code $errCode",
    );
  }
}

bool isReady(ContentUpdaterStatus status) =>
    status == ContentUpdaterStatus.partiallyReady ||
    status == ContentUpdaterStatus.fullyReady;
