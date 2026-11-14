import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../domain/group_model.dart';

/// Messages raised by the database are written for users; anything else is
/// most likely a connection problem (#61).
String mensagemErroExclusao(Object error) {
  if (error is PostgrestException && error.message.trim().isNotEmpty) {
    return error.message;
  }
  if (error is StateError) return error.message;
  return 'Esta ação precisa de internet.';
}

/// Whether [digitado] matches the group name, ignoring case and spaces at
/// the ends (the database applies the same rule).
bool nomeConfere(String digitado, String nomeGrupo) =>
    digitado.trim().toLowerCase() == nomeGrupo.trim().toLowerCase();

/// "Zona de perigo" at the end of the members screen (coordinators only).
class ZonaDePerigo extends StatelessWidget {
  final VoidCallback onExcluir;

  const ZonaDePerigo({super.key, required this.onExcluir});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final erro = theme.colorScheme.error;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: erro.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zona de perigo',
                style: theme.textTheme.titleSmall?.copyWith(color: erro),
              ),
              const SizedBox(height: 4),
              const Text(
                'Excluir o grupo apaga as músicas, as celebrações e a lista '
                'de membros para todos.',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: erro,
                  side: BorderSide(color: erro),
                ),
                onPressed: onExcluir,
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Excluir grupo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 1: what will be lost, with an optional copy to another group.
/// Pops `true` when the user chooses to continue.
class ResumoExclusaoDialog extends StatefulWidget {
  final String nomeGrupo;
  final Future<ResumoExclusao> Function() carregar;

  /// Asks for a destination and copies. Returns the message to show after a
  /// successful copy, or null when the user cancelled.
  final Future<String?> Function() copiar;

  const ResumoExclusaoDialog({
    super.key,
    required this.nomeGrupo,
    required this.carregar,
    required this.copiar,
  });

  @override
  State<ResumoExclusaoDialog> createState() => _ResumoExclusaoDialogState();
}

class _ResumoExclusaoDialogState extends State<ResumoExclusaoDialog> {
  late final Future<ResumoExclusao> _resumo = widget.carregar();
  bool _copiando = false;
  String? _copiado;
  String? _erroCopia;

  Future<void> _copiar() async {
    setState(() {
      _copiando = true;
      _erroCopia = null;
    });
    try {
      final mensagem = await widget.copiar();
      if (!mounted) return;
      setState(() => _copiado = mensagem);
    } catch (error) {
      if (mounted) setState(() => _erroCopia = mensagemErroExclusao(error));
    } finally {
      if (mounted) setState(() => _copiando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<ResumoExclusao>(
      future: _resumo,
      builder: (context, snapshot) {
        final resumo = snapshot.data;
        final Widget content;
        if (snapshot.hasError) {
          content = Text(mensagemErroExclusao(snapshot.error!));
        } else if (resumo == null) {
          content = const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        } else {
          content = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Linha('Membros', resumo.membros),
              _Linha(
                'Músicas',
                resumo.musicas,
                detalhe:
                    resumo.musicasExclusivas == 1
                        ? '1 só existe neste grupo'
                        : '${resumo.musicasExclusivas} só existem neste grupo',
              ),
              _Linha('Celebrações', resumo.celebracoes),
              _Linha('Solicitações pendentes', resumo.solicitacoesPendentes),
              const SizedBox(height: 12),
              const Text(
                'Músicas copiadas para outros grupos continuam existindo '
                'neles.',
              ),
              const SizedBox(height: 8),
              Text(
                'A exclusão é definitiva e não pode ser desfeita.',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (resumo.temConteudoParaCopiar) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _copiando || _copiado != null ? null : _copiar,
                  icon:
                      _copiando
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.copy_all_outlined),
                  label: const Text('Copiar para outro grupo'),
                ),
                if (_copiado != null) ...[
                  const SizedBox(height: 8),
                  Text(_copiado!),
                ],
                if (_erroCopia != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _erroCopia!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
              ],
            ],
          );
        }

        return AlertDialog(
          title: Text('Excluir ${widget.nomeGrupo}?'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(child: content),
          ),
          actions: [
            TextButton(
              onPressed: _copiando ? null : () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed:
                  resumo == null || _copiando
                      ? null
                      : () => Navigator.pop(context, true),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }
}

class _Linha extends StatelessWidget {
  final String rotulo;
  final int valor;
  final String? detalhe;

  const _Linha(this.rotulo, this.valor, {this.detalhe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        detalhe == null ? '$rotulo: $valor' : '$rotulo: $valor ($detalhe)',
      ),
    );
  }
}

/// Step 2: choose the group that receives the copy.
class DestinoCopiaDialog extends StatelessWidget {
  final List<GrupoModel> destinos;

  const DestinoCopiaDialog({super.key, required this.destinos});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Copiar para qual grupo?'),
      content: SizedBox(
        width: 480,
        child:
            destinos.isEmpty
                ? const Text(
                  'Você não coordena outro grupo. Crie um grupo antes para '
                  'receber o conteúdo.',
                )
                : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final grupo in destinos)
                      ListTile(
                        leading: const Icon(Icons.group_outlined),
                        title: Text(grupo.nome),
                        onTap: () => Navigator.pop(context, grupo),
                      ),
                  ],
                ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

/// Step 3: type the group name to confirm. Pops the typed text.
class ConfirmarExclusaoDialog extends StatefulWidget {
  final String nomeGrupo;

  const ConfirmarExclusaoDialog({super.key, required this.nomeGrupo});

  @override
  State<ConfirmarExclusaoDialog> createState() =>
      _ConfirmarExclusaoDialogState();
}

class _ConfirmarExclusaoDialogState extends State<ConfirmarExclusaoDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _confere => nomeConfere(_controller.text, widget.nomeGrupo);

  void _confirmar() {
    if (_confere) Navigator.pop(context, _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Confirmar exclusão'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Para confirmar, digite o nome do grupo: ${widget.nomeGrupo}'),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Nome do grupo',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _confirmar(),
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
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: _confere ? _confirmar : null,
          child: const Text('Excluir'),
        ),
      ],
    );
  }
}
