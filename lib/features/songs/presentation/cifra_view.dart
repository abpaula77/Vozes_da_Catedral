import 'package:flutter/material.dart';

import '../domain/song_model.dart';

/// Renders a full song with chord lines above lyric lines using a
/// monospaced font so chords stay aligned with the correct syllables.
///
/// Supports:
/// - Independent chord font size and lyric font size
/// - Toggle to show/hide chord lines
/// - Dark/light mode via Theme
class CifraView extends StatelessWidget {
  final SongContent song;
  final double lyricFontSize;
  final double chordFontSize;
  final bool showChords;

  const CifraView({
    super.key,
    required this.song,
    this.lyricFontSize = 16,
    this.chordFontSize = 13,
    this.showChords = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Song header
        _SongHeader(song: song, theme: theme),
        const SizedBox(height: 24),
        // Sections
        ...song.secoes.map(
          (section) => _SectionWidget(
            section: section,
            lyricFontSize: lyricFontSize,
            chordFontSize: chordFontSize,
            showChords: showChords,
            theme: theme,
          ),
        ),
      ],
    );
  }
}

class _SongHeader extends StatelessWidget {
  final SongContent song;
  final ThemeData theme;

  const _SongHeader({required this.song, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          song.titulo,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (song.tomOriginal != null)
              _MetaChip(
                icon: Icons.music_note,
                label: 'Tom: ${song.tomOriginal}',
                theme: theme,
              ),
            if (song.bpm != null)
              _MetaChip(
                icon: Icons.speed,
                label: '${song.bpm} BPM',
                theme: theme,
              ),
            ...song.categorias.map(
              (cat) => _MetaChip(
                icon: Icons.label_outline,
                label: _formatCategoria(cat),
                theme: theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatCategoria(String cat) {
    return cat.isNotEmpty
        ? cat[0].toUpperCase() + cat.substring(1).toLowerCase()
        : cat;
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionWidget extends StatelessWidget {
  final SongSection section;
  final double lyricFontSize;
  final double chordFontSize;
  final bool showChords;
  final ThemeData theme;

  const _SectionWidget({
    required this.section,
    required this.lyricFontSize,
    required this.chordFontSize,
    required this.showChords,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isRefrao =
        section.tipo.toUpperCase().contains('REFRAO') ||
        section.tipo.toUpperCase().contains('REFRÃO');

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color:
                  isRefrao
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _formatSectionLabel(section.tipo),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color:
                    isRefrao
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
          ),
          // Lines
          ...section.linhas.map(
            (line) => _LineWidget(
              line: line,
              lyricFontSize: lyricFontSize,
              chordFontSize: chordFontSize,
              showChords: showChords,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSectionLabel(String tipo) {
    return tipo.toUpperCase();
  }
}

class _LineWidget extends StatelessWidget {
  final SongLine line;
  final double lyricFontSize;
  final double chordFontSize;
  final bool showChords;
  final ThemeData theme;

  const _LineWidget({
    required this.line,
    required this.lyricFontSize,
    required this.chordFontSize,
    required this.showChords,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final hasCifra = showChords && line.cifra != null && line.cifra!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chord line — monospaced font is critical for alignment
          if (hasCifra)
            Text(
              line.cifra!,
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: chordFontSize,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
                height: 1.2,
              ),
            ),
          // Lyric line
          if (line.letra.isNotEmpty)
            Text(
              line.letra,
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: lyricFontSize,
                height: 1.4,
                color: theme.colorScheme.onSurface,
              ),
            ),
        ],
      ),
    );
  }
}
