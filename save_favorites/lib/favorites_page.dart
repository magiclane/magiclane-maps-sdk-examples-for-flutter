// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

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
            separatorBuilder: (context, index) => const Divider(
                  indent: 50,
                  height: 0,
                ),
            itemBuilder: (context, index) {
              final lmk = widget.landmarkList.elementAt(index);
              return FavoritesItem(landmark: lmk);
            }));
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
        child: Image.memory(
          widget.landmark.getImage(),
        ),
      ),
      title: Text(
        widget.landmark.name,
        overflow: TextOverflow.fade,
        style: const TextStyle(
            color: Colors.black, fontSize: 14, fontWeight: FontWeight.w400),
        maxLines: 2,
      ),
      subtitle: Text(
        '${widget.landmark.coordinates.latitude.toString()}, ${widget.landmark.coordinates.longitude.toString()}',
        overflow: TextOverflow.fade,
        style: const TextStyle(
            color: Colors.black, fontSize: 14, fontWeight: FontWeight.w400),
        maxLines: 2,
      ),
    );
  }
}
