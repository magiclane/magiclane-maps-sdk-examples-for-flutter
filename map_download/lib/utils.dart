// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:gem_kit/content_store.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';

bool getIsDownloadingOrWaiting(ContentStoreItem contentItem) => [
  ContentStoreItemStatus.downloadQueued,
  ContentStoreItemStatus.downloadRunning,
  ContentStoreItemStatus.downloadWaitingNetwork,
  ContentStoreItemStatus.downloadWaitingFreeNetwork,
  ContentStoreItemStatus.downloadWaitingNetwork,
].contains(contentItem.status);

// Method that returns the image of the country associated with the road map item
Uint8List? getImage(ContentStoreItem contentItem) {
  Img? img = MapDetails.getCountryFlagImg(contentItem.countryCodes[0]);
  if (img == null) return null;
  if (!img.isValid) return null;
  return img.getRenderableImageBytes(size: Size(100, 100));
}

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
      "Download pause for item ${contentItem.id}  failed with code $errCode",
    );
  }
}

// Method to load the maps
Future<List<ContentStoreItem>> getMaps() async {
  final mapsListCompleter = Completer<List<ContentStoreItem>>();

  ContentStore.asyncGetStoreContentList(ContentType.roadMap, (
    err,
    items,
    isCached,
  ) {
    if (err == GemError.success) {
      mapsListCompleter.complete(items);
    } else {
      mapsListCompleter.complete([]);
    }
  });

  return mapsListCompleter.future;
}
