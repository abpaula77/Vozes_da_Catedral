import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/router/app_router.dart';
import '../../songs/data/songs_provider.dart';
import '../../songs/domain/song_model.dart';
import '../data/celebrations_provider.dart';
import '../domain/celebration_model.dart';

class CelebrationsScreen extends ConsumerStatefulWidget {
  final String grupoId;
  final bool isCoordenador;

  const CelebrationsScreen({
    super.key,
    required this.grupoId,
    required this.isCoordenador,
  });

  @override
  ConsumerState<CelebrationsScreen> createState() => _CelebrationsScreenState();
}

class _CelebrationsScreenState extends ConsumerState<CelebrationsScreen> {
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _sync(showSuccess: false),
    );
  }

  Future<void> _sync({bool showSuccess = true}) async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      await ref
          .read(celebracoesServiceProvider)
          .syncCelebracoes(widget.grupoId);
      if (mounted && showSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Celebrações sincronizadas.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao sincronizar celebrações: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _createCelebracao() async {
    final result = await showDialog<_NewCelebration>(
      context: context,
      builder: (_) => const _NewCelebrationDialog(),
    );
    if (result == null || !mounted) return;

    try {
      final id = await ref
          .read(celebracoesServiceProvider)
          .createCelebracao(
            grupoId: widget.grupoId,
            titulo: result.titulo,
            dataHora: result.dataHora,
          );
      if (mounted) {
        context.push(
          AppRoutes.celebrationDetailPath(widget.grupoId, id),
          extra: widget.isCoordenador,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar celebração: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final celebrationsAsync = ref.watch(
      celebracoesByGrupoProvider(widget.grupoId),
    );
    final localizations = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Celebrações'),
        actions: [
          IconButton(
            icon:
                _isSyncing
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.sync),
            tooltip: 'Sincronizar celebrações',
            onPressed: _isSyncing ? null : _sync,
          ),
        ],
      ),
      body: celebrationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, _) =>
                Center(child: Text('Erro ao carregar celebrações: $error')),
        data: (celebrations) {
          if (celebrations.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhuma celebração cadastrada.\n'
                  'Crie uma celebração para montar os cantos.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: celebrations.length,
            itemBuilder: (context, index) {
              final celebration = celebrations[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.event)),
                title: Text(celebration.titulo),
                subtitle: Text(
                  '${localizations.formatMediumDate(celebration.dataHora)} · '
                  '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(celebration.dataHora))}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap:
                    () => context.push(
                      AppRoutes.celebrationDetailPath(
                        widget.grupoId,
                        celebration.id,
                      ),
                      extra: widget.isCoordenador,
                    ),
              );
            },
          );
        },
      ),
      floatingActionButton:
          widget.isCoordenador
              ? FloatingActionButton.extended(
                onPressed: _createCelebracao,
                icon: const Icon(Icons.add),
                label: const Text('Nova celebração'),
              )
              : null,
    );
  }
}

class CelebrationDetailScreen extends ConsumerStatefulWidget {
  final String grupoId;
  final String celebracaoId;
  final bool isCoordenador;

  const CelebrationDetailScreen({
    super.key,
    required this.grupoId,
    required this.celebracaoId,
    required this.isCoordenador,
  });

  @override
  ConsumerState<CelebrationDetailScreen> createState() =>
      _CelebrationDetailScreenState();
}

