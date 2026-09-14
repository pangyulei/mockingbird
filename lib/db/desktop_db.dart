import '../objectbox.g.dart';
import '../tool/extensions.dart';
import 'entities/desktop_metadata.dart';

class DesktopDB {
  static late final Store _store;
  static Future<void> init() async {
    _store = await initDB();
  }

  static Future<DesktopMetadata> loadMetadata() async {
    return (await _store.box<DesktopMetadata>().getAllAsync()).firstOrNull ??
        DesktopMetadata();
  }

  static Future<void> updateMetadata(DesktopMetadata metadata) async {
    await _store.box<DesktopMetadata>().putAsync(metadata);
  }
}