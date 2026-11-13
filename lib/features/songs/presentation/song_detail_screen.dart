import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../domain/song_model.dart';
import 'cifra_view.dart';

/// Font size preferences persisted in memory during the session.
final _lyricFontSizeProvider = StateProvider<double>((ref) => 16);
final _chordFontSizeProvider = StateProvider<double>((ref) => 13);
final _showChordsProvider = StateProvider<bool>((ref) => true);

class SongDetailScreen extends ConsumerWidget {
  final String musicaId;

  const SongDetailScreen({super.key, required this.musicaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final lyricSize = ref.watch(_lyricFontSizeProvider);
    final chordSize = ref.watch(_chordFontSizeProvider);
    final showChords = ref.watch(_showChordsProvider);

    return FutureBuilder(
      future: db.getMusica(musicaId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final row = snapshot.data;
        if (row == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Música não encontrada.')),
          );
        }

        final content = SongContent.fromJson(
          jsonDecode(row.conteudoJson) as Map<String, dynamic>,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(
              content.titulo,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              // Toggle chords
              IconButton(
                icon: Icon(
                  showChords ? Icons.music_note : Icons.music_off_outlined,
                ),
                tooltip: showChords ? 'Ocultar cifras' : 'Mostrar cifras',
                onPressed:
                    () =>
                        ref.read(_showChordsProvider.notifier).state =
                            !showChords,
              ),
              // Font size controls
              IconButton(
                icon: const Icon(Icons.text_decrease),
                tooltip: 'Diminuir fonte',
                onPressed:
                    lyricSize > 10
                        ? () {
                          ref.read(_lyricFontSizeProvider.notifier).state =
                              lyricSize - 1;
                          ref.read(_chordFontSizeProvider.notifier).state =
                              chordSize - 1;
                        }
                        : null,
              ),
              IconButton(
                icon: const Icon(Icons.text_increase),
                tooltip: 'Aumentar fonte',
                onPressed:
                    lyricSize < 32
                        ? () {
                          ref.read(_lyricFontSizeProvider.notifier).state =
                              lyricSize + 1;
                          ref.read(_chordFontSizeProvider.notifier).state =
                              chordSize + 1;
                        }
                        : null,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: CifraView(
              song: content,
              lyricFontSize: lyricSize,
              chordFontSize: chordSize,
              showChords: showChords,
            ),
          ),
        );
      },
    );
  }
}
