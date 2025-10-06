// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:magiclane_maps_flutter/content_store.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:map_style_update/styles_provider.dart';

class OfflineItem extends StatefulWidget {
  final ContentStoreItem styleItem;

  final void Function() onItemStatusChanged;

  const OfflineItem({
    super.key,
    required this.styleItem,
    required this.onItemStatusChanged,
  });

  @override
  State<OfflineItem> createState() => _OfflineItemState();
}

class _OfflineItemState extends State<OfflineItem> {
  late Version _clientVersion;
  late Version _updateVersion;

  @override
  Widget build(BuildContext context) {
    final styleItem = widget.styleItem;

    bool isOld = styleItem.isUpdatable;
    _clientVersion = styleItem.clientVersion;
    _updateVersion = styleItem.updateVersion;
    return InkWell(
      onTap: () => _onStyleTap(),
      child: Row(
        children: [
          Image.memory(
            getStyleImage(styleItem, Size(400, 300))!,
            width: 175,
            gaplessPlayback: true,
          ),
          Expanded(
            child: ListTile(
              title: Text(
                styleItem.name,
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
                    "${(styleItem.totalSize / (1024.0 * 1024.0)).toStringAsFixed(2)} MB",
                    style: const TextStyle(color: Colors.black, fontSize: 16),
                  ),
                  Text("Current Version: ${getString(_clientVersion)}"),
                  if (_updateVersion.major != 0 && _updateVersion.minor != 0)
                    Text("New version available: ${getString(_updateVersion)}")
                  else
                    const Text("Version up to date"),
                ],
              ),
              trailing: (isOld)
                  ? const Icon(Icons.warning, color: Colors.orange)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // Method that downloads the current style
  void _onStyleTap() {
    final item = widget.styleItem;

    if (item.isUpdatable) return;

    if (item.isCompleted) {
      Navigator.of(context).pop(item);
      return;
    }

    if (getIsDownloadingOrWaiting(item)) {
      // Pause the download.
      item.pauseDownload();
      setState(() {});
    } else {
      // Download the style.
      _startStyleDownload(item);
    }
  }

  void _onStyleDownloadProgressUpdated(int progress) {
    if (mounted) {
      setState(() {
        print('Progress: $progress');
      });
    }
  }

  void _onStyleDownloadFinished(GemError err) {
    widget.onItemStatusChanged();

    // If success, update state
    if (err == GemError.success && mounted) {
      setState(() {});
    }
  }

  void _startStyleDownload(ContentStoreItem styleItem) {
    // Download style
    styleItem.asyncDownload(
      _onStyleDownloadFinished,
      onProgress: _onStyleDownloadProgressUpdated,
      allowChargedNetworks: true,
    );
  }
}
