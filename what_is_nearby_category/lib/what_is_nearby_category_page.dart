// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/search.dart';

class WhatIsNearbyCategoryPage extends StatefulWidget {
  final Coordinates position;
  const WhatIsNearbyCategoryPage({super.key, required this.position});

  @override
  State<WhatIsNearbyCategoryPage> createState() =>
      _WhatIsNearbyCategoryPageState();
}

class _WhatIsNearbyCategoryPageState extends State<WhatIsNearbyCategoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        foregroundColor: Colors.white,
        title: const Text(
          "What's Nearby Category",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple[900],
      ),
      body: FutureBuilder(
        future: _getNearbyLocations(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.separated(
            itemBuilder: (contex, index) {
              return NearbyItem(
                landmark: snapshot.data!.elementAt(index),
                currentPosition: widget.position,
              );
            },
            separatorBuilder: (context, index) =>
                const Divider(indent: 0, height: 0),
            itemCount: snapshot.data!.length,
          );
        },
      ),
    );
  }

  Future<List<Landmark>?> _getNearbyLocations() async {
    // Add the gas stations category to SearchPreferences
    final preferences = SearchPreferences(searchAddresses: false);
    final genericCategories = GenericCategories.categories;
    final gasStationCategory = genericCategories.firstWhere(
      (category) => category.name == 'Gas Stations',
    );

    preferences.landmarks.addStoreCategoryId(
      gasStationCategory.landmarkStoreId,
      gasStationCategory.id,
    );

    final completer = Completer<List<Landmark>?>();
    // Perform search around position with current position and preferences set with gas stations category
    SearchService.searchAroundPosition(
      preferences: preferences,
      widget.position,
      (err, result) {
        completer.complete(result);
      },
    );
    return completer.future;
  }
}

class NearbyItem extends StatefulWidget {
  final Landmark landmark;
  final Coordinates currentPosition;
  const NearbyItem({
    super.key,
    required this.landmark,
    required this.currentPosition,
  });

  @override
  State<NearbyItem> createState() => _NearbyItemState();
}

class _NearbyItemState extends State<NearbyItem> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        widget.landmark.name,
        overflow: TextOverflow.fade,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        maxLines: 2,
      ),
      leading: widget.landmark.img.isValid
          ? Image.memory(
              widget.landmark.img.getRenderableImageBytes(
                size: Size(128, 128),
              )!,
            )
          : SizedBox(),
      trailing: Text(
        _convertDistance(
          widget.landmark.coordinates.distance(widget.currentPosition).toInt(),
        ),
        overflow: TextOverflow.fade,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
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
