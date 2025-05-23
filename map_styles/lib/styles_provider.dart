// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:gem_kit/content_store.dart';
import 'package:gem_kit/core.dart';

// ignore_for_file: avoid_print

class StylesProvider {
  StylesProvider._privateConstructor();
  static final StylesProvider instance = StylesProvider._privateConstructor();

  // Method to load the local-available styles
  static List<ContentStoreItem> getOfflineStyles() {
    final localMaps = ContentStore.getLocalContentList(
      ContentType.viewStyleHighRes,
    );

    final result = <ContentStoreItem>[];

    for (final map in localMaps) {
      if (map.status == ContentStoreItemStatus.completed) {
        result.add(map);
      }
    }

    return result;
  }

  // Method to load the available styles
  static Future<List<ContentStoreItem>> getOnlineStyles() {
    final completer = Completer<List<ContentStoreItem>>();

    ContentStore.asyncGetStoreContentList(ContentType.viewStyleHighRes, (
      err,
      items,
      isCached,
    ) {
      if (err != GemError.success) {
        print("Error while getting styles: ${err.name}");
        return;
      }
      completer.complete(items);
    });

    return completer.future;
  }
}

extension ContentStoreItemExtension on ContentStoreItem {
  // The first image associated to a map
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
