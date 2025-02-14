// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:gem_kit/content_store.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';

import 'package:flutter/material.dart';

import 'dart:async';

class MapsItem extends StatefulWidget {
  final ContentStoreItem map;

  const MapsItem({super.key, required this.map});

  @override
  State<MapsItem> createState() => _MapsItemState();
}

class _MapsItemState extends State<MapsItem> {
  late bool _isDownloaded;

  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    _isDownloaded = widget.map.isCompleted;
    _downloadProgress = widget.map.downloadProgress.toDouble();

    //If the map is downloading pause and start downloading again
    //so the progress indicator updates value from callback
    if (_isDownloadingOrWaiting()) {
      final errCode = widget.map.pauseDownload();
      if (errCode != GemError.success) {
        print(
          "Download pause for item ${widget.map.id} failed with code $errCode",
        );
        return;
      }

      Future<dynamic>.delayed(
        const Duration(milliseconds: 500),
      ).then((value) => _downloadMap());
    }
  }

  bool _isDownloadingOrWaiting() {
    final status = widget.map.status;
    return [
      ContentStoreItemStatus.downloadQueued,
      ContentStoreItemStatus.downloadRunning,
      ContentStoreItemStatus.downloadWaiting,
      ContentStoreItemStatus.downloadWaitingFreeNetwork,
      ContentStoreItemStatus.downloadWaitingNetwork,
    ].contains(status);
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
              child:
                  _getMapImage(widget.map) != null
                      ? Image.memory(_getMapImage(widget.map)!)
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
            subtitle: Text(
              "${(widget.map.totalSize / (1024.0 * 1024.0)).toStringAsFixed(2)} MB",
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
            trailing: SizedBox.square(
              dimension: 50,
              child: Builder(
                builder: (context) {
                  if (_isDownloaded == true) {
                    return const Icon(Icons.download_done, color: Colors.green);
                  } else if (_isDownloadingOrWaiting()) {
                    return SizedBox(
                      height: 10,
                      child: CircularProgressIndicator(
                        value: _downloadProgress / 100,
                        color: Colors.blue,
                        backgroundColor: Colors.grey.shade300,
                      ),
                    );
                  } else if (widget.map.status ==
                      ContentStoreItemStatus.paused) {
                    return const Icon(Icons.pause);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
        if (_isDownloaded)
          IconButton(
            onPressed: () => _deleteMap(widget.map),
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

  void _onTileTap() {
    if (_isDownloaded == true) return;

    if (_isDownloadingOrWaiting()) {
      _pauseDownload();
      return;
    }

    _downloadMap();
  }

  void _downloadMap() {
    // Download the map.
    widget.map.asyncDownload(
      _onMapDownloadFinished,
      onProgressCallback: _onMapDownloadProgressUpdated,
      allowChargedNetworks: true,
    );
  }

  void _pauseDownload() {
    // Pause the download.
    widget.map.pauseDownload();

    setState(() {});
  }

  void _onMapDownloadProgressUpdated(int progress) {
    if (mounted) {
      setState(() => _downloadProgress = progress.toDouble());
    }
  }

  void _onMapDownloadFinished(GemError err) {
    // If there is no error, we change the state
    if (err == GemError.success && mounted) {
      setState(() => _isDownloaded = true);
    }
  }

  void _deleteMap(ContentStoreItem map) {
    final deletedSuccesfully = map.deleteContent() == GemError.success;
    if (deletedSuccesfully) {
      setState(() {
        _isDownloaded = false;
        _downloadProgress = 0;
      });
    }
  }
}
