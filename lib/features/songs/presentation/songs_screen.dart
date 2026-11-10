import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/momento_liturgico.dart';
import '../../../core/router/app_router.dart';
import '../data/songs_provider.dart';
import '../domain/song_model.dart';
import '../domain/song_parser.dart';

final _songMomentFilterProvider =
    StateProvider.family<MomentoLiturgico?, String>((ref, grupoId) => null);

class SongsScreen extends ConsumerWidget {
  final String grupoId;
  final bool isCoordenador;

  const SongsScreen({
    super.key,
    required this.grupoId,
    required this.isCoordenador,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final musicasAsync = ref.watch(musicasByGrupoProvider(grupoId));
    final syncAtAsync = ref.watch(musicasSyncAtProvider(grupoId));
    final selectedMoment = ref.watch(_songMomentFilterProvider(grupoId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hinário'),
        actions: [
          if (isCoordenador)
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: 'Importar .txt',
              onPressed: () => _importFile(context, ref),
            ),
          if (isCoordenador)
            IconButton(
              icon: const Icon(Icons.cloud_upload_outlined),
              tooltip: 'Publicar no grupo',
              onPressed: () => _publishMusicas(context, ref),
            ),
          if (isCoordenador)
            IconButton(
              icon: const Icon(Icons.library_music_outlined),
              tooltip: 'Adicionar do catálogo compartilhado',
              onPressed: () => _browseCatalog(context, ref),
            ),
          IconButton(
            icon: const Icon(Icons.cloud_download_outlined),
            tooltip: 'Sincronizar com grupo',
            onPressed: () => _syncMusicas(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: selectedMoment == null,
                  onSelected:
                      (_) =>
                          ref
                              .read(_songMomentFilterProvider(grupoId).notifier)
                              .state = null,
                ),
                const SizedBox(width: 8),
                for (final moment in MomentoLiturgico.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(moment.label),
                      selected: selectedMoment == moment,
                      onSelected:
                          (_) =>
                              ref
                                  .read(
                                    _songMomentFilterProvider(grupoId).notifier,
                                  )
                                  .state = moment,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: musicasAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (musicas) {
                final filteredMusicas =
                    selectedMoment == null
                        ? musicas
                        : musicas
                            .where(
                              (song) => song.momentosLiturgicos.contains(
                                selectedMoment,
                              ),
                            )
                            .toList();
                if (musicas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_off,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma música no hinário.',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (isCoordenador)
                          FilledButton.tonal(
                            onPressed: () => _importFile(context, ref),
                            child: const Text('Importar arquivo .txt'),
                          )
                        else
                          FilledButton.tonal(
                            onPressed: () => _syncMusicas(context, ref),
                            child: const Text('Sincronizar com grupo'),
                          ),
                      ],
                    ),
                  );
                }
                if (filteredMusicas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Nenhuma música classificada para '
                          '${selectedMoment!.label}.',
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed:
                              () =>
                                  ref
                                      .read(
                                        _songMomentFilterProvider(
                                          grupoId,
                                        ).notifier,
                                      )
                                      .state = null,
                          child: const Text('Mostrar todas'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredMusicas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final musica = filteredMusicas[index];
                    return _MusicaCard(
                      musica: musica,
                      isCoordenador: isCoordenador,
                      onClassify:
                          isCoordenador
                              ? () => _editMoments(context, ref, musica)
                              : null,
                      onDelete:
                          isCoordenador
                              ? () => _deleteMusica(context, ref, musica)
                              : null,
                      onTap:
                          () => context.push(
                            AppRoutes.songDetailPath(grupoId, musica.id),
                          ),
                    );
                  },
                );
              },
            ),
          ),
          _SyncStatus(syncAt: syncAtAsync),
        ],
      ),
      floatingActionButton:
          isCoordenador
              ? FloatingActionButton.extended(
                onPressed: () => _importFile(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Importar .txt'),
              )
              : null,
    );
  }

  Future<void> _editMoments(
    BuildContext context,
    WidgetRef ref,
    SongModel song,
  ) async {
    final moments = await showDialog<List<MomentoLiturgico>>(
      context: context,
      builder: (_) => _SongMomentsDialog(selected: song.momentosLiturgicos),
    );
    if (moments == null || !context.mounted) return;
    try {
      await ref
          .read(songsServiceProvider)
          .updateMomentosLiturgicos(song.id, moments);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Classificação salva.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao classificar música: $error')),
        );
      }
    }
  }

  Future<void> _importFile(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(songsServiceProvider);
      final titulo = await service.importFromFile(grupoId: grupoId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$titulo" adicionado ao hinário.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } on SongParseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no arquivo: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao importar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _publishMusicas(BuildContext context, WidgetRef ref) async {
    final service = ref.read(songsServiceProvider);
    try {
      final count = await service.publishMusicas(grupoId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count música(s) publicada(s) no grupo.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao publicar: $e')));
      }
    }
  }

  Future<void> _syncMusicas(BuildContext context, WidgetRef ref) async {
    final service = ref.read(songsServiceProvider);
    try {
      final count = await service.syncMusicas(grupoId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count música(s) sincronizada(s).')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao sincronizar: $e')));
      }
    }
  }

  Future<void> _browseCatalog(BuildContext context, WidgetRef ref) async {
    try {
      final songs = await ref
          .read(songsServiceProvider)
          .getCatalogoMusicas(grupoId);
      if (!context.mounted) return;

      if (songs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não há músicas de outros grupos no catálogo.'),
          ),
        );
        return;
      }

      final selection = await showDialog<_CatalogSongSelection>(
        context: context,
        builder: (_) => _CatalogSongDialog(songs: songs),
      );
      if (selection == null || !context.mounted) return;

      if (selection.addAll) {
        final count = await ref
            .read(songsServiceProvider)
            .copiarTodasMusicasDoCatalogo(grupoId: grupoId, musicas: songs);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$count música(s) do catálogo foram adicionadas ou já '
                'estavam no hinário.',
              ),
            ),
          );
        }
        return;
      }

      final selectedSong = selection.song!;
      await ref
          .read(songsServiceProvider)
          .copiarMusicaDoCatalogo(grupoId: grupoId, musicaId: selectedSong.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '"${selectedSong.titulo}" copiada para o hinário do grupo.',
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao consultar ou adicionar do catálogo: $error'),
          ),
        );
      }
    }
  }

  Future<void> _deleteMusica(
    BuildContext context,
    WidgetRef ref,
    SongModel musica,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Remover música?'),
            content: Text('"${musica.titulo}" será removida do hinário local.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Remover'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await ref.read(songsServiceProvider).deleteMusica(musica.id);
    }
  }
}

