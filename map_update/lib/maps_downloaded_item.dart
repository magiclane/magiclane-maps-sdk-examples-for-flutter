import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gem_kit/api/gem_contentstoreitem.dart';
import 'package:gem_kit/api/gem_mapdetails.dart';
import 'package:gem_kit/api/gem_types.dart';

class MapsDownloadedItem extends StatefulWidget {
  final bool isLast;
  final ContentStoreItem map;

  const MapsDownloadedItem({super.key, this.isLast = false, required this.map});

  @override
  State<MapsDownloadedItem> createState() => _MapsDownloadedItemState();
}

class _MapsDownloadedItemState extends State<MapsDownloadedItem> {
  late Future<ui.Image?> _mapIconFuture;
  double downloadProgress = 0;
  late bool isDownloaded;
  late Version _clientVersion;
  late Version _updateVersion;

  @override
  void initState() {
    isDownloaded = widget.map.isCompleted();
    _mapIconFuture = _getMapImage(widget.map);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant MapsDownloadedItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.map.getName() != widget.map.getName()) {
      isDownloaded = widget.map.isCompleted();
      _mapIconFuture = _getMapImage(widget.map);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isOld = widget.map.isUpdatable();
    _clientVersion = widget.map.getClientVersion();
    _updateVersion = widget.map.getUpdateVersion();
    return SizedBox(
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
              Expanded(
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
                    Text("Current Version: ${_clientVersion.major}.${_clientVersion.minor}"),
                    if (_updateVersion.major != 0 && _updateVersion.minor != 0)
                      Text("New version available: ${_updateVersion.major}.${_updateVersion.minor}")
                    else
                      const Text("Version up to date"),
                  ],
                ),
              ),
              if (isOld)
                const Icon(
                  Icons.warning,
                  color: Colors.orange,
                ),
              const SizedBox(
                width: 10,
              )
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
    );
  }

  // Method that returns the image of a map
  Future<ui.Image> _getMapImage(ContentStoreItem map) async {
    final countryCodes = map.getCountryCodes();
    final rawCountryImage = await MapDetails.getCountryFlag(countryCodes[0], XyType<int>(x: 100, y: 100));
    return rawCountryImage!;
  }
}
