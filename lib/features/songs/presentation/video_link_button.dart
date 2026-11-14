import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/song_parser.dart';

/// Opens a song's video link in the browser or the platform's video app.
///
/// Only http(s) links are opened. It is shown in the hymnal and in the
/// celebration builder, but not in performance mode.
class VideoLinkButton extends StatelessWidget {
  final String url;

  /// When true, renders a compact icon button instead of a text button.
  final bool compact;

  const VideoLinkButton({super.key, required this.url, this.compact = false});

  static Future<void> open(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final safeUrl = SongParser.normalizeVideoUrl(url);
    var opened = false;
    if (safeUrl != null) {
      try {
        opened = await launchUrl(
          Uri.parse(safeUrl),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        opened = false;
      }
    }
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o link do vídeo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        icon: const Icon(Icons.play_circle_outline),
        tooltip: 'Assistir vídeo',
        iconSize: 20,
        onPressed: () => open(context, url),
      );
    }
    return TextButton.icon(
      onPressed: () => open(context, url),
      icon: const Icon(Icons.play_circle_outline),
      label: const Text('Assistir vídeo'),
    );
  }
}
