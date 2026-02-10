// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'dart:math';

import 'package:flutter/material.dart' hide Animation, Route;
import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';

class FollowPositionInfo {
  FollowPositionInfo({
    required this.cameraFocus,
    required this.perspective,
    required this.timeBeforeTurnPresentation,
    required this.touchHandlerExitAllow,
    required this.touchHandlerModifyPersistent,
    required this.touchHandlerModifyHorizontalAngleLimits,
    required this.touchHandlerModifyVerticalAngleLimits,
    required this.touchHandlerModifyDistanceLimits,
    required this.viewAngle,
    required this.zoomLevel,
    required this.accuracyCircleVisibility,
    required this.isTrackObjectFollowingMapRotation,
    required this.mapRotationMode,
    required this.mapRotationAngle,
    required this.isFollowingPosition,
    required this.isFollowingPositionTouchHandlerModified,
    required this.isDefaultFollowingPosition,
    required this.isCameraMoving,
    required this.accuracyCircleColor,
    required this.positionTrackerScale,
  });

  final Point<double> cameraFocus;
  final MapViewPerspective perspective;
  final int timeBeforeTurnPresentation;
  final bool touchHandlerExitAllow;
  final bool touchHandlerModifyPersistent;
  final (double, double) touchHandlerModifyHorizontalAngleLimits;
  final (double, double) touchHandlerModifyVerticalAngleLimits;
  final (double, double) touchHandlerModifyDistanceLimits;
  final double viewAngle;
  final int zoomLevel;
  final bool accuracyCircleVisibility;
  final bool isTrackObjectFollowingMapRotation;
  final FollowPositionMapRotationMode mapRotationMode;
  final double mapRotationAngle;
  final bool isFollowingPosition;
  final bool isFollowingPositionTouchHandlerModified;
  final bool isDefaultFollowingPosition;
  final bool isCameraMoving;
  final Color accuracyCircleColor;
  final double positionTrackerScale;

  static FollowPositionInfo empty() {
    return FollowPositionInfo(
      cameraFocus: const Point<double>(0.5, 0.5),
      perspective: MapViewPerspective.twoDimensional,
      timeBeforeTurnPresentation: -1,
      touchHandlerExitAllow: true,
      touchHandlerModifyPersistent: false,
      touchHandlerModifyHorizontalAngleLimits: (0, 0),
      touchHandlerModifyVerticalAngleLimits: (0, 0),
      touchHandlerModifyDistanceLimits: (50, 100),
      viewAngle: 0,
      zoomLevel: -1,
      accuracyCircleVisibility: false,
      isTrackObjectFollowingMapRotation: true,
      mapRotationMode: FollowPositionMapRotationMode.positionHeading,
      mapRotationAngle: 0,
      isFollowingPosition: false,
      isFollowingPositionTouchHandlerModified: false,
      isDefaultFollowingPosition: false,
      isCameraMoving: false,
      accuracyCircleColor: Colors.blue,
      positionTrackerScale: 1,
    );
  }
}

class FollowPositionController extends ChangeNotifier {
  GemMapController? _mapController;
  FollowPositionInfo _info = FollowPositionInfo.empty();

  FollowPositionInfo get info => _info;

  double cameraFocusX = 0.5;
  double cameraFocusY = 0.5;
  MapViewPerspective perspective = MapViewPerspective.twoDimensional;
  bool animatePerspective = true;
  double viewAngle = 45;
  bool animateViewAngle = true;
  bool autoZoom = false;
  int zoomLevel = 50;
  int zoomDuration = 0;

  FollowPositionMapRotationMode mapRotationMode =
      FollowPositionMapRotationMode.positionHeading;
  double mapAngle = 0;
  bool objectFollowMap = true;

  bool touchHandlerExitAllow = true;
  bool touchHandlerModifyPersistent = false;
  RangeValues horizontalAngleLimits = const RangeValues(0, 0);
  RangeValues verticalAngleLimits = const RangeValues(0, 0);
  RangeValues distanceLimits = const RangeValues(50, 200);
  bool distanceMaxUnlimited = true;

  bool useDefaultTurnPresentationTime = true;
  double turnPresentationSeconds = 5;

  bool useDefaultStartFollowPosition = true;
  int startZoomLevel = 40;
  double startViewAngle = 45;

  double positionTrackerScale = 1;

  void updateValues(VoidCallback updates) {
    updates();
    notifyListeners();
  }

  void attachMapController(GemMapController controller) {
    _mapController = controller;
    notifyListeners();
  }

