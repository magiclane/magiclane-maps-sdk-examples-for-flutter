// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import 'package:gem_kit/content_store.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

// Singleton class for persisting update related state and logic between instances of MapsPage
class MapsProvider {
  CurrentMapsStatus _currentMapsStatus = CurrentMapsStatus.unknown;

  ContentUpdater? _contentUpdater;
  void Function(int?)? _onContentUpdaterProgressChanged;

  MapsProvider._privateConstructor();
  static final MapsProvider instance = MapsProvider._privateConstructor();

  void init(AssetBundle assetBundle) async {
    // Simulate old maps
    // delete all maps, all resources and get some old ones
    // AS A USER YOU NEVER DO THAT
    await loadOldMaps(assetBundle);

    SdkSettings.setAllowInternetConnection(true);

    // keep track of the new maps status
    SdkSettings.offBoardListener.registerOnWorldwideRoadMapSupportStatus((
      status,
    ) async {
      print("MapsProvider: Maps status updated: $status");
      _currentMapsStatus = CurrentMapsStatus.fromStatus(status);
    });

    // force trying the map update process
    //The user will be notified via onWorldwideRoadMapSupportStatusCallback

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
    if (result.second == GemError.success || result.second == GemError.exist) {
      _contentUpdater = result.first;
      _onContentUpdaterProgressChanged = onContentUpdaterProgressChanged;

      // Call the update method
      _contentUpdater!.update(
        true,
        onStatusUpdated: (status) {
          print("MapsProvider: onNotifyStatusChanged with code $status");
          // fully ready - for all old maps the new maps are downloaded
          // partially ready - only a part of the new maps were downloaded because of memory constraints
          if (status.isReady) {
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
        onCompleteCallback: (error) {
          if (error == GemError.success) {
            print('MapsProvider: Successful uupdate');
          } else {
            print('MapsProvider: Update finished with error $error');
          }
        },
      );
    } else {
      print(
        "MapsProvider: There was an erorr creating the content updater: ${result.second}",
      );
    }

    return result.second;
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
      if (err == GemError.success && items != null) {
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

  // don't use this in production code
  // only used to illustrate the map update process
  ContentStore.refresh();
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
    print(
      '\x1B[31mWARNING: Directory $directoryPath not found. Test might fail.\x1B[0m',
    );
  }

  for (final file in directory.listSync()) {
    final filename = path.basename(file.path);
    if (pattern.hasMatch(filename)) {
      try {
        //print('INFO DELETE ASSETS: deleting file ${file.path}');
        file.deleteSync();
      } catch (e) {
        print(
          '\x1B[31mWARNING: Deleting file ${file.path} failed. Test might fail. Reason:\n${e.toString()}\x1B[0m',
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

  static CurrentMapsStatus fromStatus(MapStatus status) {
    switch (status) {
      case MapStatus.expiredData:
        return CurrentMapsStatus.expiredData;
      case MapStatus.oldData:
        return CurrentMapsStatus.oldData;
      case MapStatus.upToDate:
        return CurrentMapsStatus.upToDate;
    }
  }
}

extension VersionExtension on Version {
  String get str => '$major.$minor';
}

extension ContentStoreItemExtension on ContentStoreItem {
  // Method that returns the image of the country associated with the road map item
  Uint8List? get image {
    Img? img = MapDetails.getCountryFlagImg(countryCodes[0]);
    if (img == null) return null;
    if (!img.isValid) return null;
    return img.getRenderableImageBytes(size: Size(100, 100));
  }

  bool get isDownloadingOrWaiting => [
        ContentStoreItemStatus.downloadQueued,
        ContentStoreItemStatus.downloadRunning,
        ContentStoreItemStatus.downloadWaitingNetwork,
        ContentStoreItemStatus.downloadWaitingFreeNetwork,
        ContentStoreItemStatus.downloadWaitingNetwork,
      ].contains(status);

  void restartDownloadIfNecessary(
    void Function(GemError err) onCompleteCallback, {
    void Function(int progress)? onProgressCallback,
  }) {
    //If the map is downloading pause and start downloading again
    //so the progress indicator updates value from callback
    if (isDownloadingOrWaiting) {
      _pauseAndRestartDownload(
        onCompleteCallback,
        onProgressCallback: onProgressCallback,
      );
    }
  }

  void _pauseAndRestartDownload(
    void Function(GemError err) onCompleteCallback, {
    void Function(int progress)? onProgressCallback,
  }) {
    final errCode = pauseDownload(
      onComplete: (err) {
        if (err == GemError.success) {
          // Download the map.
          asyncDownload(
            onCompleteCallback,
            onProgressCallback: onProgressCallback,
            allowChargedNetworks: true,
          );
        } else {
          print("Download pause for item $id failed with code $err");
        }
      },
    );

    if (errCode != GemError.success) {
      print("Download pause for item $id failed with code $errCode");
    }
  }
}

extension ContentUpdaterStatusExtension on ContentUpdaterStatus {
  bool get isReady =>
      this == ContentUpdaterStatus.partiallyReady ||
      this == ContentUpdaterStatus.fullyReady;
}
