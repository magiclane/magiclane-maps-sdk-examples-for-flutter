// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:gem_kit/content_store.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';

import 'package:flutter/material.dart';

import 'dart:async';

class MapsItem extends StatefulWidget {
  final ContentStoreItem map;
  final void Function(bool) onDownloadStateChanged;
  final void Function(ContentStoreItem) deleteMap;

  const MapsItem(
      {super.key,
      required this.map,
      required this.onDownloadStateChanged,
      required this.deleteMap});

  @override
  State<MapsItem> createState() => _MapsItemState();
}

class _MapsItemState extends State<MapsItem> {
  double _downloadProgress = 0;
  late bool _isDownloaded;

  @override
  void initState() {
    super.initState();

    _downloadProgress = widget.map.downloadProgress.toDouble();

    //If the map is downloading pause and start downloading again
    //so the progress indicator updates value from callback
    if (_isDownloadingOrWaiting()) {
      final errCode = widget.map.pauseDownload();
      if (errCode != GemError.success) {
        print(
            "Download pause for item ${widget.map.id} failed with code $errCode");
        return;
      }

      Future<dynamic>.delayed(const Duration(milliseconds: 500))
          .then((value) => _onTileTap());
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
    _isDownloaded = widget.map.isCompleted;
    return Row(
      children: [
        Expanded(
          child: ListTile(
            onTap: () => _onTileTap(),
            leading: Container(
              padding: const EdgeInsets.all(8),
              width: 50,
              child: Image.memory(
                _getMapImage(widget.map),
                gaplessPlayback: true,
              ),
            ),
            title: Text(
              widget.map.name,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              "${(widget.map.totalSize / (1024.0 * 1024.0)).toStringAsFixed(2)} MB",
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
            ),
            trailing: SizedBox.square(
                dimension: 50,
                child: Builder(
                  builder: (context) {
                    if (_isDownloaded == true) {
                      return const Icon(
                        Icons.download_done,
                        color: Colors.green,
                      );
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
                )),
          ),
        ),
        if (_downloadProgress != 0 && !_isDownloaded)
          IconButton(
            onPressed: () => widget.deleteMap(widget.map),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.delete),
          ),
      ],
    );
  }

  // Method that returns the image of a map
  Uint8List _getMapImage(ContentStoreItem map) {
    final countryCodes = map.countryCodes;
    final countryImage = MapDetails.getCountryFlag(
        countryCode: countryCodes[0], size: const Size(100, 100));
    return countryImage;
  }

  // Method that downloads the current map
  Future<void> _onTileTap() async {
    if (_isDownloaded == true) return;
    if (_isDownloadingOrWaiting() == true) {
      _pauseDownload();
      return;
    }

    _downloadMap();
  }

  void _downloadMap() {
    // Download the map.
    widget.map.asyncDownload(_onMapDownloadFinished,
        onProgressCallback: _onMapDownloadProgressUpdated,
        allowChargedNetworks: true);
  }

  void _onMapDownloadProgressUpdated(int progress) {
    if (mounted) {
      setState(() {
        _downloadProgress = progress.toDouble();
      });
    }
  }

  void _onMapDownloadFinished(GemError err) {
    widget.onDownloadStateChanged(true);
    // If there is an error, we change the state
    if (err == GemError.success && mounted) {
      setState(() {
        _isDownloaded = true;
      });
    }
  }

  void _pauseDownload() {
    // Pause the download.
    widget.map.pauseDownload();
    setState(() {});
  }
}
