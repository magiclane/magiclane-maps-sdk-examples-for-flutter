import 'package:gem_kit/api/gem_geographicarea.dart';
import 'package:gem_kit/api/gem_searchpreferences.dart';
import 'package:gem_kit/gem_kit_basic.dart';
import 'package:gem_kit/gem_kit_map_controller.dart';
import 'package:gem_kit/api/gem_addressinfo.dart';
import 'package:gem_kit/api/gem_coordinates.dart';
import 'package:gem_kit/api/gem_landmark.dart';
import 'package:gem_kit/api/gem_searchservice.dart';

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  final GemMapController controller;
  final Coordinates coordinates;
  const SearchPage(
      {super.key, required this.controller, required this.coordinates});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late SearchService gemSearchService;
  SearchPreferences preferences =
      SearchPreferences(maxmatches: 40, allowfuzzyresults: true);

  List<Landmark> landmarks = [];

  @override
  void initState() {
    SearchService.create(widget.controller.mapId).then((value) {
      gemSearchService = value;
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text("Search Text"),
        backgroundColor: Colors.deepPurple[900],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onSubmitted: (value) => _onSubmitted(value),
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
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: landmarks.length,
              controller: ScrollController(),
              itemBuilder: (context, index) {
                final lmk = landmarks.elementAt(index);
                return SearchResultItem(
                  onTap: () => Navigator.of(context).pop(lmk),
                  landmark: lmk,
                );
              },
            ),
          )
        ],
      ),
    );
  }

  _onSubmitted(String text) {
    search(text, widget.coordinates, preferences: preferences);
  }

  late Completer<List<Landmark>> completer;

// Search method. Text and coordinates parameters are mandatory, preferences and geographicArea are optional.
  Future<void> search(String text, Coordinates coordinates,
      {SearchPreferences? preferences,
      RectangleGeographicArea? geographicArea}) async {
    completer = Completer<List<Landmark>>();

// Calling the search method from the sdk.
// (err, results) - is a callback function that calls when the computing is done.
// err is an error code, results is a list of landmarks
    gemSearchService.search(text, coordinates, (err, results) async {
      // If there is an error or there aren't any results, the method will return an empty list.
      if (err != GemError.success || results == null) {
        completer.complete([]);
        return;
      }
      final size = await results.size();
      List<Landmark> searchResults = [];

      for (int i = 0; i < size; i++) {
        final gemLmk = await results.at(i);

        searchResults.add(gemLmk);
      }

      if (!completer.isCompleted) completer.complete(searchResults);
    });

    final result = await completer.future;

    setState(() {
      landmarks = result;
    });
  }
}

// Class for the search results.
class SearchResultItem extends StatefulWidget {
  final bool isLast;
  final Landmark landmark;
  final VoidCallback? onTap;

  const SearchResultItem(
      {super.key, this.isLast = false, required this.landmark, this.onTap});

  @override
  State<SearchResultItem> createState() => _SearchResultItemState();
}

class _SearchResultItemState extends State<SearchResultItem> {
  late Future<Uint8List?> _landmarkIconFuture;
  late Future<ExtraInfo> _extraInfoFuture;
  late Future<String> _addressFuture;

  @override
  void initState() {
    _landmarkIconFuture = _decodeLandmarkIcon();
    _addressFuture = _getAddress();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          children: [
            Row(
              children: [
                FutureBuilder<Uint8List?>(
                    future: _landmarkIconFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done ||
                          snapshot.data == null) {
                        return Container();
                      }
                      return Container(
                        padding: const EdgeInsets.all(8),
                        width: 50,
                        child: Image.memory(snapshot.data!),
                      );
                    }),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 140,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          widget.landmark.getName(),
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 3),
                            child: Builder(
                              builder: (context) {
                                String formattedDistance = '';

                                final extraInfo =
                                    widget.landmark.getExtraInfo();
                                double distance = (extraInfo.getByKey(
                                        PredefinedExtraInfoKey
                                            .gmSearchResultDistance) /
                                    1000) as double;
                                formattedDistance =
                                    "${distance.toStringAsFixed(0)}km";

                                return Text(formattedDistance);
                              },
                            ),
                          ),
                          FutureBuilder<String>(
                            future: _addressFuture,
                            builder: (context, snapshot) {
                              String address = '';

                              if (snapshot.hasData) {
                                address = snapshot.data!;
                              }

                              return SizedBox(
                                width: MediaQuery.of(context).size.width - 210,
                                child: Text(
                                  address,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400),
                                ),
                              );
                            },
                          )
                        ],
                      )
                    ],
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.north_west_outlined,
                        color: Colors.grey,
                      )),
                )
              ],
            ),
            if (!widget.isLast)
              const Divider(
                color: Colors.grey,
                indent: 10,
                endIndent: 20,
              )
          ],
        ),
      ),
    );
  }

  Future<Uint8List?> _decodeLandmarkIcon() async {
    final data = await widget.landmark.getImage(100, 100);

    return decodeImageData(data);
  }

  Future<String> _getAddress() async {
    final addressInfo = await widget.landmark.getAddress();
    final street = await addressInfo.getField(EAddressField.StreetName);
    final city = await addressInfo.getField(EAddressField.City);
    final country = await addressInfo.getField(EAddressField.Country);

    return '$street $city $country';
  }

  Future<Uint8List?> decodeImageData(Uint8List data) async {
    Completer<Uint8List?> c = Completer<Uint8List?>();

    int width = 100;
    int height = 100;

    ui.decodeImageFromPixels(data, width, height, ui.PixelFormat.rgba8888,
        (ui.Image img) async {
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        c.complete(null);
      }
      final list = data!.buffer.asUint8List();
      c.complete(list);
    });

    return c.future;
  }
}
