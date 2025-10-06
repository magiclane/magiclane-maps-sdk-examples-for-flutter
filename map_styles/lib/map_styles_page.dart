// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:flutter/material.dart';
import 'package:magiclane_maps_flutter/content_store.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:map_styles/styles_provider.dart';

// ignore_for_file: avoid_print

class MapStylesPage extends StatefulWidget {
  const MapStylesPage({super.key});

  @override
  State<MapStylesPage> createState() => _MapStylesPageState();
}

class _MapStylesPageState extends State<MapStylesPage> {
  final stylesList = <ContentStoreItem>[];

  StylesProvider stylesProvider = StylesProvider.instance;

  @override
  Widget build(BuildContext context) {
    final offlineStyles = StylesProvider.getOfflineStyles();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.deepPurple[900],
        foregroundColor: Colors.white,
        title: Text("Map styles"),
      ),
      body: FutureBuilder<List<ContentStoreItem>?>(
        future: StylesProvider.getOnlineStyles(),
        builder: (context, snapshot) {
          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: Text("Local: ")),
              SliverList.separated(
                separatorBuilder: (context, index) =>
                    const Divider(indent: 20, height: 0),
                itemCount: offlineStyles.length,
                itemBuilder: (context, index) {
                  final styleItem = offlineStyles.elementAt(index);
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: StyleItem(
                      styleItem: styleItem,
                      onItemStatusChanged: () {
                        if (mounted) setState(() {});
                      },
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: Text("Online: ")),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snapshot.data == null || snapshot.data!.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      'The list of online styles is not available (missing internet connection or expired local content).',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                SliverList.separated(
                  itemCount: snapshot.data!.length,
                  separatorBuilder: (context, index) =>
                      const Divider(indent: 50, height: 0),
                  itemBuilder: (context, index) {
                    final styleItem = snapshot.data!.elementAt(index);
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: StyleItem(
                        styleItem: styleItem,
                        onItemStatusChanged: () {
                          if (mounted) setState(() {});
                        },
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class StyleItem extends StatefulWidget {
  final ContentStoreItem styleItem;

  final void Function() onItemStatusChanged;

  const StyleItem({
    super.key,
    required this.styleItem,
    required this.onItemStatusChanged,
  });

  @override
  State<StyleItem> createState() => _StyleItemState();
}

class _StyleItemState extends State<StyleItem> {
  int _downloadProgress = 0;

  @override
  void initState() {
    super.initState();

    final styleItem = widget.styleItem;

    _downloadProgress = styleItem.downloadProgress;

    // If the style is downloading pause and start downloading again
    // so the progress indicator updates value from callback
    if (getIsDownloadingOrWaiting(styleItem)) {
      final errCode = styleItem.pauseDownload();

      if (errCode == GemError.success) {
        Future.delayed(Duration(seconds: 1), () {
          _startStyleDownload(styleItem);
        });
      } else {
        print(
          "Download pause for item ${styleItem.id} failed with code $errCode",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final styleItem = widget.styleItem;

    return InkWell(
      onTap: () => _onStyleTap(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.memory(
            getStyleImage(styleItem, Size(400, 300))!,
            width: 175,
            gaplessPlayback: true,
          ),
          Expanded(
            child: ListTile(
              title: Text(
                maxLines: 5,
                styleItem.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                "${(styleItem.totalSize / (1024.0 * 1024.0)).toStringAsFixed(2)} MB",
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
              trailing: SizedBox.square(
                dimension: 50,
                child: Builder(
                  builder: (context) {
                    if (styleItem.isCompleted) {
                      return const Icon(
                        Icons.download_done,
                        color: Colors.green,
                      );
                    } else if (getIsDownloadingOrWaiting(styleItem)) {
                      return SizedBox(
                        height: 10,
                        child: CircularProgressIndicator(
                          value: _downloadProgress.toDouble() / 100,
                          color: Colors.blue,
                          backgroundColor: Colors.grey.shade300,
                        ),
                      );
                    } else if (styleItem.status ==
                        ContentStoreItemStatus.paused) {
                      return const Icon(Icons.pause);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method that downloads the current selected map style
  void _onStyleTap() {
    final item = widget.styleItem;

    if (item.isCompleted) {
      Navigator.of(context).pop(item);
      return;
    }

    if (getIsDownloadingOrWaiting(item)) {
      // Pause the download.
      item.pauseDownload();
      setState(() {});
    } else {
      // Download the map.
      _startStyleDownload(item);
    }
  }

  void _onStyleDownloadProgressUpdated(int progress) {
    if (mounted) {
      setState(() {
        _downloadProgress = progress;
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