class _SongMomentsDialog extends StatefulWidget {
  final List<MomentoLiturgico> selected;

  const _SongMomentsDialog({required this.selected});

  @override
  State<_SongMomentsDialog> createState() => _SongMomentsDialogState();
}

class _SongMomentsDialogState extends State<_SongMomentsDialog> {
  late final Set<MomentoLiturgico> _selected = {...widget.selected};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Momentos litúrgicos'),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final moment in MomentoLiturgico.values)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(moment.label),
                value: _selected.contains(moment),
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      _selected.add(moment);
                    } else {
                      _selected.remove(moment);
                    }
                  });
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => setState(_selected.clear),
          child: const Text('Limpar'),
        ),
        FilledButton(
          onPressed:
              () => Navigator.pop(
                context,
                MomentoLiturgico.values.where(_selected.contains).toList(),
              ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _CatalogSongSelection {
  final SongModel? song;
  final bool addAll;

  const _CatalogSongSelection.song(this.song) : addAll = false;
  const _CatalogSongSelection.all() : song = null, addAll = true;
}

class _CatalogSongDialog extends StatefulWidget {
  final List<SongModel> songs;

  const _CatalogSongDialog({required this.songs});

  @override
  State<_CatalogSongDialog> createState() => _CatalogSongDialogState();
}

class _CatalogSongDialogState extends State<_CatalogSongDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songs =
        widget.songs
            .where(
              (song) =>
                  song.titulo.toLowerCase().contains(_query.toLowerCase()),
            )
            .toList();

    return AlertDialog(
      title: const Text('Catálogo compartilhado'),
      content: SizedBox(
        width: 480,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar música',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  songs.isEmpty
                      ? const Center(child: Text('Nenhuma música encontrada.'))
                      : ListView.separated(
                        itemCount: songs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final song = songs[index];
                          final details = <String>[
                            if (song.tomOriginal != null)
                              'Tom ${song.tomOriginal}',
                            if (song.bpm != null) '${song.bpm} BPM',
                          ];
                          return ListTile(
                            leading: const Icon(Icons.music_note),
                            title: Text(song.titulo),
                            subtitle:
                                details.isEmpty
                                    ? null
                                    : Text(details.join(' · ')),
                            onTap:
                                () => Navigator.pop(
                                  context,
                                  _CatalogSongSelection.song(song),
                                ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
        FilledButton.icon(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Adicionar todas as músicas?'),
                    content: Text(
                      'As ${widget.songs.length} músicas do catálogo serão '
                      'adicionadas ao hinário do grupo. As que já foram '
                      'adicionadas não serão duplicadas.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Adicionar todas'),
                      ),
                    ],
                  ),
            );
            if (confirmed == true && context.mounted) {
              Navigator.pop(context, const _CatalogSongSelection.all());
            }
          },
          icon: const Icon(Icons.library_add),
          label: Text('Adicionar todas (${widget.songs.length})'),
        ),
      ],
    );
  }
}

