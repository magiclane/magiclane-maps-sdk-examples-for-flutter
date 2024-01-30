import 'dart:async';

import 'package:flutter/material.dart';

import 'package:gem_kit/api/gem_contentstore.dart';
import 'package:gem_kit/api/gem_contentstoreitem.dart';
import 'package:gem_kit/api/gem_contenttypes.dart';
import 'package:gem_kit/gem_kit_basic.dart';

import 'package:map_download/maps_item.dart';

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
        title: const Text(
          "Maps list",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple[900],
      ),
      body: FutureBuilder<List<ContentStoreItem>>(
          future: _getMaps(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: snapshot.data!.length,
              controller: ScrollController(),
              itemBuilder: (context, index) {
                final map = snapshot.data!.elementAt(index);
                bool isLast =
                    (index == snapshot.data!.length - 1) ? true : false;
                return MapsItem(
                  map: map,
                  isLast: isLast,
                );
              },
            );
          }),
    );
  }

  // Method to load the maps
  Future<List<ContentStoreItem>> _getMaps() async {
    Completer<List<ContentStoreItem>> mapsList =
        Completer<List<ContentStoreItem>>();
    await ContentStore.asyncGetStoreContentList(EContentType.CT_RoadMap,
        (err, items, isCached) {
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
}
