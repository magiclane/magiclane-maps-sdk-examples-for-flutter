// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gem_kit/content_store.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';

import 'package:flutter/material.dart';

import 'dart:async';

class MapsItem extends StatefulWidget {
  final ContentStoreItem map;
  final void Function(bool) onDownloadStateChanged;
  final void Function(ContentStoreItem) deleteMap;

  const MapsItem({super.key, required this.map, required this.onDownloadStateChanged, required this.deleteMap});

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
        print("Download pause for item ${widget.map.id} failed with code $errCode");
        return;
      }

      Future<dynamic>.delayed(const Duration(milliseconds: 500)).then((value) => _downloadMap());
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
    return Slidable(
      enabled: _downloadProgress != 0 && !_isDownloaded,
      endActionPane: ActionPane(motion: const ScrollMotion(), extentRatio: 0.25, children: [
        SlidableAction(
          onPressed: (context) => widget.deleteMap(widget.map),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          icon: Icons.delete,
        )
      ]),
      child: ListTile(
        onTap: () => _downloadMap(),
        leading: Container(
          padding: const EdgeInsets.all(8),
          width: 50,
          child: Image.memory(_getMapImage(widget.map)),
        ),
        title: Text(
          widget.map.name,
          style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
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
                } else if (widget.map.status == ContentStoreItemStatus.paused) {
                  return const Icon(Icons.pause);
                }
                return const SizedBox.shrink();
              },
            )),
      ),
    );
  }

  // Method that returns the image of a map
  Uint8List _getMapImage(ContentStoreItem map) {
    final countryCodes = map.countryCodes;
    final countryImage = MapDetails.getCountryFlag(countryCode: countryCodes[0], size: const Size(100, 100));
    return countryImage;
  }

  // Method that downloads the current map
  Future<void> _downloadMap() async {
    if (_isDownloaded == true) return;
    if (_isDownloadingOrWaiting() == true) {
      widget.map.pauseDownload();
      setState(() {});
      return;
    }

    await widget.map.asyncDownload((err) {
      if (err != GemError.success) {
        print("Error $err while downloading map ${widget.map.mapId}");
        setState(() {});
        return;
      }

      _onCompleted();

      // Download was succesful
    }, onProgressCallback: (progress) {
      // Gets called everytime download progresses with a value between [0, 100]
      print("onProgressCallback $progress");

      if (!mounted) return;
      setState(() {
        _downloadProgress = progress.toDouble();
      });
    }, allowChargedNetworks: true);
  }

  void _onCompleted() {
    widget.onDownloadStateChanged(true);

    //Should not setState when widget is destroyed
    if (!mounted) return;
    setState(() {
      _isDownloaded = true;
    });
  }
}
