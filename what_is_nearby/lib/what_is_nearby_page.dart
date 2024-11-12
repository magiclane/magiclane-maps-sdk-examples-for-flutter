// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/search.dart';

class WhatIsNearbyPage extends StatefulWidget {
  final Coordinates position;
  const WhatIsNearbyPage({super.key, required this.position});

  @override
  State<WhatIsNearbyPage> createState() => _WhatIsNearbyPageState();
}

class _WhatIsNearbyPageState extends State<WhatIsNearbyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        foregroundColor: Colors.white,
        title: const Text(
          "What's Nearby",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple[900],
      ),
      body: FutureBuilder(
          future: _getNearbyLocations(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return ListView.separated(
                itemBuilder: (contex, index) {
                  return NearbyItem(
                    landmark: snapshot.data!.elementAt(index),
                    currentPosition: widget.position,
                  );
                },
                separatorBuilder: (context, index) => const Divider(
                      indent: 0,
                      height: 0,
                    ),
                itemCount: snapshot.data!.length);
          }),
    );
  }

  Future<List<Landmark>?> _getNearbyLocations() async {
    // Add all categories to SearchPreferences
    final preferences = SearchPreferences(searchAddresses: false);
    final genericCategories = GenericCategories.categories;
    for (final category in genericCategories) {
      preferences.landmarks
          .addStoreCategoryId(category.landmarkStoreId, category.id);
    }
    final completer = Completer<List<Landmark>?>();
    // Perform search around position with current position and all categories
    SearchService.searchAroundPosition(
        preferences: preferences, widget.position, (err, result) {
      completer.complete(result);
    });
    return completer.future;
  }
}

class NearbyItem extends StatefulWidget {
  final Landmark landmark;
  final Coordinates currentPosition;
  const NearbyItem(
      {super.key, required this.landmark, required this.currentPosition});

  @override
  State<NearbyItem> createState() => _NearbyItemState();
}

class _NearbyItemState extends State<NearbyItem> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        widget.landmark.categories.first.name,
        overflow: TextOverflow.fade,
        style: const TextStyle(
            color: Colors.black, fontSize: 14, fontWeight: FontWeight.w400),
        maxLines: 2,
      ),
      trailing: Text(
        _convertDistance(widget.landmark.coordinates
            .distance(widget.currentPosition)
            .toInt()),
        overflow: TextOverflow.fade,
        style: const TextStyle(
            color: Colors.black, fontSize: 14, fontWeight: FontWeight.w400),
      ),
    );
  }

  String _convertDistance(int meters) {
    if (meters >= 1000) {
      double kilometers = meters / 1000;
      return '${kilometers.toStringAsFixed(1)} km';
    } else {
      return '${meters.toString()} m';
    }
  }
}