  Future<void> refreshInfo() async {
    if (_mapController == null) {
      _info = FollowPositionInfo.empty();
      notifyListeners();
      return;
    }

    final prefs = _mapController!.preferences.followPositionPreferences;
    final (rotationMode, rotationAngle) = prefs.mapRotationMode;

    final MapSceneObject tracker = MapSceneObject.getDefPositionTracker();

    debugPrint(
      '[FollowPositionController] calling all getters to refresh info',
    );
    _info = FollowPositionInfo(
      cameraFocus: prefs.cameraFocus,
      perspective: prefs.perspective,
      timeBeforeTurnPresentation: prefs.timeBeforeTurnPresentation,
      touchHandlerExitAllow: prefs.touchHandlerExitAllow,
      touchHandlerModifyPersistent: prefs.touchHandlerModifyPersistent,
      touchHandlerModifyHorizontalAngleLimits:
          prefs.touchHandlerModifyHorizontalAngleLimits,
      touchHandlerModifyVerticalAngleLimits:
          prefs.touchHandlerModifyVerticalAngleLimits,
      touchHandlerModifyDistanceLimits: prefs.touchHandlerModifyDistanceLimits,
      viewAngle: prefs.viewAngle,
      zoomLevel: prefs.zoomLevel,
      accuracyCircleVisibility: prefs.accuracyCircleVisibility,
      isTrackObjectFollowingMapRotation:
          prefs.isTrackObjectFollowingMapRotation,
      mapRotationMode: rotationMode,
      mapRotationAngle: rotationAngle,
      isFollowingPosition: _mapController!.isFollowingPosition,
      isFollowingPositionTouchHandlerModified:
          _mapController!.isFollowingPositionTouchHandlerModified,
      isDefaultFollowingPosition: _mapController!.isDefaultFollowingPosition,
      isCameraMoving: _mapController!.isCameraMoving,
      accuracyCircleColor: MapSceneObject.defPositionTrackerAccuracyCircleColor,
      positionTrackerScale: tracker.scale,
    );

    notifyListeners();
  }

  Future<void> startFollowingPosition() async {
    if (_mapController == null) {
      return;
    }

    final animation = GemAnimation(type: AnimationType.linear);
    final zoomLevel = useDefaultStartFollowPosition ? -1 : startZoomLevel;
    final viewAngle = useDefaultStartFollowPosition ? null : startViewAngle;

    debugPrint(
      '[FollowPositionController] startFollowingPosition with zoomLevel=$zoomLevel and viewAngle=$viewAngle animation: type=${animation.type} duration=${animation.duration}',
    );
    _mapController!.startFollowingPosition(
      animation: animation,
      zoomLevel: zoomLevel,
      viewAngle: viewAngle,
    );

    await refreshInfo();
  }

  void stopFollowingPosition({bool restoreCameraMode = false}) {
    if (_mapController == null) {
      return;
    }

    debugPrint('[FollowPositionController] stopFollowingPosition');
    _mapController!.stopFollowingPosition(restoreCameraMode: restoreCameraMode);
    refreshInfo();
  }

  void restoreFollowingPosition() {
    if (_mapController == null) {
      return;
    }

    debugPrint('[FollowPositionController] restoreFollowingPosition');
    _mapController!.restoreFollowingPosition(
      animation: GemAnimation(type: AnimationType.linear, duration: 600),
    );
    refreshInfo();
  }

  void applyCameraFocus() {
    if (_mapController == null) {
      return;
    }

    final prefs = _mapController!.preferences.followPositionPreferences;
    debugPrint(
      '[FollowPositionController] applyCameraFocus: cameraFocus=(${cameraFocusX.toStringAsFixed(3)}, ${cameraFocusY.toStringAsFixed(3)})',
    );
    prefs.setCameraFocus(Point<double>(cameraFocusX, cameraFocusY));
    refreshInfo();
  }

  void applyPerspective() {
    if (_mapController == null) {
      return;
    }

    final prefs = _mapController!.preferences.followPositionPreferences;
    final animation = animatePerspective
        ? GemAnimation(type: AnimationType.linear, duration: 350)
        : null;
    debugPrint(
      '[FollowPositionController] applyPerspective: perspective=$perspective animate=$animatePerspective animationDuration=${animation?.duration}',
    );
    prefs.setPerspective(perspective, animation: animation);
    refreshInfo();
  }

