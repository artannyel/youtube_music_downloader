import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Custom playlist helper that bypasses the youtube_explode_dart internal
/// parsers to support YouTube's new [lockupViewModel] playlist layout which
/// the library (as of v3.1.0) does not yet handle, returning 0 items.
///
/// Uses the InnerTube [browse] endpoint directly via [dart:io].
class CustomPlaylistHelper {
  static const _browseUrl =
      'https://www.youtube.com/youtubei/v1/browse?prettyPrint=false';

  // ── HTTP helpers ────────────────────────────────────────────────────────────

  static Future<String> _getString(String url) async {
    final client = HttpClient();
    client.userAgent =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36';
    try {
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9');
      final res = await req.close();
      return await res.transform(utf8.decoder).join();
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> _postBrowse(
    Map<String, dynamic> body, {
    String? visitorData,
  }) async {
    final client = HttpClient();
    client.userAgent =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36';
    try {
      final req = await client.postUrl(Uri.parse(_browseUrl));
      req.headers.contentType = ContentType.json;
      req.headers.set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9');
      req.headers.set('x-youtube-client-name', '1');
      req.headers.set('x-youtube-client-version', '2.20240726.00.00');
      if (visitorData != null && visitorData.isNotEmpty) {
        req.headers.set('x-goog-visitor-id', visitorData);
      }
      req.write(jsonEncode(body));
      final res = await req.close();
      final raw = await res.transform(utf8.decoder).join();
      return jsonDecode(raw) as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }

  // ── Visitor data extraction from HTML ───────────────────────────────────────

  static String _extractVisitorData(String html) {
    final patterns = [
      RegExp(r'"visitorData"\s*:\s*"([^"]+)"'),
      RegExp(r'"VISITOR_DATA"\s*:\s*"([^"]+)"'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null) return match.group(1) ?? '';
    }
    return '';
  }

  // ── JSON tree traversal helpers ─────────────────────────────────────────────

  static List<dynamic>? _findVideoItems(Map<String, dynamic> root) {
    // Continuation response
    final actions = root['onResponseReceivedActions'] ??
        root['onResponseReceivedCommands'];
    if (actions is List) {
      for (final action in actions) {
        if (action is Map) {
          final items =
              action['appendContinuationItemsAction']?['continuationItems'] ??
                  action['reloadContinuationItemsCommand']?['continuationItems'];
          if (items is List) return items;
        }
      }
    }

    // Initial page response
    final contents = root['contents'];
    if (contents is Map) {
      final twoColumn = contents['twoColumnBrowseResultsRenderer'];
      if (twoColumn is Map) {
        final tabs = twoColumn['tabs'];
        if (tabs is List) {
          for (final tab in tabs) {
            final content = tab?['tabRenderer']?['content'];
            if (content is! Map) continue;
            final sectionList = content['sectionListRenderer'];
            if (sectionList is! Map) continue;
            final sections = sectionList['contents'];
            if (sections is! List) continue;
            for (final section in sections) {
              final itemSection = section?['itemSectionRenderer'];
              if (itemSection is! Map) continue;
              final itemContents = itemSection['contents'];
              if (itemContents is! List) continue;
              // New lockupViewModel layout
              if (itemContents.any(
                (e) => e is Map && e.containsKey('lockupViewModel'),
              )) {
                return itemContents;
              }
              // Classic playlistVideoListRenderer layout
              for (final item in itemContents) {
                if (item is! Map) continue;
                final pvl = item['playlistVideoListRenderer'];
                if (pvl is Map) {
                  final pvContents = pvl['contents'];
                  if (pvContents is List) return pvContents;
                }
              }
            }
          }
        }
      }
    }
    return null;
  }

  static String? _findContinuationToken(List<dynamic> items) {
    for (final item in items) {
      if (item is! Map || !item.containsKey('continuationItemRenderer')) {
        continue;
      }
      final endpoint =
          item['continuationItemRenderer']?['continuationEndpoint'];
      if (endpoint is Map) {
        final token = endpoint['continuationCommand']?['token'];
        if (token is String) return token;
        final commands =
            endpoint['commandExecutorCommand']?['commands'];
        if (commands is List) {
          final tok = commands
              .whereType<Map>()
              .map((c) => c['continuationCommand']?['token'])
              .whereType<String>()
              .firstOrNull;
          if (tok != null) return tok;
        }
      }
    }
    return null;
  }

  // ── Item parsers ─────────────────────────────────────────────────────────────

  static String _lockupAuthor(Map<String, dynamic> lockup) {
    try {
      final rows = lockup['metadata']?['lockupMetadataViewModel']?['metadata']
          ?['contentMetadataViewModel']?['metadataRows'];
      if (rows is List && rows.isNotEmpty) {
        final parts = rows[0]?['metadataParts'];
        if (parts is List && parts.isNotEmpty) {
          final author = parts[0]?['text']?['content'];
          if (author is String) return author;
        }
      }
    } catch (_) {}
    return '';
  }

  static String _lockupChannelId(Map<String, dynamic> lockup) {
    try {
      final rows = lockup['metadata']?['lockupMetadataViewModel']?['metadata']
          ?['contentMetadataViewModel']?['metadataRows'];
      if (rows is List && rows.isNotEmpty) {
        final parts = rows[0]?['metadataParts'];
        if (parts is List && parts.isNotEmpty) {
          final runs = parts[0]?['text']?['commandRuns'];
          if (runs is List && runs.isNotEmpty) {
            final id = runs[0]?['onTap']?['innertubeCommand']
                ?['browseEndpoint']?['browseId'];
            if (id is String) return id;
          }
        }
      }
    } catch (_) {}
    return '';
  }

  static Duration? _lockupDuration(Map<String, dynamic> lockup) {
    try {
      final overlays =
          lockup['contentImage']?['thumbnailViewModel']?['overlays'];
      if (overlays is List) {
        for (final overlay in overlays) {
          final badges =
              overlay?['thumbnailBottomOverlayViewModel']?['badges'];
          if (badges is List && badges.isNotEmpty) {
            final text =
                badges[0]?['thumbnailBadgeViewModel']?['text'];
            if (text is String) return _parseDuration(text);
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static Duration? _parseDuration(String text) {
    final parts = text.split(':').map(int.tryParse).toList();
    if (parts.any((p) => p == null)) return null;
    if (parts.length == 2) {
      return Duration(minutes: parts[0]!, seconds: parts[1]!);
    }
    if (parts.length == 3) {
      return Duration(hours: parts[0]!, minutes: parts[1]!, seconds: parts[2]!);
    }
    return null;
  }

  static List<Video> _parseItems(List<dynamic> items) {
    final list = <Video>[];
    for (final item in items) {
      if (item is! Map) continue;

      // ── lockupViewModel (new layout) ────────────────────────────────────────
      if (item.containsKey('lockupViewModel')) {
        final lv = item['lockupViewModel'] as Map<String, dynamic>;
        final videoId = lv['contentId'] as String?;
        final title = lv['metadata']?['lockupMetadataViewModel']
            ?['title']?['content'] as String?;
        if (videoId == null || title == null) continue;

        list.add(Video(
          VideoId(videoId),
          title,
          _lockupAuthor(lv),
          ChannelId(_lockupChannelId(lv)),
          DateTime.now(),
          '',
          null,
          '',
          _lockupDuration(lv),
          ThumbnailSet(videoId),
          null,
          Engagement(0, null, null),
          false,
        ));
        continue;
      }

      // ── playlistVideoRenderer (classic layout) ──────────────────────────────
      if (item.containsKey('playlistVideoRenderer')) {
        final vr = item['playlistVideoRenderer'] as Map<String, dynamic>;
        final videoId = vr['videoId'] as String?;
        final titleRuns = vr['title']?['runs'];
        final title = (titleRuns is List && titleRuns.isNotEmpty)
            ? titleRuns[0]['text'] as String?
            : null;
        if (videoId == null || title == null) continue;

        final authorRuns =
            vr['shortBylineText']?['runs'] ?? vr['ownerText']?['runs'];
        final author = (authorRuns is List && authorRuns.isNotEmpty)
            ? (authorRuns[0]['text'] as String? ?? '')
            : '';

        String channelId = '';
        if (authorRuns is List && authorRuns.isNotEmpty) {
          final run0 = authorRuns[0];
          if (run0 is Map) {
            final bId = run0['navigationEndpoint']
                ?['browseEndpoint']?['browseId'];
            if (bId is String) channelId = bId;
          }
        }

        final durationText = vr['lengthText']?['simpleText'] as String?;

        list.add(Video(
          VideoId(videoId),
          title,
          author,
          ChannelId(channelId),
          DateTime.now(),
          null,
          null,
          '',
          durationText != null ? _parseDuration(durationText) : null,
          ThumbnailSet(videoId),
          null,
          Engagement(0, null, null),
          false,
        ));
      }
    }
    return list;
  }

  // ── Public API ────────────────────────────────────────────────────────────────

  /// Fetches all videos from the given [playlistId] using the InnerTube
  /// browse endpoint, supporting both the legacy [playlistVideoRenderer] and
  /// the new [lockupViewModel] YouTube layouts.
  static Future<List<Video>> getPlaylistVideos(String playlistId) async {
    final videos = <Video>[];

    try {
      // 1. Fetch playlist page HTML to extract visitor data.
      final html = await _getString(
        'https://www.youtube.com/playlist?list=$playlistId&hl=en',
      );
      final visitorData = _extractVisitorData(html);

      // 2. Initial browse request with VL-prefixed browseId.
      final payload = <String, dynamic>{
        'context': {
          'client': {
            'clientName': 'WEB',
            'clientVersion': '2.20240726.00.00',
            'hl': 'en',
            'gl': 'US',
          },
        },
        'browseId': 'VL$playlistId',
      };

      var data = await _postBrowse(payload, visitorData: visitorData);
      var items = _findVideoItems(data);

      if (items != null) {
        videos.addAll(_parseItems(items));

        // 3. Paginate via continuation tokens.
        var token = _findContinuationToken(items);
        String? prevToken;

        while (token != null && token != prevToken) {
          prevToken = token;

          final contPayload = <String, dynamic>{
            'context': {
              'client': {
                'clientName': 'WEB',
                'clientVersion': '2.20240726.00.00',
                'hl': 'en',
                'gl': 'US',
              },
            },
            'continuation': token,
          };

          data = await _postBrowse(contPayload, visitorData: visitorData);
          final contItems = _findVideoItems(data);
          if (contItems == null || contItems.isEmpty) break;

          videos.addAll(_parseItems(contItems));
          token = _findContinuationToken(contItems);
        }
      }
    } catch (_) {
      // Return whatever was collected so far.
    }

    return videos;
  }
}
