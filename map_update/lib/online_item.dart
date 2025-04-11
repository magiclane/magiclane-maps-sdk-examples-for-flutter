// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

// ignore_for_file: avoid_print

import 'package:gem_kit/content_store.dart';
import 'package:gem_kit/core.dart';

import 'maps_provider.dart';

import 'package:flutter/material.dart';
import 'dart:async';

class OnlineItem extends StatefulWidget {
  final ContentStoreItem mapItem;

  final void Function() onItemStatusChanged;

  const OnlineItem({
    super.key,
    required this.mapItem,
    required this.onItemStatusChanged,
  });

  @override
  State<OnlineItem> createState() => _OnlineItemState();
}

class _OnlineItemState extends State<OnlineItem> {
  int _downloadProgress = 0;

  ContentStoreItem get mapItem => widget.mapItem;

  @override
  void initState() {
    super.initState();

    _downloadProgress = mapItem.downloadProgress;

    mapItem.restartDownloadIfNecessary(
      _onMapDownloadFinished,
      onProgressCallback: _onMapDownloadProgressUpdated,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ListTile(
            onTap: () => _onTileTap(),
            leading: Container(
              padding: const EdgeInsets.all(8),
              width: 50,
              child:
                  mapItem.image != null
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
                  } else if (mapItem.isDownloadingOrWaiting) {
                    return SizedBox(
                      height: 10,
                      child: CircularProgressIndicator(
                        value: _downloadProgress.toDouble() / 100,
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
        if (_downloadProgress != 0 && !mapItem.isCompleted)
          IconButton(
            onPressed: () {
              if (mapItem.deleteContent() == GemError.success) {
                widget.onItemStatusChanged();
              }
            },
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.delete),
          ),
      ],
    );
  }

  // Method that downloads the current map
  Future<void> _onTileTap() async {
    if (mapItem.isCompleted) return;

    if (mapItem.isDownloadingOrWaiting) {
      // Pause the download.
      mapItem.pauseDownload();
      setState(() {});
    } else {
      // Download the map.
      _startMapDownload(mapItem);
    }
  }

  void _startMapDownload(ContentStoreItem mapItem) {
    mapItem.asyncDownload(
      _onMapDownloadFinished,
      onProgressCallback: _onMapDownloadProgressUpdated,
      allowChargedNetworks: true,
    );
  }

  void _onMapDownloadProgressUpdated(int progress) {
    if (mounted) {
      setState(() {
        _downloadProgress = progress;
        print('Progress: $progress');
      });
    }
  }

  void _onMapDownloadFinished(GemError err) {
    widget.onItemStatusChanged();

    // If success, update state
    if (err == GemError.success && mounted) {
      setState(() {});
    }
  }
}
