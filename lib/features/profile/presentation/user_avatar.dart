import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/foto_resolver.dart';
import '../domain/meu_perfil_model.dart';

/// Round avatar showing a user's photo, or the initial of the name when there
/// is no photo, it is still loading, or it fails to load (requirement 3.4).
class UserAvatar extends ConsumerWidget {
  final String nome;

  /// Raw `users.foto` value (Google URL or `avatars/...` path).
  final String? foto;
  final double radius;

  const UserAvatar({
    super.key,
    required this.nome,
    this.foto,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valor = foto;
    final url =
        valor == null || classificarFoto(valor) == TipoFoto.nenhuma
            ? null
            : ref.watch(fotoUrlProvider(valor)).valueOrNull;

    return Semantics(
      label: 'Foto de $nome',
      image: true,
      child: CircleAvatar(
        radius: radius,
        foregroundImage: url == null ? null : NetworkImage(url),
        onForegroundImageError: url == null ? null : (_, __) {},
        child: Text(
          inicialDoNome(nome),
          style: TextStyle(fontSize: radius * 0.8),
        ),
      ),
    );
  }
}
