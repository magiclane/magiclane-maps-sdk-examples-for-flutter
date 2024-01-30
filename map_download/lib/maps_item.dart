import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gem_kit/api/gem_contentstoreitem.dart';
import 'package:gem_kit/api/gem_mapdetails.dart';
import 'package:gem_kit/api/gem_types.dart';
import 'package:gem_kit/gem_kit_basic.dart';
import 'package:map_download/utility.dart';

class MapsItem extends StatefulWidget {
  final bool isLast;
  final ContentStoreItem map;

  const MapsItem({super.key, this.isLast = false, required this.map});

  @override
  State<MapsItem> createState() => _MapsItemState();
}

class _MapsItemState extends State<MapsItem> {
  late Future<Uint8List?> _mapIconFuture;
  double downloadProgress = 0;
  late bool isDownloaded;

  @override
  void initState() {
    isDownloaded = widget.map.isCompleted();
    _mapIconFuture = _getMapImage(widget.map);
    super.initState();
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
                FutureBuilder<Uint8List?>(
                  future: _mapIconFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done ||
                        snapshot.data == null) {
                      return Container();
                    }
                    return Container(
                      padding: const EdgeInsets.all(8),
                      width: 50,
                      child: Image.memory(snapshot.data!),
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
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
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
                      else if (downloadProgress != 0)
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
  Future<Uint8List> _getMapImage(ContentStoreItem map) async {
    final countryCodes = map.getCountryCodes();
    final rawCountryImage =
        MapDetails.getCountryFlag(countryCodes[0], XyType<int>(x: 100, y: 100));
    return await decodeImageData(rawCountryImage) ?? Uint8List(0);
  }

  // Method that downloads the current map
  Future<void> _downloadMap() async {
    if (isDownloaded == true) return;
    await widget.map.asyncDownload((err) {
      if (err != GemError.success) {
        // An error was encountered during download
        return;
      }
      setState(() {
        isDownloaded = true;
      });
      // Download was succesful
    }, onProgressCallback: (progress) {
      // Gets called everytime download progresses with a value between [0, 100]
      setState(() {
        downloadProgress = progress.toDouble();
      });
    }, allowChargedNetworks: true);
  }
}
