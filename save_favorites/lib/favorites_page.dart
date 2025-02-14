// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:gem_kit/core.dart';

import 'package:flutter/material.dart';

class FavoritesPage extends StatefulWidget {
  final List<Landmark> landmarkList;
  const FavoritesPage({super.key, required this.landmarkList});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
        title: const Text("Favorites list"),
        backgroundColor: Colors.deepPurple[900],
      ),
      body: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: widget.landmarkList.length,
        separatorBuilder:
            (context, index) => const Divider(indent: 50, height: 0),
        itemBuilder: (context, index) {
          final lmk = widget.landmarkList.elementAt(index);
          return FavoritesItem(landmark: lmk);
        },
      ),
    );
  }
}

// Class for favorites landmark.
class FavoritesItem extends StatefulWidget {
  final Landmark landmark;

  const FavoritesItem({super.key, required this.landmark});

  @override
  State<FavoritesItem> createState() => _FavoritesItemState();
}

class _FavoritesItemState extends State<FavoritesItem> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.of(context).pop(widget.landmark),
      leading: Container(
        padding: const EdgeInsets.all(8),
        width: 50,
        child:
            widget.landmark.getImage() != null
                ? Image.memory(widget.landmark.getImage()!)
                : SizedBox(),
      ),
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
      subtitle: Text(
        '${widget.landmark.coordinates.latitude.toString()}, ${widget.landmark.coordinates.longitude.toString()}',
        overflow: TextOverflow.fade,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        maxLines: 2,
      ),
    );
  }
}
