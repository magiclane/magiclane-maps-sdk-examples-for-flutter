// ignore_for_file: avoid_print

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
  SearchPreferences preferences =
      SearchPreferences(maxmatches: 40, allowfuzzyresults: true);

  List<Landmark> landmarks = [];

  final TextEditingController _tecLatitude = TextEditingController();
  final TextEditingController _tecLongitude = TextEditingController();

  @override
  void initState() {
    super.initState();

    //Set initial coordonates the center of the map
    _tecLatitude.text = widget.coordinates.latitude.toString();
    _tecLongitude.text = widget.coordinates.longitude.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text("Search Location"),
        backgroundColor: Colors.deepPurple[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _tecLatitude,
              cursorColor: Colors.deepPurple[900],
              decoration: const InputDecoration(
                hintText: 'Latitude',
                hintStyle: TextStyle(color: Colors.black),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepPurple, width: 2.0),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _tecLongitude,
              cursorColor: Colors.deepPurple[900],
              decoration: const InputDecoration(
                hintText: 'Longitude',
                hintStyle: TextStyle(color: Colors.black),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepPurple, width: 2.0),
                ),
              ),
            ),
          ),
          ElevatedButton(onPressed: _onSubmitted, child: const Text("Search")),
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

  _onSubmitted() {
    final latitude = double.tryParse(_tecLatitude.text);
    final longitude = double.tryParse(_tecLongitude.text);

    if (latitude == null || longitude == null) {
      print("Invalid values for the reference coordinate.");
      return;
    }

    Coordinates coords = Coordinates(latitude: latitude, longitude: longitude);

    search(coords, preferences: preferences);
  }

  late Completer<List<Landmark>> completer;

  // Search method. Coordinates parameters are mandatory, preferences and geographicArea are optional.
  Future<void> search(Coordinates coordinates,
      {SearchPreferences? preferences,
      RectangleGeographicArea? geographicArea}) async {
    completer = Completer<List<Landmark>>();

    // Calling the search method from the sdk.
    // (err, results) - is a callback function that calls when the computing is done.
    // err is an error code, results is a list of landmarks
    SearchService.searchAroundPosition(coordinates, (err, results) async {
      // If there is an error or there aren't any results, the method will return an empty list.
      if (err != GemError.success || results == null) {
        completer.complete([]);
        return;
      }
      List<Landmark> searchResults = [];

      for (final gemLmk in results) {
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
    final data = widget.landmark.getImage(100, 100);

    return decodeImageData(data);
  }

  Future<String> _getAddress() async {
    final addressInfo = widget.landmark.getAddress();
    final street = addressInfo.getField(EAddressField.StreetName);
    final city = addressInfo.getField(EAddressField.City);
    final country = addressInfo.getField(EAddressField.Country);

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
