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
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

// Singleton class for persisting update related state and logic between instances of StylesPage
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
      print("StylesProvider: Styles status updated: $status");
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

    // Force trying the style update process
    // The user will be notified via onAvailableContentUpdateCallback
    final code = ContentStore.checkForUpdate(ContentType.viewStyleHighRes);
    print("StylesProvider: checkForUpdate resolved with code $code");

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
    if (result.$2 == GemError.success || result.$2 == GemError.exist) {
      _contentUpdater = result.$1;
      _onContentUpdaterProgressChanged = onContentUpdaterProgressChanged;
      _onContentUpdaterProgressChanged?.call(0);

      // Call the update method
      _contentUpdater!.update(
        true,
        onStatusUpdated: (status) {
          print("StylesProvider: onNotifyStatusChanged with code $status");
          // fully ready - for all old styles the new styles are downloaded
          // partially ready - only a part of the new styles were downloaded because of memory constraints
          if (isReady(status)) {
            // newer styles are downloaded and everything is set to
            // - delete old styles and keep the new ones
            // - update style version to the new version
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
        onComplete: (error) {
          if (error == GemError.success) {
            print('StylesProvider: Successful update');
          } else {
            print('StylesProvider: Update finished with error $error');
          }
        },
      );
    } else {
      print(
        "StylesProvider: There was an error creating the content updater: ${result.$2}",
      );
    }

    return result.$2;
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

    for (final style in localStyles) {
      if (style.status == ContentStoreItemStatus.completed) {
        result.add(style);
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

    for (final localStyle in localStyles) {
      if (localStyle.isUpdatable &&
          localStyle.status == ContentStoreItemStatus.completed) {
        sum += localStyle.updateSize;
      }
    }

    return sum;
  }
}

enum CurrentStylesStatus {
  expiredData, // more than one version behind
  oldData, // one version behind
  upToDate, // updated
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

String getString(Version version) => '${version.major}.${version.minor}';

// Map style image preview
Uint8List? getStyleImage(ContentStoreItem contentItem, Size? size) =>
    contentItem.imgPreview.getRenderableImageBytes(
      size: size,
      format: ImageFileFormat.png,
    );

bool getIsDownloadingOrWaiting(ContentStoreItem contentItem) => [
  ContentStoreItemStatus.downloadQueued,
  ContentStoreItemStatus.downloadRunning,
  ContentStoreItemStatus.downloadWaitingNetwork,
  ContentStoreItemStatus.downloadWaitingFreeNetwork,
  ContentStoreItemStatus.downloadWaitingNetwork,
].contains(contentItem.status);

bool isReady(ContentUpdaterStatus updaterStatus) =>
    updaterStatus == ContentUpdaterStatus.partiallyReady ||
    updaterStatus == ContentUpdaterStatus.fullyReady;

Future<void> loadOldStyles(AssetBundle assetBundle) async {
  const style = 'Basic_1_Oldtime-1_21_656.style';

  final dirPath = await _getDirPath();
  final resFilePath = path.joinAll([dirPath.path, "Data", "SceneRes"]);

  await _deleteAssets(resFilePath, RegExp(r'Basic_1_Oldtime.+\.style'));
  await _loadAsset(assetBundle, style, resFilePath);
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
        print('INFO DELETE ASSETS: deleting file ${file.path}');
        file.deleteSync();
      } catch (e) {
        print(
          'WARNING: Deleting file ${file.path} failed. Reason:\n${e.toString()}.',
        );
      }
    }
  }
}
