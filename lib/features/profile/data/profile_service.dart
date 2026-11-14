import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/presentation/auth_provider.dart';
import '../../songs/domain/song_id.dart';
import '../domain/meu_perfil_model.dart';
import 'foto_resolver.dart';

/// Thrown for problems the user can fix (wrong file type, file too large).
class PerfilException implements Exception {
  final String mensagem;
  const PerfilException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Profile operations (issue #42). Online only; rules are enforced by the
/// Supabase RPCs and Storage policies described in the spec design.
class ProfileService {
  final Ref _ref;
  ProfileService(this._ref);

  SupabaseClient get _supabase => _ref.read(supabaseProvider);

  User get _usuario {
    final user = _supabase.auth.currentUser;
    if (user == null) throw const PerfilException('Faça login novamente.');
    return user;
  }

  /// Google photo of the signed-in account, if any.
  ///
  /// Read from the session's user metadata and, as a fallback, from the
  /// linked Google identity (accounts created by e-mail and linked to Google
  /// later may only have it there).
  String? get fotoDoGoogle {
    final user = _supabase.auth.currentUser;
    final fontes = <Map<String, dynamic>?>[
      user?.userMetadata,
      for (final identidade in user?.identities ?? const <UserIdentity>[])
        if (identidade.provider == 'google') identidade.identityData,
    ];
    for (final fonte in fontes) {
      for (final chave in ['avatar_url', 'picture']) {
        final valor = fonte?[chave];
        if (valor is String && valor.startsWith('https://')) return valor;
      }
    }
    return null;
  }

  Future<MeuPerfilModel?> carregar() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    final row =
        await _supabase
            .from('users')
            .select('id, nome, foto')
            .eq('id', user.id)
            .maybeSingle();
    if (row == null) return null;
    return MeuPerfilModel(
      id: row['id'] as String,
      nome: row['nome'] as String,
      foto: row['foto'] as String?,
      email: user.email,
      fotoDoGoogle: fotoDoGoogle,
    );
  }

  Future<void> atualizarNome(String nome) async {
    await _supabase.rpc('atualizar_meu_nome', params: {'p_nome': nome.trim()});
    _atualizado();
  }

  Future<void> usarFotoDoGoogle() async {
    final foto = fotoDoGoogle;
    if (foto == null) {
      throw const PerfilException('Esta conta não tem foto do Google.');
    }
    await _definirFoto(foto);
  }

  Future<void> removerFoto() => _definirFoto(null);

  /// Uploads a picked image (already resized by the picker) and makes it the
  /// profile photo. The previous uploaded file is deleted (requirement 2.6).
  Future<void> enviarFoto(XFile arquivo) async {
    final user = _usuario;
    final contentType =
        _tipoAceito(arquivo.mimeType) ?? tipoDeImagem(arquivo.name);
    if (contentType == null) {
      throw const PerfilException('Escolha uma imagem JPEG, PNG ou WebP.');
    }
    final bytes = await arquivo.readAsBytes();
    if (bytes.length > tamanhoMaximoFoto) {
      throw const PerfilException(
        'A imagem é grande demais. Escolha outra foto.',
      );
    }

    final caminho =
        '${user.id}/${SongId.generate()}.${extensaoDoTipo(contentType)}';
    final bucket = _supabase.storage.from(bucketAvatars);
    await bucket.uploadBinary(
      caminho,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: false),
    );

    try {
      await _definirFoto('$bucketAvatars/$caminho');
    } catch (_) {
      // Do not leave an unused file behind.
      await _apagarArquivos([caminho]);
      rethrow;
    }
  }

  /// Groups where the user is the only coordinator (deletion is blocked).
  Future<List<String>> gruposImpedindoExclusao() async {
    final rows =
        await _supabase.rpc('grupos_impedindo_exclusao') as List<dynamic>;
    return rows
        .map((row) => (row as Map<String, dynamic>)['nome'] as String)
        .toList();
  }

  /// Deletes the uploaded photos, then the account, then signs out.
  /// If deleting the photos fails, the account is deleted anyway: the files
  /// become unreachable (design decision 2).
  Future<void> excluirConta() async {
    final user = _usuario;
    try {
      final arquivos = await _supabase.storage
          .from(bucketAvatars)
          .list(path: user.id);
      await _apagarArquivos([
        for (final arquivo in arquivos) '${user.id}/${arquivo.name}',
      ]);
    } catch (_) {
      // Continue with the deletion.
    }

    await _supabase.rpc('excluir_minha_conta');

    try {
      await _supabase.auth.signOut();
    } catch (_) {
      // The account no longer exists; the local session is cleared anyway.
    }
  }

  Future<void> _definirFoto(String? foto) async {
    final anterior =
        await _supabase.rpc('definir_minha_foto', params: {'p_foto': foto})
            as String?;
    final caminhoAnterior = caminhoNoBucket(anterior);
    if (caminhoAnterior != null && anterior != foto) {
      await _apagarArquivos([caminhoAnterior]);
    }
    _atualizado();
  }

  Future<void> _apagarArquivos(List<String> caminhos) async {
    if (caminhos.isEmpty) return;
    try {
      await _supabase.storage.from(bucketAvatars).remove(caminhos);
    } catch (_) {
      // Best effort: an orphan file is only visible to who could see the
      // photo, and becomes unreachable if the account is deleted.
    }
  }

  void _atualizado() {
    _ref.read(fotoResolverProvider).limpar();
    _ref.invalidate(meuPerfilProvider);
    _ref.invalidate(currentUserProvider);
  }

  static String? _tipoAceito(String? mimeType) => switch (mimeType) {
    'image/jpeg' || 'image/png' || 'image/webp' => mimeType,
    _ => null,
  };
}

final profileServiceProvider = Provider<ProfileService>(ProfileService.new);

final meuPerfilProvider = FutureProvider.autoDispose<MeuPerfilModel?>(
  (ref) => ref.watch(profileServiceProvider).carregar(),
);

/// Turns an error from the profile flow into a message for the user.
String mensagemErroPerfil(Object error) {
  if (error is PerfilException) return error.mensagem;
  if (error is PostgrestException && error.message.trim().isNotEmpty) {
    return error.message;
  }
  if (error is StorageException) {
    final status = error.statusCode ?? '';
    if (status == '413' || error.message.toLowerCase().contains('size')) {
      return 'A imagem é grande demais. Escolha outra foto.';
    }
    if (status == '415' || error.message.toLowerCase().contains('mime')) {
      return 'Escolha uma imagem JPEG, PNG ou WebP.';
    }
  }
  return 'Não foi possível concluir. Verifique a conexão com a internet e '
      'tente novamente.';
}
