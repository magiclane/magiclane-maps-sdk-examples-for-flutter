import 'dart:async';
import 'dart:typed_data';
import 'package:human_voices/utility.dart';
import 'package:gem_kit/api/gem_navigationinstruction.dart';

class InstructionModel {
  final String nextTurnDistance;
  final String eta;
  final String streetName;
  final String nextStreetName;
  final Uint8List? nextTurnImageData;
  final String remainingDistance;
  final String remainingDuration;

  InstructionModel(
      {required this.nextTurnDistance,
      required this.eta,
      required this.streetName,
      required this.nextStreetName,
      required this.nextTurnImageData,
      required this.remainingDistance,
      required this.remainingDuration});

  static Future<InstructionModel> fromGemInstruction(
      NavigationInstruction ins) async {
    final timeDistance = await ins.getTimeDistanceToNextTurn();
    final rawDistance =
        timeDistance.restrictedDistanceM + timeDistance.unrestrictedDistanceM;

    final formattedDistance = convertDistance(rawDistance);

    final currentStreetName = await ins.getCurrentStreetName();
    final nextStreetname = await ins.getNextStreetName();

    final nextTurnDetails = await ins.getNextTurnDetails();
    final imageData = await nextTurnDetails.getAbstractGeometryImage(100, 100);
    final decodedImage = await decodeImageData(imageData);

    final remainingTimeDistance = await ins.getRemainingTravelTimeDistance();
    final rawRemainingTime = remainingTimeDistance.restrictedTimeS +
        remainingTimeDistance.unrestrictedTimeS;
    final rawRemainingDist = remainingTimeDistance.restrictedDistanceM +
        remainingTimeDistance.unrestrictedDistanceM;

    final formattedEta = getCurrentTime(additionalSeconds: rawRemainingTime);
    final formattedRemainingDuration = convertDuration(rawRemainingTime);
    final formattedRemainingDistance = convertDistance(rawRemainingDist);

    return InstructionModel(
      nextTurnDistance: formattedDistance,
      eta: formattedEta,
      nextTurnImageData: decodedImage,
      remainingDistance: formattedRemainingDistance,
      remainingDuration: formattedRemainingDuration,
      streetName: currentStreetName,
      nextStreetName: nextStreetname,
    );
  }
}
