import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/downloads_history/data/models/download_task.dart';

class IsarService {
  static Isar? _instance;

  static Isar get instance {
    if (_instance == null) {
      throw StateError('IsarService não foi inicializado. Chame initialize() no main.dart.');
    }
    return _instance!;
  }

  static Future<void> initialize() async {
    if (_instance != null) return;
    
    final dir = await getApplicationDocumentsDirectory();
    _instance = await Isar.open(
      [DownloadTaskSchema],
      directory: dir.path,
    );
  }
}