class _SyncStatus extends StatelessWidget {
  final AsyncValue<DateTime?> syncAt;

  const _SyncStatus({required this.syncAt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = syncAt.when(
      loading:
          () => const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('Consultando sincronização...'),
            ],
          ),
      error:
          (error, _) => Text(
            'Erro ao consultar sincronização: $error',
            style: TextStyle(color: theme.colorScheme.error),
          ),
      data: (date) {
        if (date == null) {
          return const Text('Ainda não sincronizado com o grupo.');
        }
        final localDate = date.toLocal();
        final formatted =
            '${localDate.day.toString().padLeft(2, '0')}/'
            '${localDate.month.toString().padLeft(2, '0')}/'
            '${localDate.year} '
            '${localDate.hour.toString().padLeft(2, '0')}:'
            '${localDate.minute.toString().padLeft(2, '0')}';
        return Text('Última sincronização: $formatted');
      },
    );

    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: DefaultTextStyle(
        style: theme.textTheme.bodySmall!,
        textAlign: TextAlign.center,
        child: status,
      ),
    );
  }
}

class _MusicaCard extends StatelessWidget {
  final SongModel musica;
  final bool isCoordenador;
  final VoidCallback? onClassify;
  final VoidCallback? onDelete;
  final VoidCallback onTap;

  const _MusicaCard({
    required this.musica,
    required this.isCoordenador,
    required this.onTap,
    this.onClassify,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Tone badge
              if (musica.tomOriginal != null)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    musica.tomOriginal!,
                    style: TextStyle(
                      fontFamily: 'RobotoMono',
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                      fontSize: 13,
                    ),
                  ),
                )
              else
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.music_note,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(width: 16),
              // Title + categories
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      musica.titulo,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (musica.momentosLiturgicos.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children:
                            musica.momentosLiturgicos
                                .map(
                                  (moment) => _CategoryBadge(cat: moment.label),
                                )
                                .toList(),
                      ),
                    ],
                    if (musica.categorias.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children:
                            musica.categorias
                                .take(3)
                                .map((cat) => _CategoryBadge(cat: cat))
                                .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              if (onClassify != null)
                IconButton(
                  icon: const Icon(Icons.category_outlined),
                  tooltip: 'Classificar momentos litúrgicos',
                  onPressed: onClassify,
                  iconSize: 20,
                ),
              if (onDelete != null)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error.withValues(alpha: 0.7),
                  ),
                  onPressed: onDelete,
                  iconSize: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String cat;
  const _CategoryBadge({required this.cat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        cat.length > 1 ? cat[0].toUpperCase() + cat.substring(1) : cat,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
