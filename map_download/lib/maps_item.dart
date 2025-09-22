// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:gem_kit/content_store.dart';
import 'package:gem_kit/core.dart';

import 'package:flutter/material.dart';

import 'utils.dart';

class MapsItem extends StatefulWidget {
  final ContentStoreItem mapItem;

  const MapsItem({super.key, required this.mapItem});

  @override
  State<MapsItem> createState() => _MapsItemState();
}

class _MapsItemState extends State<MapsItem> {
  ContentStoreItem get mapItem => widget.mapItem;

  @override
  void initState() {
    super.initState();

    restartDownloadIfNecessary(
      mapItem,
      _onMapDownloadFinished,
      onProgress: _onMapDownloadProgressUpdated,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ListTile(
            onTap: _onTileTap,
            leading: Container(
              padding: const EdgeInsets.all(8),
              width: 50,
              child: getImage(mapItem) != null
                  ? Image.memory(getImage(mapItem)!)
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
            subtitle: Text(
              "${(mapItem.totalSize / (1024.0 * 1024.0)).toStringAsFixed(2)} MB",
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
            trailing: SizedBox.square(
              dimension: 50,
              child: Builder(
                builder: (context) {
                  if (mapItem.isCompleted) {
                    return const Icon(Icons.download_done, color: Colors.green);
                  } else if (getIsDownloadingOrWaiting(mapItem)) {
                    return SizedBox(
                      height: 10,
                      child: CircularProgressIndicator(
                        value: mapItem.downloadProgress / 100.0,
                        color: Colors.blue,
                        backgroundColor: Colors.grey.shade300,
                      ),
                    );
                  } else if (mapItem.status == ContentStoreItemStatus.paused) {
                    return const Icon(Icons.pause);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
        if (mapItem.isCompleted)
          IconButton(
            onPressed: () {
              if (mapItem.deleteContent() == GemError.success) {
                setState(() {});
              }
            },
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.delete),
          ),
      ],
    );
  }

  void _onTileTap() {
    if (!mapItem.isCompleted) {
      if (getIsDownloadingOrWaiting(mapItem)) {
        _pauseDownload();
      } else {
        _downloadMap();
      }
    }
  }

  void _downloadMap() {
    // Download the map.
    mapItem.asyncDownload(
      _onMapDownloadFinished,
      onProgress: _onMapDownloadProgressUpdated,
      allowChargedNetworks: true,
    );
  }

  void _pauseDownload() {
    // Pause the download.
    mapItem.pauseDownload();
    setState(() {});
  }

  void _onMapDownloadProgressUpdated(int progress) {
    if (mounted) {
      setState(() {});
    }
  }

  void _onMapDownloadFinished(GemError err) {
    // If there is no error, we change the state
    if (mounted && err == GemError.success) {
      setState(() {});
    }
  }
}
