// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

// ignore_for_file: must_be_immutable

import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';
import 'package:gem_kit/search.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:typed_data';

class SearchPage extends StatefulWidget {
  final GemMapController controller;
  final Coordinates coordinates;

  // Method to get all the generic categories
  final categories = GenericCategories.categories;

  SearchPage({super.key, required this.controller, required this.coordinates});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _textController = TextEditingController();

  List<Landmark> landmarks = [];
  List<LandmarkCategory> selectedCategories = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _onLeadingPressed,
          icon: const Icon(CupertinoIcons.arrow_left),
        ),
        title: const Text("Search Category"),
        backgroundColor: Colors.deepPurple[900],
        foregroundColor: Colors.white,
        actions: [
          if (landmarks.isEmpty)
            IconButton(
              onPressed: () => _onSubmitted(_textController.text),
              icon: const Icon(Icons.search),
            ),
        ],
      ),
      body: Column(
        children: [
          if (landmarks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _textController,
                cursorColor: Colors.deepPurple[900],
                decoration: const InputDecoration(
                  hintText: 'Enter text',
                  hintStyle: TextStyle(color: Colors.black),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.deepPurple,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ),
          if (landmarks.isEmpty)
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: widget.categories.length,
                controller: ScrollController(),
                separatorBuilder:
                    (context, index) => const Divider(indent: 50, height: 0),
                itemBuilder: (context, index) {
                  return CategoryItem(
                    onTap: () => _onCategoryTap(index),
                    category: widget.categories[index],
                    categoryIcon: widget.categories[index].getImage(
                      size: Size(200, 200),
                    ),
                  );
                },
              ),
            ),
          if (landmarks.isNotEmpty)
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: landmarks.length,
                controller: ScrollController(),
                separatorBuilder:
                    (context, index) => const Divider(indent: 50, height: 0),
                itemBuilder: (context, index) {
                  final lmk = landmarks.elementAt(index);
                  return SearchResultItem(landmark: lmk);
                },
              ),
            ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  int? _isCategorySelected(LandmarkCategory category) {
    for (int index = 0; index < selectedCategories.length; index++) {
      if (category.id == selectedCategories[index].id) {
        return index;
      }
    }
    return null;
  }

  void _onSubmitted(String text) {
    // Setting the preferences so the results are only from the selected categories
    SearchPreferences preferences = SearchPreferences(
      maxMatches: 40,
      allowFuzzyResults: false,
      searchMapPOIs: true,
      searchAddresses: false,
    );

    // Adding in search preferences the selected categories
    for (final category in selectedCategories) {
      preferences.landmarks.addStoreCategoryId(
        category.landmarkStoreId,
        category.id,
      );
    }

    search(text, widget.coordinates, preferences);
  }

  late Completer<List<Landmark>> completer;

  // Search method
  Future<void> search(
    String text,
    Coordinates coordinates,
    SearchPreferences preferences,
  ) async {
    completer = Completer<List<Landmark>>();

    // Calling the search around position SDK method.
    // (err, results) - is a callback function that calls when the computing is done.
    // err is an error code, results is a list of landmarks
    SearchService.searchAroundPosition(
      coordinates,
      preferences: preferences,
      textFilter: text,
      (err, results) async {
        // If there is an error or there aren't any results, the method will return an empty list.
        if (err != GemError.success) {
          completer.complete([]);
          return;
        }

        if (!completer.isCompleted) completer.complete(results);
      },
    );

    final result = await completer.future;

    setState(() {
      landmarks = result;
    });
  }

  void _onLeadingPressed() {
    if (landmarks.isNotEmpty) {
      landmarks.clear();
      _textController.clear();
      selectedCategories.clear();
      setState(() {});
      return;
    }
    Navigator.pop(context);
  }

  void _onCategoryTap(int index) {
    int? categoryIndex = _isCategorySelected(widget.categories[index]);
    if (categoryIndex != null) {
      selectedCategories.removeAt(categoryIndex);
    } else {
      selectedCategories.add(widget.categories[index]);
    }
  }
}

// Class for the categories.
class CategoryItem extends StatefulWidget {
  final LandmarkCategory category;
  final Uint8List? categoryIcon;
  final VoidCallback onTap;

  const CategoryItem({
    super.key,
    required this.category,
    required this.onTap,
    required this.categoryIcon,
  });

  @override
  State<CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<CategoryItem> {
  bool _isSelected = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        widget.onTap();
        setState(() {
          _isSelected = !_isSelected;
        });
      },
      leading: Container(
        padding: const EdgeInsets.all(8),
        width: 50,
        height: 50,
        child:
            widget.categoryIcon != null
                ? Image.memory(widget.categoryIcon!)
                : SizedBox(),
      ),
      title: Text(
        widget.category.name,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing:
          (_isSelected)
              ? const SizedBox(
                width: 50,
                child: Icon(Icons.check, color: Colors.grey),
              )
              : null,
    );
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
        widget.landmark.getFormattedDistance() + widget.landmark.getAddress(),
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

    return '$street $city $country';
  }

  String getFormattedDistance() {
    String formattedDistance = '';

    double distance =
        (extraInfo.getByKey(PredefinedExtraInfoKey.gmSearchResultDistance) /
                1000)
            as double;
    formattedDistance = "${distance.toStringAsFixed(0)}km";
    return formattedDistance;
  }
}
