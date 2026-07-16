import 'package:isar/isar.dart';

part 'download_task.g.dart';

@collection
class DownloadTask {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String youtubeId;
  
  late String title;
  late String url;
  
  @Enumerated(EnumType.name)
  late DownloadType type; // video ou audio
  
  late String requestedQuality;
  late String actualQuality;
  late String targetPath;
  
  late double progress; // 0.0 a 100.0
  late String downloadSpeed;
  late String eta;
  
  @Enumerated(EnumType.name)
  late DownloadStatus status; // pending, downloading, completed, failed, paused
  
  String? errorMessage;
  late DateTime createdAt;
}

enum DownloadType { video, audio }
enum DownloadStatus { pending, downloading, completed, failed, paused }
