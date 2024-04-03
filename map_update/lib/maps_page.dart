// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gem_kit/api/gem_contentstore.dart';
import 'package:gem_kit/api/gem_contentstoreitem.dart';
import 'package:gem_kit/api/gem_contenttypes.dart';
import 'package:gem_kit/api/gem_contentupdate.dart';
import 'package:gem_kit/core.dart';

import 'package:map_update/maps_downloaded_item.dart';
import 'package:map_update/maps_item.dart';

import 'update_persistence.dart';

class MapsPage extends StatefulWidget {
  final int mapId;
  const MapsPage({super.key, required this.mapId});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  List<ContentStoreItem> mapsList = [];
  UpdatePersistence updatePersistence = UpdatePersistence.instance;
  int? updateProgress;

  @override
  void initState() {
    super.initState();

    updatePersistence.onProgress = onProgressListener;
    updatePersistence.onStatusChanged = onStatusChanged;

    checkForUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final localMaps = _getDownloadedMaps();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Text(
              "Maps",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(width: 10),
            if (updateProgress != null) Expanded(child: ProgressBar(value: updateProgress!)),
            const SizedBox(width: 10),
          ],
        ),
        actions: [
          updateProgress != null
              ? GestureDetector(
                  onTap: () {
                    updatePersistence.cancel();
                  },
                  child: const Text("Cancel Update"),
                )
              : IconButton(
                  onPressed: () {
                    showUpdateDialog();
                  },
                  icon: const Icon(Icons.download),
                )
        ],
        backgroundColor: Colors.deepPurple[900],
      ),
      body: FutureBuilder<List<ContentStoreItem>>(
          future: _getMaps(),
          builder: (context, snapshot) {
            //The CustomScrollView is required in order to render the online map list items lazily
            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: Text("Local: ")),
                SliverList.builder(
                  itemCount: localMaps.length,
                  itemBuilder: (context, index) {
                    final map = localMaps.elementAt(index);
                    bool isLast = (index == localMaps.length - 1) ? true : false;
                    return MapsDownloadedItem(
                      map: map,
                      isLast: isLast,
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
                const SliverToBoxAdapter(child: Text("All: ")),
                if (!snapshot.hasData || snapshot.data == null)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final map = snapshot.data!.elementAt(index);
                      bool isLast = (index == snapshot.data!.length - 1) ? true : false;
                      return MapsItem(
                        map: map,
                        isLast: isLast,
                        onDownloadStateChanged: (p0) {
                          if (!mounted) return;
                          //Update page after map download
                          setState(
                            () {},
                          );
                        },
                      );
                    },
                  ),
              ],
            );
          }),
    );
  }

  // Method to load the online map list
  Future<List<ContentStoreItem>> _getMaps() async {
    Completer<List<ContentStoreItem>> mapsList = Completer<List<ContentStoreItem>>();
    await ContentStore.asyncGetStoreContentList(EContentType.CT_RoadMap, (err, items, isCached) {
      if (err != GemError.success || items == null) {
        return;
      }
      List<ContentStoreItem> list = [];
      for (final item in items) {
        list.add(item);
      }
      mapsList.complete(list);
    });

    return mapsList.future;
  }

  // Method to load the downloaded map list
  List<ContentStoreItem> _getDownloadedMaps() {
    final localMaps = ContentStore.getLocalContentList(EContentType.CT_RoadMap);

    List<ContentStoreItem> result = [];

    for (final map in localMaps) {
      result.add(map);
    }

    return result;
  }

  void checkForUpdate() {
    final id = updatePersistence.checkForUpdate();

    if (id != GemError.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error checking for updates $id")));
    }
  }

  void showUpdateDialog() {
    if (!updatePersistence.isOldData) {
      showDialog(
        context: context,
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AlertDialog(
                title: const Text("No updates available"),
                content: const Column(
                  children: [Text("You are up to date.")],
                ),
                actions: [
                  CupertinoDialogAction(
                    child: const Text("Ok"),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          );
        },
      );

      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AlertDialog(
              title: const Text("Update available"),
              content: Column(
                children: [
                  const Text("New world map available."),
                  Text("Size: ${(computeUpdateSize() / (1024.0 * 1024.0)).toStringAsFixed(2)} MB"),
                  const Text("Do you wish to update?")
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text("Later"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                CupertinoDialogAction(
                  child: const Text("Update"),
                  onPressed: () {
                    if (!updatePersistence.isOldData) {
                      Navigator.pop(context);
                      return;
                    }

                    final statusId = updatePersistence.update();

                    if (statusId != GemError.success) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating $statusId")));
                    }

                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  int computeUpdateSize() {
    final localMaps = ContentStore.getLocalContentList(EContentType.CT_RoadMap);

    int sum = 0;

    for (final localmap in localMaps) {
      if (localmap.isUpdatable()) {
        final status = localmap.getStatus();

        // The map has to be fully downloaded
        if (status == EContentStoreItemStatus.CIS_Completed) {
          sum += localmap.getUpdateSize();
        }
      }
    }
    return sum;
  }

  void onProgressListener(int? value) {
    if (!mounted) return;

    setState(() {
      updateProgress = value;
    });
  }

  void onStatusChanged(int code) {
    if (!mounted) return;

    if (!(code == EContentUpdaterStatus.FullyReady.id || code == EContentUpdaterStatus.PartiallyReady.id)) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AlertDialog(
              title: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Update finished"),
                ],
              ),
              content: const Column(
                children: [
                  Text("The update is done."),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text("Ok"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class ProgressBar extends StatelessWidget {
  final int value;

  const ProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("$value%"),
        LinearProgressIndicator(
          value: value.toDouble() * 0.01,
          color: Colors.white,
          backgroundColor: Colors.grey,
        )
      ],
    );
  }
}
