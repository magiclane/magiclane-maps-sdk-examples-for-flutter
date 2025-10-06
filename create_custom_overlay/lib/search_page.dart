// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/search.dart';

import 'package:flutter/material.dart';

import 'dart:async';

class SearchPage extends StatefulWidget {
  final Coordinates coordinates;
  final SearchPreferences preferences;
  const SearchPage({
    super.key,
    required this.coordinates,
    required this.preferences,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<OverlayItem> overlayItems = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text(
          "Search Overlay Items",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onSubmitted: (value) => _onSearchSubmitted(value),
              cursorColor: Colors.deepPurple[900],
              decoration: const InputDecoration(
                hintText: 'Hint: York',
                hintStyle: TextStyle(color: Colors.black),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepPurple, width: 2.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: overlayItems.length,
              controller: ScrollController(),
              separatorBuilder: (context, index) =>
                  const Divider(indent: 50, height: 0),
              itemBuilder: (context, index) {
                final lmk = overlayItems.elementAt(index);
                return SearchResultItem(overlayItem: lmk);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onSearchSubmitted(String text) {
    search(text, widget.coordinates, preferences: widget.preferences);
  }

  // Search method. Text and coordinates parameters are mandatory, preferences are optional.
  Future<void> search(
    String text,
    Coordinates coordinates, {
    SearchPreferences? preferences,
  }) async {
    Completer<List<OverlayItem>> completer = Completer<List<OverlayItem>>();

    // Calling the search method from the sdk.
    // (err, results) - is a callback function that calls when the computing is done.
    // err is an error code, results is a list of landmarks
    SearchService.search(text, coordinates, preferences: preferences, (
      err,
      results,
    ) async {
      // If there is an error or there aren't any results, the method will return an empty list.
      if (err != GemError.success) {
        completer.complete([]);
        return;
      }

      // Convert Landmarks to OverlayItems
      final overlayItems = results
          .map((lmk) => lmk.overlayItem)
          .where((item) => item != null)
          .cast<OverlayItem>()
          .toList();

      if (!completer.isCompleted) completer.complete(overlayItems);
    });

    final result = await completer.future;

    setState(() {
      overlayItems = result;
    });
  }
}

// Class for the search results.
class SearchResultItem extends StatefulWidget {
  final OverlayItem overlayItem;

  const SearchResultItem({super.key, required this.overlayItem});

  @override
  State<SearchResultItem> createState() => _SearchResultItemState();
}

class _SearchResultItemState extends State<SearchResultItem> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.of(context).pop(widget.overlayItem),
      leading: Container(
        padding: const EdgeInsets.all(8),
        child: widget.overlayItem.img.isValid
            ? Image.memory(
                widget.overlayItem.img.getRenderableImageBytes(
                  size: Size(50, 50),
                )!,
              )
            : SizedBox(),
      ),
      title: Text(
        widget.overlayItem.name,
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
