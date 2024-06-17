// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

import 'package:gem_kit/content_store.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';

import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:flutter/material.dart';

import 'dart:typed_data';

class MapsDownloadedItem extends StatefulWidget {
  final ContentStoreItem map;
  final void Function(ContentStoreItem) deleteMap;

  const MapsDownloadedItem(
      {super.key, required this.map, required this.deleteMap});

  @override
  State<MapsDownloadedItem> createState() => _MapsDownloadedItemState();
}

class _MapsDownloadedItemState extends State<MapsDownloadedItem> {
  late Version _clientVersion;
  late Version _updateVersion;

  @override
  Widget build(BuildContext context) {
    bool isOld = widget.map.isUpdatable;
    _clientVersion = widget.map.clientVersion;
    _updateVersion = widget.map.updateVersion;
    return Slidable(
      endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (context) => widget.deleteMap(widget.map),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              icon: Icons.delete,
            )
          ]),
      child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            width: 50,
            child: Image.memory(_getMapImage(widget.map)),
          ),
          title: Text(
            widget.map.name,
            style: const TextStyle(
                color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${(widget.map.totalSize / (1024.0 * 1024.0)).toStringAsFixed(2)} MB",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
              Text(
                  "Current Version: ${_clientVersion.major}.${_clientVersion.minor}"),
              if (_updateVersion.major != 0 && _updateVersion.minor != 0)
                Text(
                    "New version available: ${_updateVersion.major}.${_updateVersion.minor}")
              else
                const Text("Version up to date"),
            ],
          ),
          trailing: (isOld)
              ? const Icon(
                  Icons.warning,
                  color: Colors.orange,
                )
              : null),
    );
  }

  // Method that returns the image of a map
  Uint8List _getMapImage(ContentStoreItem map) {
    final countryCodes = map.countryCodes;
    final countryImage = MapDetails.getCountryFlag(
        countryCode: countryCodes[0], size: const Size(100, 100));
    return countryImage;
  }
}
