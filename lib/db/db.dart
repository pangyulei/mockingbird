import 'package:collection/collection.dart';
import 'package:mockingbird/db/entities/mobile_media_history.dart';
import 'package:mockingbird/db/entities/mobile_metadata.dart';
import 'package:mockingbird/db/entities/preference.dart';
import 'package:mockingbird/objectbox.g.dart';
import '../tool/extensions.dart';

class DB {
  static late final Store _store;
  static Future<void> init() async {
    _store = await initDB();
  }

  static Future<MobileMetadata> loadMobileMetadata() async {
    return (await _store.box<MobileMetadata>().getAllAsync()).firstOrNull ??
        MobileMetadata();
  }

  static Future<MobileMediaHistory> updateMobileHistory(MobileMediaHistory progress) async {
    return await _store.box<MobileMediaHistory>().putAndGetAsync(progress);
  }

  static Future<MobileMetadata> updateMobileMetadata(MobileMetadata metadata) async {
    return await _store.box<MobileMetadata>().putAndGetAsync(metadata);
  }


  static Future<Preference?> loadPreference() async {
    return (await _store.box<Preference>().getAllAsync()).firstOrNull;
  }
  
  static Future<Preference> updatePreference(
    Preference preference,
  ) async {
    return await _store.box<Preference>().putAndGetAsync(preference);
  }

}