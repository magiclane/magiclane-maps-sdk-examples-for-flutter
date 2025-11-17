// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:magiclane_maps_flutter/content_store.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';

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
