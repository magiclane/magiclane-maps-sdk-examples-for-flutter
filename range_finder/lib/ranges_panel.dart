// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';
import 'package:gem_kit/routing.dart';

import 'range.dart';
import 'utility.dart';

import 'package:flutter/material.dart' hide Route;

import 'dart:math';

class RangesPanel extends StatefulWidget {
  final Landmark landmark;
  final GemMapController mapController;
  final VoidCallback onCancelTap;
  const RangesPanel(
      {super.key,
      required this.landmark,
      required this.onCancelTap,
      required this.mapController});

  @override
  State<RangesPanel> createState() => _RangesPanelState();
}

class _RangesPanelState extends State<RangesPanel> {
  int _rangeValue = 3600;
  RouteTransportMode _transportMode = RouteTransportMode.car;

  RouteType _routeType = RouteType.fastest;
  bool _avoidMotorways = false;
  bool _avoidTollRoads = false;
  bool _avoidFerries = false;
  bool _avoidUnpavedRoads = false;

  BikeProfile _bikeProfile = BikeProfile.city;
  double _hillsValue = 0;

  TrafficAvoidance _trafficAvoidance = TrafficAvoidance.roadblocks;

  List<Range> routeRanges = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height / 2,
      width: MediaQuery.of(context).size.width,
      color: Colors.grey.shade100,
      child: Scrollbar(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 50,
                  child: Row(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: routeRanges.length,
                          itemBuilder: (BuildContext context, int index) =>
                              RouteRangeChip(
                            range: routeRanges[index],
                            onDelete: () => _deleteRouteRange(index),
                            onTap: () => _toggleRouteRange(index),
                          ),
                          separatorBuilder: (BuildContext context, int index) =>
                              const SizedBox(
                            width: 10,
                          ),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: widget.onCancelTap,
                        icon: const Icon(
                          Icons.cancel,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Range Value',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                _onAddRouteRangeButtonPressed(context),
                            icon: const Icon(Icons.add),
                          )
                        ],
                      ),
                      RangeValueSlider(
                        value: _rangeValue.toDouble(),
                        type: _routeType,
                        onChanged: (value) {
                          setState(() {
                            _rangeValue = value.toInt();
                          });
                        },
                      ),
                      DropMenuItem(
                        title: 'Transport mode',
                        selection: _transportMode,
                        onSelected: (RouteTransportMode value) => {
                          setState(() {
                            _transportMode = value;
                            _routeType = RouteType.fastest;
                            _rangeValue = 3600;
                          })
                        },
                        values: RouteTransportMode.values.sublist(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      if (_transportMode != RouteTransportMode.pedestrian)
                        DropMenuItem(
                          title: 'Route Type',
                          selection: _routeType,
                          onSelected: (RouteType value) => {
                            setState(() {
                              _routeType = value;
                              switch (value) {
                                case RouteType.fastest:
                                  _rangeValue = 3600;
                                case RouteType.shortest:
                                  _rangeValue = 1000;
                                case RouteType.economic:
                                  _rangeValue = 1000;
                              }
                            })
                          },
                          values: [
                            RouteType.fastest,
                            if (_transportMode != RouteTransportMode.bicycle)
                              RouteType.shortest,
                            if (_transportMode == RouteTransportMode.bicycle)
                              RouteType.economic
                          ],
                        ),
                      if (_transportMode == RouteTransportMode.bicycle)
                        DropMenuItem(
                          title: 'Bike type',
                          selection: _bikeProfile,
                          onSelected: (BikeProfile value) => {
                            setState(() {
                              _bikeProfile = value;
                            })
                          },
                          values: BikeProfile.values,
                        ),
                      if (_transportMode == RouteTransportMode.lorry)
                        DropMenuItem(
                          title: 'Avoid Traffic',
                          selection: _trafficAvoidance,
                          onSelected: (TrafficAvoidance value) => {
                            setState(() {
                              _trafficAvoidance = value;
                            })
                          },
                          values: TrafficAvoidance.values,
                        ),
                      if (_transportMode == RouteTransportMode.car ||
                          _transportMode == RouteTransportMode.lorry)
                        SwitchItem(
                          title: 'Avoid Motorways',
                          value: _avoidMotorways,
                          onChanged: (value) {
                            setState(() {
                              _avoidMotorways = value;
                            });
                          },
                        ),
                      if (_transportMode == RouteTransportMode.car ||
                          _transportMode == RouteTransportMode.lorry)
                        SwitchItem(
                          title: 'Avoid Toll Roads',
                          value: _avoidTollRoads,
                          onChanged: (value) {
                            setState(() {
                              _avoidTollRoads = value;
                            });
                          },
                        ),
                      SwitchItem(
                        title: 'Avoid Ferries',
                        value: _avoidFerries,
                        onChanged: (value) {
                          setState(() {
                            _avoidFerries = value;
                          });
                        },
                      ),
                      SwitchItem(
                        title: 'Avoid Unpaved Roads',
                        value: _avoidUnpavedRoads,
                        onChanged: (value) {
                          setState(() {
                            _avoidUnpavedRoads = value;
                          });
                        },
                      ),
                      if (_transportMode == RouteTransportMode.bicycle)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Hills', style: TextStyle(fontSize: 18)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('0'),
                                  Text(_hillsValue.toString()),
                                  const Text('10')
                                ],
                              ),
                            ),
                            Slider(
                                value: _hillsValue,
                                divisions: 10,
                                min: 0,
                                max: 10,
                                onChanged: (value) {
                                  setState(() {
                                    _hillsValue = value;
                                  });
                                }),
                          ],
                        ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteRouteRange(int index) {
    // Remove the route range from map.
    widget.mapController.preferences.routes.remove(routeRanges[index].route);
    setState(() {
      routeRanges.removeAt(index);
    });
  }

  void _toggleRouteRange(int index) {
    if (routeRanges[index].isEnabled) {
      // If the route range is enabled, remove it from map.
      widget.mapController.preferences.routes.remove(routeRanges[index].route);
      return;
    } else {
      // If the route range is disabled, display it on map and center on it.
      RouteRenderSettings settings =
          RouteRenderSettings(fillColor: routeRanges[index].color);
      widget.mapController.preferences.routes
          .add(routeRanges[index].route, true, routeRenderSettings: settings);
      _centerOnRouteRange(routeRanges[index].route);
    }
  }

  RoutePreferences _getRoutePreferences() {
    // Get the preferences based on the selected transport mode.
    switch (_transportMode) {
      case RouteTransportMode.car:
        return RoutePreferences(
          avoidMotorways: _avoidMotorways,
          avoidTollRoads: _avoidTollRoads,
          avoidFerries: _avoidFerries,
          avoidUnpavedRoads: _avoidUnpavedRoads,
          transportMode: _transportMode,
          routeType: _routeType,
          routeRanges: [_rangeValue],
        );
      case RouteTransportMode.lorry:
        return RoutePreferences(
          avoidMotorways: _avoidMotorways,
          avoidTollRoads: _avoidTollRoads,
          avoidFerries: _avoidFerries,
          avoidUnpavedRoads: _avoidUnpavedRoads,
          transportMode: _transportMode,
          routeType: _routeType,
          routeRanges: [_rangeValue],
          avoidTraffic: _trafficAvoidance,
        );
      case RouteTransportMode.pedestrian:
        return RoutePreferences(
          avoidFerries: _avoidFerries,
          avoidUnpavedRoads: _avoidUnpavedRoads,
          transportMode: _transportMode,
          routeRanges: [_rangeValue],
        );
      case RouteTransportMode.bicycle:
        return RoutePreferences(
          avoidFerries: _avoidFerries,
          avoidUnpavedRoads: _avoidUnpavedRoads,
          transportMode: _transportMode,
          routeType: _routeType,
          routeRanges: [_rangeValue],
          avoidBikingHillFactor: _hillsValue,
          bikeProfile: BikeProfileElectricBikeProfile(
              profile: _bikeProfile, eProfile: ElectricBikeProfile()),
        );
      default:
        return RoutePreferences();
    }
  }

  void _onAddRouteRangeButtonPressed(BuildContext context) {
    if (!_doesRouteRangeExist()) {
      _showSnackBar(context, message: "The route is being calculated.");

      // Calling the calculateRoute SDK method.
      // (err, results) - is a callback function that gets called when the route computing is finished.
      // err is an error enum, results is a list of routes.
      RoutingService.calculateRoute([widget.landmark], _getRoutePreferences(),
          (err, routes) {
        ScaffoldMessenger.of(context).clearSnackBars();

        // If there aren't any errors, we display the range.
        if (err == GemError.success) {
          // Get the routes collection from map preferences.
          final routesMap = widget.mapController.preferences.routes;

          // Color the range in a random color.
          final randomColor = Color.fromARGB(128, Random().nextInt(200),
              Random().nextInt(200), Random().nextInt(200));
          RouteRenderSettings settings =
              RouteRenderSettings(fillColor: randomColor);

          // Display the range on map.
          routesMap.add(routes.first, true, routeRenderSettings: settings);

          // Center the camera on range.
          _centerOnRouteRange(routes.first);

          setState(() {
            _addNewRouteRange(routes.first, randomColor);
          });
        }
      });

      setState(() {});
    }
  }

  String _getRouteRangeValueString() {
    final String valueString = (_routeType == RouteType.fastest)
        ? convertDuration(_rangeValue)
        : (_routeType == RouteType.economic)
            ? convertWh(_rangeValue)
            : convertDistance(_rangeValue);
    return valueString;
  }

  bool _doesRouteRangeExist() {
    bool exists = routeRanges.any((range) =>
        range.transportMode == _transportMode &&
        range.value == _getRouteRangeValueString());
    return exists;
  }

  void _addNewRouteRange(Route route, Color color) {
    Range newRange = Range(
      route: route,
      color: color,
      transportMode: _transportMode,
      value: _getRouteRangeValueString(),
      isEnabled: true,
    );
    routeRanges.add(newRange);
  }

  void _centerOnRouteRange(Route route) {
    const appbarHeight = 50;
    const padding = 20;

    // Use the map controller to center on route above the panel.
    widget.mapController.centerOnRoute(route,
        screenRect: RectType(
          x: 0,
          y: (appbarHeight + padding * MediaQuery.of(context).devicePixelRatio)
              .toInt(),
          width: (MediaQuery.of(context).size.width *
                  MediaQuery.of(context).devicePixelRatio)
              .toInt(),
          height: ((MediaQuery.of(context).size.height / 2 -
                      appbarHeight -
                      2 * padding * MediaQuery.of(context).devicePixelRatio) *
                  MediaQuery.of(context).devicePixelRatio)
              .toInt(),
        ));
  }

  // Show a snackbar indicating that the route calculation is in progress.
  void _showSnackBar(BuildContext context,
      {required String message, Duration duration = const Duration(hours: 1)}) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: duration,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

