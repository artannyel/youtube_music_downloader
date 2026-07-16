import '../entities/media_metadata.dart';

abstract class DownloadSetupRepository {
  Future<MediaMetadata> fetchMetadata(String url);
}
