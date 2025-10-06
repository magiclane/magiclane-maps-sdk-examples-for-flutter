// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:magiclane_maps_flutter/content_store.dart';

import 'maps_item.dart';
import 'utils.dart';

import 'package:flutter/material.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  final mapsList = <ContentStoreItem>[];

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
        future: getMaps(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Scrollbar(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: snapshot.data!.length,
              separatorBuilder: (context, index) =>
                  const Divider(indent: 50, height: 0),
              itemBuilder: (context, index) {
                final mapItem = snapshot.data!.elementAt(index);
                return MapsItem(mapItem: mapItem);
              },
            ),
          );
        },
      ),
    );
  }
}
