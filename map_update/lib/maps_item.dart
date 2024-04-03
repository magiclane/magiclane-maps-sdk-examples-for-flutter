import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gem_kit/api/gem_contentstoreitem.dart';
import 'package:gem_kit/api/gem_mapdetails.dart';
import 'package:gem_kit/api/gem_types.dart';
import 'package:gem_kit/gem_kit_basic.dart';

class MapsItem extends StatefulWidget {
  final bool isLast;
  final ContentStoreItem map;
  final void Function(bool) onDownloadStateChanged;

  const MapsItem({super.key, this.isLast = false, required this.map, required this.onDownloadStateChanged});

  @override
  State<MapsItem> createState() => _MapsItemState();
}

class _MapsItemState extends State<MapsItem> {
  late Future<ui.Image?> _mapIconFuture;
  double downloadProgress = 0;
  late bool isDownloaded;

  @override
  void initState() {
    super.initState();
    isDownloaded = widget.map.isCompleted();
    _mapIconFuture = _getMapImage(widget.map);
    downloadProgress = widget.map.getDownloadProgress().toDouble();

    //If the map is downloading pause and start downloading again
    //so the progress indicator updates value from callback
    if (_isDownloadingOrWaiting()) {
      final errCode = widget.map.pauseDownload();
      if (errCode != GemError.success) {
        print("Download pause for item ${widget.map.getId()} failed with code ${errCode}");
        return;
      }

      Future.delayed(const Duration(milliseconds: 500)).then((value) => _downloadMap());
    }
  }

  bool _isDownloadingOrWaiting() {
    final status = widget.map.getStatus();
    return [
      EContentStoreItemStatus.CIS_DownloadQueued,
      EContentStoreItemStatus.CIS_DownloadRunning,
      EContentStoreItemStatus.CIS_DownloadWaiting,
      EContentStoreItemStatus.CIS_DownloadWaitingFreeNetwork,
      EContentStoreItemStatus.CIS_DownloadWaitingNetwork,
    ].contains(status);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: InkWell(
        onTap: () => _downloadMap(),
        child: Column(
          children: [
            Row(
              children: [
                FutureBuilder<ui.Image?>(
                  future: _mapIconFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done || snapshot.data == null) {
                      return Container();
                    }
                    return Container(
                      padding: const EdgeInsets.all(8),
                      width: 50,
                      child: RawImage(image: snapshot.data!),
                    );
                  },
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 140,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          widget.map.getName(),
                          style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          "${(widget.map.getTotalSize() / (1024.0 * 1024.0)).toStringAsFixed(2)} MB",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (isDownloaded == true)
                        const Divider(
                          color: Colors.green,
                          thickness: 5,
                        )
                      else if (_isDownloadingOrWaiting())
                        LinearProgressIndicator(
                          value: downloadProgress / 100,
                          color: Colors.blue,
                          backgroundColor: Colors.grey.shade300,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (!widget.isLast)
              const Divider(
                color: Colors.grey,
                indent: 10,
                endIndent: 20,
              )
          ],
        ),
      ),
    );
  }

  // Method that returns the image of a map
  Future<ui.Image> _getMapImage(ContentStoreItem map) async {
    final countryCodes = map.getCountryCodes();
    final rawCountryImage = await MapDetails.getCountryFlag(countryCodes[0], XyType<int>(x: 100, y: 100));
    return rawCountryImage!;
  }

  // Method that downloads the current map
  Future<void> _downloadMap() async {
    if (isDownloaded == true) return;
    await widget.map.asyncDownload((err) {
      if (err != GemError.success) {
        print("Error ${err}} while downloading map ${widget.map.mapId}");
        return;
      }

      _onCompleted();

      // Download was succesful
    }, onProgressCallback: (progress) {
      // Gets called everytime download progresses with a value between [0, 100]
      print("onProgressCallback ${progress}");
      //TODO: Remove when onCompleteCallback fixed in SDK
      if (progress == 100) _onCompleted();
      if (!mounted) return;
      setState(() {
        downloadProgress = progress.toDouble();
      });
    }, allowChargedNetworks: true);
  }

  void _onCompleted() {
    widget.onDownloadStateChanged(true);

    //Should not setState when widget is destroyed
    if (!mounted) return;
    setState(() {
      isDownloaded = true;
    });
  }
}
