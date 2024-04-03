import 'package:gem_kit/api/gem_contentstore.dart';
import 'package:gem_kit/api/gem_contenttypes.dart';
import 'package:gem_kit/api/gem_contentupdate.dart';
import 'package:gem_kit/api/gem_offboardlistener.dart';
import 'package:gem_kit/core.dart';
import 'package:map_update/main.dart';

// Singleton class for persisting update related state and logic between instances of MapsPage
class UpdatePersistence {
  ContentUpdater? _contentUpdater;
  bool _isOldData = false;
  ProgressListener? _updateProgressListener;

  void Function(int?)? onProgress;
  void Function(int)? onStatusChanged;

  static final UpdatePersistence instance = UpdatePersistence._internal();

  UpdatePersistence._internal() {
    offBoardListener!.registerOnWorldwideRoadMapSupportStatus((status) {
      print("UpdatePersistence: onWorldwideRoadMapSupportStatus ${status}");
      if (status != EStatus.UpToDate) {
        _isOldData = true;
      }
    });
  }

  bool get isOldData => _isOldData;

  int checkForUpdate() {
    //The user will be notified via registerOnWorldwideRoadMapSupportStatus
    final code = ContentStore.checkForUpdate(EContentType.CT_RoadMap);
    print("UpdatePersistence: checkForUpdate resolved with code ${code}");
    return code;
  }

  int update() {
    _contentUpdater = ContentStore.createContentUpdater(EContentType.CT_RoadMap);
    _updateProgressListener = ProgressListener.create();

    _updateProgressListener!.registerOnProgressCallback((value) => onProgress?.call(value));
    _updateProgressListener!.registerOnNotifyStatusChanged((statusCode) {
      print("UpdatePersistence: onNotifyStatusChanged with code ${statusCode}");
      if (statusCode == EContentUpdaterStatus.FullyReady.id || statusCode == EContentUpdaterStatus.PartiallyReady.id) {
        _isOldData = false;

        int code = _contentUpdater!.apply();
        print("UpdatePersistence: apply resolved with code ${code}");
      }

      onProgress?.call(null);
      onStatusChanged?.call(statusCode);
    });

    final statusId = _contentUpdater!.update(true, _updateProgressListener!);
    print("UpdatePersistence: update resolved with code ${statusId}");
    return statusId;
  }

  void cancel() {
    _contentUpdater!.cancel();

    onProgress?.call(null);
  }
}