  void applyViewAngle() {
    if (_mapController == null) {
      return;
    }

    final prefs = _mapController!.preferences.followPositionPreferences;
    debugPrint(
      '[FollowPositionController] applyViewAngle: viewAngle=$viewAngle animate=$animateViewAngle',
    );
    prefs.setViewAngle(viewAngle, animated: animateViewAngle);
    refreshInfo();
  }

  void applyZoomLevel() {
    if (_mapController == null) {
      return;
    }

    final prefs = _mapController!.preferences.followPositionPreferences;
    debugPrint(
      '[FollowPositionController] applyZoomLevel: zoomLevel=${autoZoom ? -1 : zoomLevel} autoZoom=$autoZoom duration=$zoomDuration',
    );
    prefs.setZoomLevel(autoZoom ? -1 : zoomLevel, duration: zoomDuration);
    refreshInfo();
  }

  void applyMapRotationMode() {
    if (_mapController == null) {
      return;
    }

    final prefs = _mapController!.preferences.followPositionPreferences;
    debugPrint(
      '[FollowPositionController] applyMapRotationMode: mapRotationMode=$mapRotationMode mapAngle=$mapAngle objectFollowMap=$objectFollowMap',
    );
    prefs.setMapRotationMode(
      mapRotationMode,
      mapAngle: mapAngle,
      objectFollowMap: objectFollowMap,
    );
    refreshInfo();
  }

  void applyTurnPresentationTime() {
    if (_mapController == null) {
      return;
    }

    final prefs = _mapController!.preferences.followPositionPreferences;
    final value = useDefaultTurnPresentationTime
        ? -1
        : turnPresentationSeconds.round();
    debugPrint(
      '[FollowPositionController] applyTurnPresentationTime: value=$value useDefault=$useDefaultTurnPresentationTime',
    );
    prefs.timeBeforeTurnPresentation = value;
    refreshInfo();
  }

  void applyTouchHandlerExitAllow() {
    if (_mapController == null) {
      return;
    }

    final prefs = _mapController!.preferences.followPositionPreferences;
    debugPrint(
      '[FollowPositionController] applyTouchHandlerExitAllow: touchHandlerExitAllow=$touchHandlerExitAllow',
    );
    prefs.touchHandlerExitAllow = touchHandlerExitAllow;
    refreshInfo();
  }

  void applyTouchHandlerModifyPersistent() {
    if (_mapController == null) {
      return;
    }

    final prefs = _mapController!.preferences.followPositionPreferences;
    debugPrint(
      '[FollowPositionController] applyTouchHandlerModifyPersistent: touchHandlerModifyPersistent=$touchHandlerModifyPersistent',
    );
    prefs.touchHandlerModifyPersistent = touchHandlerModifyPersistent;
    refreshInfo();
  }

  void applyHorizontalAngleLimits() {
    if (_mapController == null) {
      return;
    }

    final prefs = _mapController!.preferences.followPositionPreferences;
    debugPrint(
      '[FollowPositionController] applyHorizontalAngleLimits: start=${horizontalAngleLimits.start} end=${horizontalAngleLimits.end}',
    );
    prefs.touchHandlerModifyHorizontalAngleLimits = (
      horizontalAngleLimits.start,
      horizontalAngleLimits.end,
    );
    refreshInfo();
  }

  void applyVerticalAngleLimits() {
    if (_mapController == null) {
      return;
    }

    final prefs = _mapController!.preferences.followPositionPreferences;
    debugPrint(
      '[FollowPositionController] applyVerticalAngleLimits: start=${verticalAngleLimits.start} end=${verticalAngleLimits.end}',
    );
    prefs.touchHandlerModifyVerticalAngleLimits = (
      verticalAngleLimits.start,
      verticalAngleLimits.end,
    );
    refreshInfo();
  }

  void applyDistanceLimits() {
    if (_mapController == null) {
      return;
    }

    final prefs = _mapController!.preferences.followPositionPreferences;
    final maxDistance = distanceLimits.end;
    debugPrint(
      '[FollowPositionController] applyDistanceLimits: start=${distanceLimits.start} end=$maxDistance distanceMaxUnlimited=$distanceMaxUnlimited',
    );
    prefs.touchHandlerModifyDistanceLimits = (
      distanceLimits.start,
      maxDistance,
    );
    refreshInfo();
  }

  void applyPositionTrackerScale() {
    final tracker = MapSceneObject.getDefPositionTracker();
    tracker.scale = positionTrackerScale;
    refreshInfo();
  }
}
