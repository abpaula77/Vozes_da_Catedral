import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../celebrations/presentation/celebrations_screen.dart';
import '../../songs/presentation/songs_screen.dart';
import '../data/groups_provider.dart';
import '../domain/group_model.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String grupoId;

  const GroupDetailScreen({super.key, required this.grupoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gruposAsync = ref.watch(gruposProvider);

    return gruposAsync.when(
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erro: $e'))),
      data: (grupos) {
        final grupo = grupos.where((g) => g.id == grupoId).firstOrNull;
        if (grupo == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Grupo não encontrado.')),
          );
        }
        return _GroupDetailView(grupo: grupo);
      },
    );
  }
}

class _GroupDetailView extends ConsumerStatefulWidget {
  final GrupoModel grupo;
  const _GroupDetailView({required this.grupo});

  @override
  ConsumerState<_GroupDetailView> createState() => _GroupDetailViewState();
}

class _GroupDetailViewState extends ConsumerState<_GroupDetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grupo = widget.grupo;

    return Scaffold(
      appBar: AppBar(
        title: Text(grupo.nome),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.music_note), text: 'Hinário'),
            Tab(icon: Icon(Icons.event), text: 'Celebrações'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_outlined),
            tooltip: 'Ver membros',
            onPressed: () => context.pushGroupMembers(grupo.id),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SongsScreen(grupoId: grupo.id, isCoordenador: grupo.isCoordenador),
          CelebrationsScreen(
            grupoId: grupo.id,
            isCoordenador: grupo.isCoordenador,
          ),
        ],
      ),
    );
  }
}
