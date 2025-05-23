// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:gem_kit/content_store.dart';
import 'package:gem_kit/core.dart';

import 'custom_dialog.dart';
import 'offline_item.dart';
import 'online_item.dart';
import 'maps_provider.dart';

import 'package:flutter/material.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  final mapsList = <ContentStoreItem>[];

  MapsProvider mapsProvider = MapsProvider.instance;
  int? updateProgress;

  @override
  Widget build(BuildContext context) {
    final localMaps = MapsProvider.getOfflineMaps();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Text("Maps", style: TextStyle(color: Colors.white)),
            const SizedBox(width: 10),
            if (updateProgress != null)
              Expanded(child: ProgressBar(value: updateProgress!)),
            const SizedBox(width: 10),
          ],
        ),
        actions: [
          if (mapsProvider.canUpdateMaps)
            updateProgress != null
                ? GestureDetector(
                    onTap: () {
                      mapsProvider.cancelUpdateMaps();
                    },
                    child: const Text("Cancel Update"),
                  )
                : IconButton(
                    onPressed: () {
                      showUpdateDialog();
                    },
                    icon: const Icon(Icons.download),
                  ),
        ],
        backgroundColor: Colors.deepPurple[900],
      ),
      body: FutureBuilder<List<ContentStoreItem>?>(
        future: MapsProvider.getOnlineMaps(),
        builder: (context, snapshot) {
          //The CustomScrollView is required in order to render the online map list items lazily

          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: Text("Local: ")),
              SliverList.separated(
                separatorBuilder: (context, index) =>
                    const Divider(indent: 50, height: 0),
                itemCount: localMaps.length,
                itemBuilder: (context, index) {
                  final mapItem = localMaps.elementAt(index);
                  return OfflineItem(
                    mapItem: mapItem,
                    deleteMap: (map) {
                      if (map.deleteContent() == GemError.success) {
                        setState(() {});
                      }
                    },
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
              const SliverToBoxAdapter(child: Text("All: ")),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snapshot.data == null || snapshot.data!.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      'The list of online maps is not available (missing internet connection or expired local content).',
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
                    final mapItem = snapshot.data!.elementAt(index);
                    return OnlineItem(
                      mapItem: mapItem,
                      onItemStatusChanged: () {
                        if (mounted) setState(() {});
                      },
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  void showUpdateDialog() {
    showDialog<dynamic>(
      context: context,
      builder: (context) {
        return CustomDialog(
          title: "Update available",
          content:
              "New world map available.\nSize: ${(MapsProvider.computeUpdateSize() / (1024.0 * 1024.0)).toStringAsFixed(2)} MB\nDo you wish to update?",
          positiveButtonText: "Update",
          negativeButtonText: "Later",
          onPositivePressed: () {
            final statusId = mapsProvider.updateMaps(
              onContentUpdaterStatusChanged: onUpdateStatusChanged,
              onContentUpdaterProgressChanged: onUpdateProgressChanged,
            );

            if (statusId != GemError.success) {
              _showMessage("Error updating $statusId");
            }
          },
          onNegativePressed: () {
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _showMessage(String message) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));

  void onUpdateProgressChanged(int? value) {
    if (mounted) {
      setState(() {
        updateProgress = value;
      });
    }
  }

  void onUpdateStatusChanged(ContentUpdaterStatus status) {
    if (mounted && status.isReady) {
      showDialog<dynamic>(
        context: context,
        builder: (context) {
          return CustomDialog(
            title: "Update finished",
            content: "The update is done.",
            positiveButtonText: "Ok",
            negativeButtonText: "", // No negative button for this dialog
            onPositivePressed: () {
              //Navigator.pop(context);
            },
            onNegativePressed: () {
              // You can leave this empty or add additional behavior if needed
            },
          );
        },
      );
    }
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
        ),
      ],
    );
  }
}
