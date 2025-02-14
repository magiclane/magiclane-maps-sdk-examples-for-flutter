// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:gem_kit/content_store.dart';
import 'package:gem_kit/core.dart';

import 'maps_item.dart';

import 'package:flutter/material.dart';

import 'dart:async';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  List<ContentStoreItem> mapsList = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        foregroundColor: Colors.white,
        title: const Text("Maps List", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple[900],
      ),
      body: FutureBuilder<List<ContentStoreItem>>(
        future: _getMaps(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Scrollbar(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: snapshot.data!.length,
              separatorBuilder:
                  (context, index) => const Divider(indent: 50, height: 0),
              itemBuilder: (context, index) {
                final map = snapshot.data!.elementAt(index);
                return MapsItem(map: map);
              },
            ),
          );
        },
      ),
    );
  }

  // Method to load the maps
  Future<List<ContentStoreItem>> _getMaps() async {
    Completer<List<ContentStoreItem>> mapsList =
        Completer<List<ContentStoreItem>>();
    ContentStore.asyncGetStoreContentList(ContentType.roadMap, (
      err,
      items,
      isCached,
    ) {
      if (err == GemError.success && items != null) {
        mapsList.complete(items);
      }
    });
    return mapsList.future;
  }
}