class _CelebrationDetailScreenState
    extends ConsumerState<CelebrationDetailScreen> {
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  Future<void> _sync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      await ref
          .read(celebracoesServiceProvider)
          .syncCelebracoes(widget.grupoId);
      if (mounted) {
        ref.invalidate(celebracaoLocalProvider(widget.celebracaoId));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao sincronizar celebração: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _editCelebracao(CelebracoesLocalData celebration) async {
    final result = await showDialog<_NewCelebration>(
      context: context,
      builder:
          (_) => _NewCelebrationDialog(
            initialTitle: celebration.titulo,
            initialDateTime: celebration.dataHora,
            dialogTitle: 'Editar celebração',
          ),
    );
    if (result == null || !mounted) return;
    try {
      await ref
          .read(celebracoesServiceProvider)
          .updateCelebracao(
            id: celebration.id,
            titulo: result.titulo,
            dataHora: result.dataHora,
          );
      if (mounted) {
        ref.invalidate(celebracaoLocalProvider(celebration.id));
        await _sync();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao editar celebração: $error')),
        );
      }
    }
  }

  Future<void> _chooseSong(ItensCelebracaoLocalData item) async {
    final songsState = ref.read(musicasByGrupoProvider(widget.grupoId));
    if (songsState.hasError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar músicas: ${songsState.error}'),
          ),
        );
      }
      return;
    }
    if (!songsState.hasValue) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Carregando hinário. Tente novamente.')),
        );
      }
      return;
    }
    final songs = songsState.requireValue;
    final itemsState = ref.read(itensByCelebracaoProvider(widget.celebracaoId));
    if (itemsState.hasError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao verificar músicas já utilizadas: ${itemsState.error}',
            ),
          ),
        );
      }
      return;
    }
    if (!itemsState.hasValue) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Carregando os momentos da celebração. Tente novamente.',
            ),
          ),
        );
      }
      return;
    }
    final celebrationItems = itemsState.requireValue;
    final moment = MomentoLiturgico.fromString(item.momentoLiturgico);
    final selectedId = await showDialog<String?>(
      context: context,
      builder:
          (context) => _SongPickerDialog(songs: songs, selectedMoment: moment),
    );
    if (selectedId == null || !mounted) return;
    final repeatedMoments =
        celebrationItems
            .where(
              (other) =>
                  other.id != item.id &&
                  other.musicaId == selectedId &&
                  selectedId.isNotEmpty,
            )
            .map(
              (other) =>
                  MomentoLiturgico.fromString(other.momentoLiturgico).label,
            )
            .toList();
    if (repeatedMoments.isNotEmpty) {
      final useAgain = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Música já utilizada'),
              content: Text(
                'Esta música já está selecionada em '
                '${repeatedMoments.join(', ')}. Deseja reutilizá-la também '
                'em ${moment.label}?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Usar mesmo assim'),
                ),
              ],
            ),
      );
      if (useAgain != true || !mounted) return;
    }
    try {
      await ref
          .read(celebracoesServiceProvider)
          .updateItem(
            celebracaoId: widget.celebracaoId,
            itemId: item.id,
            musicaId: selectedId == '' ? null : selectedId,
            observacao: item.observacao,
          );
      if (mounted) await _sync();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar música: $error')),
        );
      }
    }
  }

  Future<void> _editNote(ItensCelebracaoLocalData item) async {
    final controller = TextEditingController(text: item.observacao ?? '');
    final note = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Observação do momento'),
            content: TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Ex.: tom, orientação ou comentário',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Salvar'),
              ),
            ],
          ),
    );
    controller.dispose();
    if (note == null || !mounted) return;
    try {
      await ref
          .read(celebracoesServiceProvider)
          .updateItem(
            celebracaoId: widget.celebracaoId,
            itemId: item.id,
            musicaId: item.musicaId,
            observacao: note,
          );
      if (mounted) await _sync();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar observação: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final celebrationAsync = ref.watch(
      celebracaoLocalProvider(widget.celebracaoId),
    );
    final itemsAsync = ref.watch(
      itensByCelebracaoProvider(widget.celebracaoId),
    );
    final songsAsync = ref.watch(musicasByGrupoProvider(widget.grupoId));
    final localizations = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: celebrationAsync.maybeWhen(
          data: (celebration) => Text(celebration?.titulo ?? 'Celebração'),
          orElse: () => const Text('Celebração'),
        ),
        actions: [
          if (widget.isCoordenador)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Editar celebração',
              onPressed:
                  celebrationAsync.valueOrNull == null
                      ? null
                      : () => _editCelebracao(celebrationAsync.valueOrNull!),
            ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Abrir modo performance',
            onPressed:
                () => context.push(
                  AppRoutes.performancePath(
                    widget.grupoId,
                    widget.celebracaoId,
                  ),
                ),
          ),
          IconButton(
            icon:
                _isSyncing
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.sync),
            tooltip: 'Sincronizar',
            onPressed: _isSyncing ? null : _sync,
          ),
        ],
      ),
      body: celebrationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (celebration) {
          if (celebration == null) {
            return const Center(child: Text('Celebração não encontrada.'));
          }
          final items = itemsAsync.valueOrNull;
          if (items == null) {
            return itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Erro: $error')),
              data: (_) => const SizedBox.shrink(),
            );
          }
          final songs = songsAsync.valueOrNull ?? const <SongModel>[];
          final songTitles = {for (final song in songs) song.id: song.titulo};
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_month),
                  title: Text(
                    '${localizations.formatMediumDate(celebration.dataHora)} · '
                    '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(celebration.dataHora))}',
                  ),
                  subtitle: Text(
                    !celebration.isSynced || items.any((item) => !item.isSynced)
                        ? 'Rito Romano · Pendente de sincronização'
                        : 'Rito Romano',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (final item in items)
                _CelebrationMomentCard(
                  item: item,
                  songTitle: songTitles[item.musicaId],
                  isCoordenador: widget.isCoordenador,
                  onChooseSong: () => _chooseSong(item),
                  onEditNote: () => _editNote(item),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CelebrationMomentCard extends StatelessWidget {
  final ItensCelebracaoLocalData item;
  final String? songTitle;
  final bool isCoordenador;
  final VoidCallback onChooseSong;
  final VoidCallback onEditNote;

  const _CelebrationMomentCard({
    required this.item,
    required this.songTitle,
    required this.isCoordenador,
    required this.onChooseSong,
    required this.onEditNote,
  });

  @override
  Widget build(BuildContext context) {
    final moment = MomentoLiturgico.fromString(item.momentoLiturgico);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.ordem + 1}. ${moment.label}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.music_note),
              title: Text(
                songTitle ??
                    (item.musicaId == null
                        ? 'Nenhuma música selecionada'
                        : 'Música não encontrada no hinário'),
              ),
              trailing:
                  isCoordenador
                      ? IconButton(
                        tooltip: 'Selecionar música',
                        icon: const Icon(Icons.edit),
                        onPressed: onChooseSong,
                      )
                      : null,
            ),
            if (item.observacao?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(item.observacao!),
              ),
            if (isCoordenador)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onEditNote,
                  icon: const Icon(Icons.notes),
                  label: Text(
                    item.observacao?.isNotEmpty == true
                        ? 'Editar observação'
                        : 'Adicionar observação',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SongPickerDialog extends StatefulWidget {
  final List<SongModel> songs;
  final MomentoLiturgico selectedMoment;

  const _SongPickerDialog({required this.songs, required this.selectedMoment});

  @override
  State<_SongPickerDialog> createState() => _SongPickerDialogState();
}

class _SongPickerDialogState extends State<_SongPickerDialog> {
  MomentoLiturgico? _momentFilter;

  @override
  void initState() {
    super.initState();
    _momentFilter = widget.selectedMoment;
  }

  @override
  Widget build(BuildContext context) {
    final songs =
        widget.songs
            .where(
              (song) =>
                  _momentFilter == null ||
                  song.momentosLiturgicos.isEmpty ||
                  song.momentosLiturgicos.contains(_momentFilter),
            )
            .toList()
          ..sort((a, b) {
            final aMatches = a.momentosLiturgicos.contains(_momentFilter);
            final bMatches = b.momentosLiturgicos.contains(_momentFilter);
            return (aMatches == bMatches) ? 0 : (aMatches ? -1 : 1);
          });
    return AlertDialog(
      title: const Text('Selecionar música'),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    label: const Text('Todas'),
                    selected: _momentFilter == null,
                    onSelected: (_) => setState(() => _momentFilter = null),
                  ),
                  const SizedBox(width: 8),
                  for (final moment in MomentoLiturgico.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(moment.label),
                        selected: _momentFilter == moment,
                        onSelected:
                            (_) => setState(() => _momentFilter = moment),
                      ),
                    ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: const Icon(Icons.remove_circle_outline),
                    title: const Text('Remover música'),
                    onTap: () => Navigator.pop(context, ''),
                  ),
                  if (widget.songs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Nenhuma música disponível no hinário deste grupo.',
                      ),
                    )
                  else if (songs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Nenhuma música classificada para este momento.',
                      ),
                    ),
                  for (final song in songs)
                    ListTile(
                      leading: const Icon(Icons.music_note),
                      title: Text(song.titulo),
                      subtitle:
                          song.tomOriginal == null
                              ? null
                              : Text('Tom: ${song.tomOriginal}'),
                      onTap: () => Navigator.pop(context, song.id),
                    ),
                ],
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
      ],
    );
  }
}

