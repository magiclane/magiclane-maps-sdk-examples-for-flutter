// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:gem_kit/content_store.dart';
import 'package:gem_kit/core.dart';

import 'package:flutter/material.dart';

import 'package:map_update/maps_provider.dart';

class OfflineItem extends StatefulWidget {
  final ContentStoreItem mapItem;
  final void Function(ContentStoreItem) deleteMap;

  const OfflineItem({
    super.key,
    required this.mapItem,
    required this.deleteMap,
  });

  @override
  State<OfflineItem> createState() => _OfflineItemState();
}

class _OfflineItemState extends State<OfflineItem> {
  late Version _clientVersion;
  late Version _updateVersion;

  @override
  Widget build(BuildContext context) {
    final mapItem = widget.mapItem;

    bool isOld = mapItem.isUpdatable;
    _clientVersion = mapItem.clientVersion;
    _updateVersion = mapItem.updateVersion;
    return Row(
      children: [
        Expanded(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              width: 50,
              child: mapItem.image != null
                  ? Image.memory(mapItem.image!)
                  : SizedBox(),
            ),
            title: Text(
              mapItem.name,
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
                  "${(mapItem.totalSize / (1024.0 * 1024.0)).toStringAsFixed(2)} MB",
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                ),
                Text("Current Version: ${_clientVersion.str}"),
                if (_updateVersion.major != 0 && _updateVersion.minor != 0)
                  Text("New version available: ${_updateVersion.str}")
                else
                  const Text("Version up to date"),
              ],
            ),
            trailing: (isOld)
                ? const Icon(Icons.warning, color: Colors.orange)
                : null,
          ),
        ),
        IconButton(
          onPressed: () => widget.deleteMap(mapItem),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.delete),
        ),
      ],
    );
  }
}
