import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/presentation/auth_provider.dart';
import '../data/profile_service.dart';
import '../domain/meu_perfil_model.dart';
import 'user_avatar.dart';

/// "Meu perfil" (issue #42): photo, name, e-mail, sign out and account
/// deletion. Online only; changes need internet (requirement 1.5).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(meuPerfilProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: perfil.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      mensagemErroPerfil(error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(meuPerfilProvider),
                      child: const Text('Tentar novamente'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => ref.read(authServiceProvider).signOut(),
                      icon: const Icon(Icons.logout),
                      label: const Text('Sair'),
                    ),
                  ],
                ),
              ),
            ),
        data: (dados) {
          if (dados == null) {
            return const Center(child: Text('Perfil não encontrado.'));
          }
          return _ProfileView(perfil: dados);
        },
      ),
    );
  }
}

class _ProfileView extends ConsumerStatefulWidget {
  final MeuPerfilModel perfil;

  const _ProfileView({required this.perfil});

  @override
  ConsumerState<_ProfileView> createState() => _ProfileViewState();
}

enum _AcaoFoto { galeria, camera, google, remover }

class _ProfileViewState extends ConsumerState<_ProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  bool _ocupado = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.perfil.nome);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  ProfileService get _service => ref.read(profileServiceProvider);

  Future<void> _executar(
    Future<void> Function() acao, {
    String? sucesso,
  }) async {
    setState(() => _ocupado = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await acao();
      if (sucesso != null) {
        messenger.showSnackBar(SnackBar(content: Text(sucesso)));
      }
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(mensagemErroPerfil(error))),
      );
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _salvarNome() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await _executar(
      () => _service.atualizarNome(_nomeController.text),
      sucesso: 'Nome atualizado.',
    );
  }

  Future<void> _alterarFoto() async {
    final perfil = widget.perfil;
    final acao = await showModalBottomSheet<_AcaoFoto>(
      context: context,
      showDragHandle: true,
      builder:
          (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // On the web (computer) the picker opens the file dialog.
                ListTile(
                  leading: Icon(
                    kIsWeb
                        ? Icons.upload_file_outlined
                        : Icons.photo_library_outlined,
                  ),
                  title: Text(
                    kIsWeb ? 'Escolher arquivo' : 'Escolher da galeria',
                  ),
                  subtitle: const Text('JPEG, PNG ou WebP'),
                  onTap: () => Navigator.pop(sheetContext, _AcaoFoto.galeria),
                ),
                if (!kIsWeb)
                  ListTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: const Text('Tirar foto'),
                    onTap: () => Navigator.pop(sheetContext, _AcaoFoto.camera),
                  ),
                // Always listed when the account has a Google photo; marked
                // (and disabled) when it is already the profile photo.
                if (perfil.fotoDoGoogle != null)
                  ListTile(
                    leading: const Icon(Icons.account_circle_outlined),
                    title: const Text('Usar a foto do Google'),
                    subtitle:
                        perfil.usaFotoDoGoogle
                            ? const Text('Em uso no seu perfil')
                            : null,
                    trailing:
                        perfil.usaFotoDoGoogle
                            ? const Icon(Icons.check_circle)
                            : null,
                    enabled: !perfil.usaFotoDoGoogle,
                    onTap: () => Navigator.pop(sheetContext, _AcaoFoto.google),
                  ),
                if (perfil.tipoFoto != TipoFoto.nenhuma)
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Remover foto'),
                    onTap: () => Navigator.pop(sheetContext, _AcaoFoto.remover),
                  ),
              ],
            ),
          ),
    );
    if (acao == null || !mounted) return;

    switch (acao) {
      case _AcaoFoto.galeria:
      case _AcaoFoto.camera:
        final XFile? arquivo;
        try {
          arquivo = await ImagePicker().pickImage(
            source:
                acao == _AcaoFoto.camera
                    ? ImageSource.camera
                    : ImageSource.gallery,
            maxWidth: 512,
            maxHeight: 512,
            imageQuality: 80,
          );
        } catch (error) {
          debugPrint('Falha ao escolher imagem: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  kIsWeb
                      ? 'Não foi possível abrir a seleção de arquivo.'
                      : 'Não foi possível abrir a galeria ou a câmera.',
                ),
              ),
            );
          }
          return;
        }
        if (arquivo == null || !mounted) return;
        final selecionado = arquivo;
        await _executar(
          () => _service.enviarFoto(selecionado),
          sucesso: 'Foto atualizada.',
        );
      case _AcaoFoto.google:
        await _executar(
          _service.usarFotoDoGoogle,
          sucesso: 'Agora você usa a foto do Google.',
        );
      case _AcaoFoto.remover:
        await _executar(_service.removerFoto, sucesso: 'Foto removida.');
    }
  }

  Future<void> _excluirConta() async {
    setState(() => _ocupado = true);
    List<String> bloqueios;
    try {
      bloqueios = await _service.gruposImpedindoExclusao();
    } catch (error) {
      if (mounted) {
        setState(() => _ocupado = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensagemErroPerfil(error))));
      }
      return;
    }
    if (!mounted) return;
    setState(() => _ocupado = false);

    if (bloqueios.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('Não é possível excluir agora'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Você é o único coordenador destes grupos. Promova outro '
                    'coordenador ou exclua o grupo antes:',
                  ),
                  const SizedBox(height: 12),
                  for (final nome in bloqueios) Text('• $nome'),
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Entendi'),
                ),
              ],
            ),
      );
      return;
    }

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => const _ConfirmarExclusaoDialog(),
    );
    if (confirmado != true || !mounted) return;

    await _executar(_service.excluirConta);
    // On success the session ends and the router goes to the login screen.
  }

  @override
  Widget build(BuildContext context) {
    final perfil = widget.perfil;
    final theme = Theme.of(context);

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: UserAvatar(
                nome: perfil.nome,
                foto: perfil.foto,
                radius: 56,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _ocupado ? null : _alterarFoto,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Alterar foto'),
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  helperText: 'É assim que os colegas veem você nos grupos.',
                  border: OutlineInputBorder(),
                ),
                maxLength: nomeMaximo,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                validator: validarNome,
                onFieldSubmitted: (_) => _salvarNome(),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _ocupado ? null : _salvarNome,
                child: const Text('Salvar nome'),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email_outlined),
              title: const Text('E-mail'),
              subtitle: Text(perfil.email ?? '—'),
            ),
            const Divider(height: 32),
            OutlinedButton.icon(
              onPressed:
                  _ocupado
                      ? null
                      : () => ref.read(authServiceProvider).signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Sair'),
            ),
            const SizedBox(height: 32),
            Text(
              'Excluir minha conta',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Apaga seu perfil, sua foto e sua participação nos grupos. '
              'As músicas e celebrações que você criou continuam nos grupos.',
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                onPressed: _ocupado ? null : _excluirConta,
                child: const Text('Excluir minha conta'),
              ),
            ),
          ],
        ),
        if (_ocupado)
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}

/// Requires typing EXCLUIR before deleting the account (requirement 6.1).
class _ConfirmarExclusaoDialog extends StatefulWidget {
  const _ConfirmarExclusaoDialog();

  @override
  State<_ConfirmarExclusaoDialog> createState() =>
      _ConfirmarExclusaoDialogState();
}

class _ConfirmarExclusaoDialogState extends State<_ConfirmarExclusaoDialog> {
  static const _palavra = 'EXCLUIR';
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pode = _controller.text.trim().toUpperCase() == _palavra;
    return AlertDialog(
      title: const Text('Excluir conta?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Esta ação não pode ser desfeita. Para confirmar, digite '
            '$_palavra abaixo.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: pode ? () => Navigator.pop(context, true) : null,
          child: const Text('Excluir'),
        ),
      ],
    );
  }
}
