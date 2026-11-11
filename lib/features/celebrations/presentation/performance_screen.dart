import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../songs/data/songs_provider.dart';
import '../../songs/domain/song_model.dart';
import '../../songs/presentation/cifra_view.dart';
import '../data/celebrations_provider.dart';
import '../domain/celebration_model.dart';

class PerformanceScreen extends ConsumerStatefulWidget {
  final String grupoId;
  final String celebracaoId;

  const PerformanceScreen({
    super.key,
    required this.grupoId,
    required this.celebracaoId,
  });

  @override
  ConsumerState<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends ConsumerState<PerformanceScreen>
    with WidgetsBindingObserver {
  final Map<String, GlobalKey> _momentKeys = {};
  final Set<String> _collapsedMoments = {};

  double _fontSize = 20;
  bool _showChords = true;
  bool _darkMode = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setScreenAwake(true, notifyError: true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _setScreenAwake(state == AppLifecycleState.resumed);
  }

  Future<void> _setScreenAwake(bool enabled, {bool notifyError = false}) async {
    try {
      if (enabled) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (error) {
      debugPrint('Falha ao atualizar wakelock: $error');
      if (notifyError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível manter a tela ativa: $error'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_setScreenAwake(false));
    super.dispose();
  }

  void _jumpToMoment(String itemId) {
    final context = _momentKeys[itemId]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    final performanceTheme = _darkMode ? AppTheme.dark : AppTheme.light;
    final itemsAsync = ref.watch(
      itensByCelebracaoProvider(widget.celebracaoId),
    );
    final songsAsync = ref.watch(musicasByGrupoProvider(widget.grupoId));
    final celebrationAsync = ref.watch(
      celebracaoLocalProvider(widget.celebracaoId),
    );

    return Theme(
      data: performanceTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            celebrationAsync.valueOrNull?.titulo ?? 'Modo Performance',
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            itemsAsync.maybeWhen(
              data:
                  (items) => PopupMenuButton<String>(
                    tooltip: 'Ir para momento',
                    icon: const Icon(Icons.list),
                    onSelected: _jumpToMoment,
                    itemBuilder:
                        (context) =>
                            items
                                .map(
                                  (item) => PopupMenuItem(
                                    value: item.id,
                                    child: Text(
                                      MomentoLiturgico.fromString(
                                        item.momentoLiturgico,
                                      ).label,
                                    ),
                                  ),
                                )
                                .toList(),
                  ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        body: itemsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Erro ao carregar momentos da celebração: $error',
                  ),
                ),
              ),
          data:
              (items) => songsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Erro ao carregar hinário local: $error'),
                      ),
                    ),
                data: (songs) => _buildPerformance(items, songs),
              ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Material(
            elevation: 8,
            color: performanceTheme.colorScheme.surfaceContainer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  tooltip: 'Diminuir fonte',
                  icon: const Icon(Icons.text_decrease),
                  onPressed:
                      _fontSize > 12
                          ? () => setState(() => _fontSize -= 2)
                          : null,
                ),
                IconButton(
                  tooltip: 'Aumentar fonte',
                  icon: const Icon(Icons.text_increase),
                  onPressed:
                      _fontSize < 34
                          ? () => setState(() => _fontSize += 2)
                          : null,
                ),
                IconButton(
                  tooltip: _showChords ? 'Ocultar cifras' : 'Mostrar cifras',
                  icon: Icon(
                    _showChords ? Icons.music_note : Icons.music_off_outlined,
                  ),
                  onPressed: () => setState(() => _showChords = !_showChords),
                ),
                IconButton(
                  tooltip: _darkMode ? 'Usar tema claro' : 'Usar tema escuro',
                  icon: Icon(_darkMode ? Icons.light_mode : Icons.dark_mode),
                  onPressed: () => setState(() => _darkMode = !_darkMode),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerformance(
    List<ItensCelebracaoLocalData> items,
    List<SongModel> songs,
  ) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Esta celebração ainda não possui momentos cadastrados.'),
      );
    }

    final songsById = {for (final song in songs) song.id: song};
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children:
          items.map((item) {
            final song = songsById[item.musicaId];
            final key = _momentKeys.putIfAbsent(item.id, GlobalKey.new);

            return Card(
              key: key,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap:
                          song == null
                              ? null
                              : () => setState(() {
                                if (!_collapsedMoments.add(item.id)) {
                                  _collapsedMoments.remove(item.id);
                                }
                              }),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.ordem + 1}. '
                                '${MomentoLiturgico.fromString(item.momentoLiturgico).label}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            if (song != null)
                              Icon(
                                _collapsedMoments.contains(item.id)
                                    ? Icons.expand_more
                                    : Icons.expand_less,
                                semanticLabel:
                                    _collapsedMoments.contains(item.id)
                                        ? 'Expandir música'
                                        : 'Recolher música',
                              ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 24),
                    if (song == null)
                      Text(
                        item.musicaId == null
                            ? 'Nenhuma música selecionada para este momento.'
                            : 'A música selecionada não está disponível offline.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      )
                    else if (!_collapsedMoments.contains(item.id))
                      CifraView(
                        song: song.conteudoJson,
                        lyricFontSize: _fontSize,
                        chordFontSize: _fontSize * 0.78,
                        showChords: _showChords,
                      ),
                    if (item.observacao?.isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      Text(
                        item.observacao!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}
