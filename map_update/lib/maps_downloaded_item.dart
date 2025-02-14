// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:gem_kit/content_store.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';

import 'package:flutter/material.dart';

import 'dart:typed_data';

class MapsDownloadedItem extends StatefulWidget {
  final ContentStoreItem map;
  final void Function(ContentStoreItem) deleteMap;

  const MapsDownloadedItem({
    super.key,
    required this.map,
    required this.deleteMap,
  });

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
    return Row(
      children: [
        Expanded(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              width: 50,
              child:
                  _getMapImage(widget.map) != null
                      ? Image.memory(
                        _getMapImage(widget.map)!,
                        gaplessPlayback: true,
                      )
                      : SizedBox(),
            ),
            title: Text(
              widget.map.name,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${(widget.map.totalSize / (1024.0 * 1024.0)).toStringAsFixed(2)} MB",
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                ),
                Text(
                  "Current Version: ${_clientVersion.major}.${_clientVersion.minor}",
                ),
                if (_updateVersion.major != 0 && _updateVersion.minor != 0)
                  Text(
                    "New version available: ${_updateVersion.major}.${_updateVersion.minor}",
                  )
                else
                  const Text("Version up to date"),
              ],
            ),
            trailing:
                (isOld)
                    ? const Icon(Icons.warning, color: Colors.orange)
                    : null,
          ),
        ),
        IconButton(
          onPressed: () => widget.deleteMap(widget.map),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.delete),
        ),
      ],
    );
  }

  // Method that returns the image of a map
  Uint8List? _getMapImage(ContentStoreItem map) {
    final countryCodes = map.countryCodes;
    final countryImage = MapDetails.getCountryFlag(
      countryCode: countryCodes[0],
      size: const Size(100, 100),
    );
    return countryImage;
  }
}
