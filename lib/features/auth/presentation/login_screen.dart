import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;
  final _nomeController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      if (_isSignUp) {
        await authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          _nomeController.text.trim(),
        );
      } else {
        await authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = _friendlyError(e.toString());
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (error.contains('User already registered')) {
      return 'Este e-mail já está cadastrado. Faça login.';
    }
    if (error.contains('Email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar.';
    }
    return 'Erro ao entrar. Tente novamente.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Icon(Icons.music_note_rounded,
                        size: 64, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Vozes da Catedral',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUp ? 'Criar conta' : 'Entrar',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Nome (only on sign up)
                    if (_isSignUp) ...[
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome completo',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                        if (!v.contains('@')) return 'E-mail inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Informe a senha';
                        if (_isSignUp && v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Error message
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: theme.colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Submit button
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isSignUp ? 'Criar conta' : 'Entrar'),
                    ),

                    const SizedBox(height: 16),

                    // Toggle sign up / login
                    TextButton(
                      onPressed: () => setState(() {
                        _isSignUp = !_isSignUp;
                        _errorMessage = null;
                      }),
                      child: Text(
                        _isSignUp
                            ? 'Já tem conta? Entrar'
                            : 'Não tem conta? Criar conta',
                      ),
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
