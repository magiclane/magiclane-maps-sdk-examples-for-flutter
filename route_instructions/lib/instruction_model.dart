import 'dart:async';
import 'dart:typed_data';

import 'package:gem_kit/api/gem_routingservice.dart';
import 'package:route_instructions/utility.dart';

class RouteInstructionModel {
  final String distanceUntilInstruction;

  final String followingRoadinstruction;

  final String instruction;

  Uint8List? imageData;

  RouteInstructionModel(
      {required this.distanceUntilInstruction,
      required this.followingRoadinstruction,
      required this.instruction,
      required this.imageData});

  static Future<RouteInstructionModel> fromGemRouteInstruction(
      RouteInstruction ins) async {
    final nextTurnDetails = await ins.getTurnDetails();
    final imageData = nextTurnDetails.getAbstractGeometryImage(100, 100);
    final decodedImage =
        await decodeImageData(data: imageData, width: 100, height: 100);

    final timeDistance = await ins.getTraveledTimeDistance();
    final rawDistance =
        timeDistance.restrictedDistanceM + timeDistance.unrestrictedDistanceM;
    final formattedDistance = convertDistance(rawDistance);

    final followingRoadInstruction = await ins.getFollowRoadInstruction();

    final instruction = ins.getTurnInstruction();

    return RouteInstructionModel(
        distanceUntilInstruction: formattedDistance,
        followingRoadinstruction: followingRoadInstruction,
        instruction: instruction,
        imageData: decodedImage);
  }
}
