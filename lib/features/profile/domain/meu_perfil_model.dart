/// User profile domain (issue #42). See `.kiro/specs/perfil-usuario/`.
library;

/// Storage bucket for uploaded photos. `users.foto` stores uploaded photos as
/// `avatars/<user_id>/<file>`; the object name inside the bucket omits the
/// bucket prefix.
const bucketAvatars = 'avatars';

/// Kind of value stored in `users.foto`.
enum TipoFoto { nenhuma, google, enviada }

TipoFoto classificarFoto(String? foto) {
  final valor = foto?.trim() ?? '';
  if (valor.isEmpty) return TipoFoto.nenhuma;
  if (valor.startsWith('$bucketAvatars/')) return TipoFoto.enviada;
  if (valor.startsWith('https://')) return TipoFoto.google;
  // Unknown formats are treated as no photo (shows the initial).
  return TipoFoto.nenhuma;
}

/// Object name inside the bucket for an uploaded photo, or null.
String? caminhoNoBucket(String? foto) {
  if (classificarFoto(foto) != TipoFoto.enviada) return null;
  return foto!.trim().substring(bucketAvatars.length + 1);
}

/// First letter of a name, used when there is no photo.
String inicialDoNome(String nome) {
  final limpo = nome.trim();
  return limpo.isEmpty ? '?' : limpo[0].toUpperCase();
}

const nomeMinimo = 2;
const nomeMaximo = 80;

/// Returns an error message, or null when the name is valid (requirement 1.3).
String? validarNome(String? nome) {
  final tamanho = (nome ?? '').trim().length;
  if (tamanho < nomeMinimo) {
    return 'Informe pelo menos $nomeMinimo letras.';
  }
  if (tamanho > nomeMaximo) {
    return 'Use no máximo $nomeMaximo caracteres.';
  }
  return null;
}

/// Content type accepted by the bucket for a file name, or null.
String? tipoDeImagem(String nomeArquivo) {
  final nome = nomeArquivo.toLowerCase();
  if (nome.endsWith('.jpg') || nome.endsWith('.jpeg')) return 'image/jpeg';
  if (nome.endsWith('.png')) return 'image/png';
  if (nome.endsWith('.webp')) return 'image/webp';
  return null;
}

/// Extension used in the stored file name for a content type.
String extensaoDoTipo(String contentType) => switch (contentType) {
  'image/png' => 'png',
  'image/webp' => 'webp',
  _ => 'jpg',
};

/// Same limit as the bucket (512 KB).
const tamanhoMaximoFoto = 512 * 1024;

/// The signed-in user's own profile.
class MeuPerfilModel {
  final String id;
  final String nome;
  final String? foto;

  /// From the login session; never read from the database.
  final String? email;

  /// Google photo of the account, when the user signed in with Google.
  final String? fotoDoGoogle;

  const MeuPerfilModel({
    required this.id,
    required this.nome,
    this.foto,
    this.email,
    this.fotoDoGoogle,
  });

  TipoFoto get tipoFoto => classificarFoto(foto);

  bool get usaFotoDoGoogle =>
      fotoDoGoogle != null && foto?.trim() == fotoDoGoogle;
}
