// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:gem_kit/content_store.dart';
import 'package:gem_kit/core.dart';
import 'package:map_style_update/custom_dialog.dart';
import 'package:map_style_update/offline_item.dart';
import 'package:map_style_update/online_item.dart';
import 'package:map_style_update/styles_provider.dart';

class StylesPage extends StatefulWidget {
  final StylesProvider stylesProvider;
  const StylesPage({super.key, required this.stylesProvider});

  @override
  State<StylesPage> createState() => _MapStylesUpdatePageState();
}

class _MapStylesUpdatePageState extends State<StylesPage> {
  final stylesList = <ContentStoreItem>[];

  StylesProvider stylesProvider = StylesProvider.instance;

  int? updateProgress;

  @override
  Widget build(BuildContext context) {
    final offlineStyles = StylesProvider.getOfflineStyles();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.deepPurple[900],
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Text("Update", style: TextStyle(color: Colors.white)),
            const SizedBox(width: 10),
            if (updateProgress != null)
              Expanded(child: ProgressBar(value: updateProgress!)),
            const SizedBox(width: 10),
          ],
        ),
        actions: [
          if (stylesProvider.canUpdateStyles)
            updateProgress != null
                ? GestureDetector(
                    onTap: () {
                      stylesProvider.cancelUpdateStyles();
                    },
                    child: const Text("Cancel"),
                  )
                : IconButton(
                    onPressed: () {
                      showUpdateDialog();
                    },
                    icon: const Icon(Icons.download),
                  ),
        ],
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
                    child: OfflineItem(
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
                      const Divider(indent: 20, height: 0),
                  itemBuilder: (context, index) {
                    final styleItem = snapshot.data!.elementAt(index);
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: OnlineItem(
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

  void showUpdateDialog() {
    showDialog<dynamic>(
      context: context,
      builder: (context) {
        return CustomDialog(
          title: "Update available",
          content:
              "New style update available.\nSize: ${(StylesProvider.computeUpdateSize() / (1024.0 * 1024.0)).toStringAsFixed(2)} MB\nDo you wish to update?",
          positiveButtonText: "Update",
          negativeButtonText: "Later",
          onPositivePressed: () {
            final statusId = stylesProvider.updateStyles(
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
    if (mounted && isReady(status)) {
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
        Text("$value%", style: TextStyle(fontSize: 12.0)),
        LinearProgressIndicator(
          value: value.toDouble() * 0.01,
          color: Colors.white,
          backgroundColor: Colors.grey,
        ),
      ],
    );
  }
}
