// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:gem_kit/core.dart';
import 'package:gem_kit/search.dart';

import 'package:flutter/material.dart';

import 'dart:async';

class SearchPage extends StatefulWidget {
  final Coordinates coordinates;
  const SearchPage({super.key, required this.coordinates});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Landmark> landmarks = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text("Text Search"),
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
                hintText: 'Enter text',
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
              itemCount: landmarks.length,
              controller: ScrollController(),
              separatorBuilder: (context, index) =>
                  const Divider(indent: 50, height: 0),
              itemBuilder: (context, index) {
                final lmk = landmarks.elementAt(index);
                return SearchResultItem(landmark: lmk);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onSearchSubmitted(String text) {
    SearchPreferences preferences = SearchPreferences(
      maxMatches: 40,
      allowFuzzyResults: true,
    );

    search(text, widget.coordinates, preferences: preferences);
  }

  // Search method. Text and coordinates parameters are mandatory, preferences are optional.
  Future<void> search(
    String text,
    Coordinates coordinates, {
    SearchPreferences? preferences,
  }) async {
    Completer<List<Landmark>> completer = Completer<List<Landmark>>();

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

      if (!completer.isCompleted) completer.complete(results);
    });

    final result = await completer.future;

    setState(() {
      landmarks = result;
    });
  }
}

// Class for the search results.
class SearchResultItem extends StatefulWidget {
  final Landmark landmark;

  const SearchResultItem({super.key, required this.landmark});

  @override
  State<SearchResultItem> createState() => _SearchResultItemState();
}

class _SearchResultItemState extends State<SearchResultItem> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.of(context).pop(widget.landmark),
      leading: Container(
        padding: const EdgeInsets.all(8),
        child: widget.landmark.img.isValid
            ? Image.memory(
                widget.landmark.img.getRenderableImageBytes(
                  size: Size(50, 50),
                )!,
              )
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
        '${widget.landmark.getFormattedDistance()} ${widget.landmark.getAddress()}',
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

// Define an extension for landmark for formatting the address and the distance.
extension LandmarkExtension on Landmark {
  String getAddress() {
    final addressInfo = address;
    final street = addressInfo.getField(AddressField.streetName);
    final city = addressInfo.getField(AddressField.city);
    final country = addressInfo.getField(AddressField.country);

    return " ${street ?? ""} ${city ?? ""} ${country ?? ""}";
  }

  String getFormattedDistance() {
    String formattedDistance = '';

    double distance =
        (extraInfo.getByKey(PredefinedExtraInfoKey.gmSearchResultDistance) /
            1000) as double;
    formattedDistance = "${distance.toStringAsFixed(0)}km";
    return formattedDistance;
  }
}
