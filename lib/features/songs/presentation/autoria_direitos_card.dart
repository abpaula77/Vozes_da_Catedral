import 'package:flutter/material.dart';

import '../domain/direitos_autorais.dart';
import '../domain/song_model.dart';

/// Authorship and rights of a song (issue #27): hymnal only, for every user.
/// Not used in celebrations or performance mode.

/// Opens a dialog with the authorship and rights of [song]. Used by the
/// song menu in the hymnal list.
Future<void> mostrarAutoriaDireitos(BuildContext context, SongContent song) {
  return showDialog<void>(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          icon: const Icon(Icons.copyright_outlined),
          title: const Text('Autoria e direitos'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.titulo,
                  style: Theme.of(dialogContext).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                AutoriaDireitosInfo(song: song),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fechar'),
            ),
          ],
        ),
  );
}

/// Card shown at the end of the song detail.
class AutoriaDireitosCard extends StatelessWidget {
  final SongContent song;

  const AutoriaDireitosCard({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.copyright_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('Autoria e direitos', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            AutoriaDireitosInfo(song: song),
          ],
        ),
      ),
    );
  }
}

/// The filled-in fields, or "Não informados." when there are none.
class AutoriaDireitosInfo extends StatelessWidget {
  final SongContent song;

  const AutoriaDireitosInfo({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linhas = <(String, String)>[
      if (song.letrista case final valor?) ('Letra', valor),
      if (song.compositor case final valor?) ('Música', valor),
      if (song.editora case final valor?) ('Editora', valor),
      if (song.statusDireitos case final status?)
        ('Direitos', descreverDireitos(status, song.direitosAte)),
      if (song.statusLicencaApp case final status?)
        ('Licença no app', status.rotulo),
    ];

    if (linhas.isEmpty) {
      return Text(
        'Não informados.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (rotulo, valor) in linhas)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$rotulo: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: valor),
                ],
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }
}
