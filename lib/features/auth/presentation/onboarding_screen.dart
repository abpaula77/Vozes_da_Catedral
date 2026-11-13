import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../profile/data/profile_service.dart';
import '../../profile/domain/meu_perfil_model.dart';
import '../../profile/presentation/user_avatar.dart';
import 'auth_provider.dart';

/// First access: confirms the name (and the Google photo, if any).
///
/// The former "Coordenador / Membro" choice was removed (issue #42): it was
/// stored in users.papel but never used; roles are per group.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(supabaseProvider).auth.currentUser;
    final meta = user?.userMetadata;
    final sugestao =
        (meta?['nome'] ?? meta?['full_name'] ?? user?.email?.split('@').first)
            as String?;
    _nomeController = TextEditingController(text: sugestao?.trim() ?? '');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final service = ref.read(profileServiceProvider);
    try {
      await service.atualizarNome(_nomeController.text);
      if (service.fotoDoGoogle != null) {
        try {
          await service.usarFotoDoGoogle();
        } catch (_) {
          // The photo is optional; it can be set later in "Meu perfil".
        }
      }
      if (mounted) context.go(AppRoutes.groups);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensagemErroPerfil(e))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fotoDoGoogle = ref.read(profileServiceProvider).fotoDoGoogle;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _nomeController,
                        builder:
                            (_, value, __) => UserAvatar(
                              nome: value.text,
                              foto: fotoDoGoogle,
                              radius: 40,
                            ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Bem-vindo ao\nVozes da Catedral',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Como você quer ser chamado nos grupos?',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: nomeMaximo,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      validator: validarNome,
                      onFieldSubmitted: (_) => _confirm(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Você pode mudar o nome e a foto depois, em Meu perfil.',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isLoading ? null : _confirm,
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Continuar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