class _NewCelebration {
  final String titulo;
  final DateTime dataHora;

  const _NewCelebration(this.titulo, this.dataHora);
}

class _NewCelebrationDialog extends StatefulWidget {
  final String initialTitle;
  final DateTime? initialDateTime;
  final String dialogTitle;

  const _NewCelebrationDialog({
    this.initialTitle = '',
    this.initialDateTime,
    this.dialogTitle = 'Nova celebração',
  });

  @override
  State<_NewCelebrationDialog> createState() => _NewCelebrationDialogState();
}

class _NewCelebrationDialogState extends State<_NewCelebrationDialog> {
  late final TextEditingController _titleController;
  late DateTime _dateTime;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _dateTime = widget.initialDateTime ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        _dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          _dateTime.hour,
          _dateTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time != null) {
      setState(() {
        _dateTime = DateTime(
          _dateTime.year,
          _dateTime.month,
          _dateTime.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.dialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Título',
                hintText: 'Ex.: Missa dominical',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month),
              title: const Text('Data'),
              subtitle: Text(localizations.formatMediumDate(_dateTime)),
              onTap: _selectDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Horário'),
              subtitle: Text(
                localizations.formatTimeOfDay(
                  TimeOfDay.fromDateTime(_dateTime),
                ),
              ),
              onTap: _selectTime,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final title = _titleController.text.trim();
            if (title.isEmpty) {
              setState(() => _error = 'Informe o título.');
              return;
            }
            Navigator.pop(context, _NewCelebration(title, _dateTime));
          },
          child: const Text('Criar'),
        ),
      ],
    );
  }
}