class DropMenuItem<T> extends StatelessWidget {
  final String title;
  final Function onSelected;
  final T selection;
  final List<T> values;
  const DropMenuItem(
      {super.key,
      required this.onSelected,
      required this.selection,
      required this.values,
      required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title),
          DropdownButton<T>(
            value: selection,
            items: [
              for (final value in values)
                DropdownMenuItem(
                    value: value, child: Text((value as Enum).name))
            ],
            onChanged: (mode) => onSelected(mode),
          ),
        ],
      ),
    );
  }
}

class SwitchItem extends StatelessWidget {
  final String title;
  final bool value;
  final void Function(bool) onChanged;
  const SwitchItem(
      {super.key,
      required this.value,
      required this.onChanged,
      required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class RangeValueSlider extends StatelessWidget {
  final RouteType type;
  final double value;
  late final double minValue;
  late final double maxValue;
  late final int divisions;
  final void Function(double) onChanged;
  late final String Function(int) valueToString;

  RangeValueSlider(
      {super.key,
      required this.value,
      required this.onChanged,
      required this.type}) {
    switch (type) {
      case RouteType.fastest:
        minValue = 60;
        maxValue = 10800;
        divisions = 179;
        valueToString = convertDuration;
      case RouteType.shortest:
        minValue = 100;
        maxValue = 200000;
        divisions = 500;
        valueToString = convertDistance;
      case RouteType.economic:
        minValue = 10;
        maxValue = 2000;
        divisions = 199;
        valueToString = convertWh;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(valueToString(minValue.toInt())),
            Text(valueToString(value.toInt())),
            Text(valueToString(maxValue.toInt()))
          ],
        ),
        Slider(
          value: value,
          onChanged: onChanged,
          min: minValue,
          max: maxValue,
          divisions: divisions,
        ),
      ],
    );
  }
}

class RouteRangeChip extends StatefulWidget {
  final Range range;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const RouteRangeChip(
      {super.key,
      required this.range,
      required this.onDelete,
      required this.onTap});

  @override
  State<RouteRangeChip> createState() => _RouteRangeChipState();
}

class _RouteRangeChipState extends State<RouteRangeChip> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        widget.onTap();
        setState(() {
          widget.range.isEnabled = !widget.range.isEnabled;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          border: Border.all(
            width: 3,
            color: widget.range.isEnabled ? widget.range.color : Colors.grey,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _transportMeansIcon(widget.range.transportMode),
            ),
            Text(widget.range.value),
            InkWell(
              onTap: widget.onDelete,
              child: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }

  IconData _transportMeansIcon(RouteTransportMode transportMode) {
    switch (transportMode) {
      case RouteTransportMode.bicycle:
        return Icons.directions_bike;
      case RouteTransportMode.car:
        return Icons.directions_car;
      case RouteTransportMode.pedestrian:
        return Icons.directions_walk;
      case RouteTransportMode.lorry:
        return Icons.local_shipping;
      default:
        throw Exception("Unknown transport means");
    }
  }
}
