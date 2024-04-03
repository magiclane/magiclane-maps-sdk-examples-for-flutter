import 'dart:async';
import 'dart:ui';

import 'package:gem_kit/api/gem_routingservice.dart';
import 'package:route_instructions/utility.dart';

class RouteInstructionModel {
  final String distanceUntilInstruction;

  final String followingRoadinstruction;

  final String instruction;

  Image? imageData;

  RouteInstructionModel(
      {required this.distanceUntilInstruction,
      required this.followingRoadinstruction,
      required this.instruction,
      required this.imageData});

  static Future<RouteInstructionModel> fromGemRouteInstruction(RouteInstruction ins) async {
    final nextTurnDetails = ins.getTurnDetails();
    final imageData = await nextTurnDetails.getAbstractGeometryImage(100, 100);

    final timeDistance = ins.getTraveledTimeDistance();
    final rawDistance = timeDistance.restrictedDistanceM + timeDistance.unrestrictedDistanceM;
    final formattedDistance = convertDistance(rawDistance);

    final followingRoadInstruction = ins.getFollowRoadInstruction();

    final instruction = ins.getTurnInstruction();

    return RouteInstructionModel(
        distanceUntilInstruction: formattedDistance,
        followingRoadinstruction: followingRoadInstruction,
        instruction: instruction,
        imageData: imageData);
  }
}
