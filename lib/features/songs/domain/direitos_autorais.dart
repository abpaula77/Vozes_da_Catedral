/// Song authorship and rights metadata (issue #27).
///
/// Informational only: nothing in the app is blocked by these values. They
/// help coordinators keep track of authors and licenses of the shared catalog.
/// See `docs/direitos-autorais.md`.
library;

/// Copyright status of the work (`[DIREITOS]` in the TXT header).
enum StatusDireitos {
  dominioPublico('dominio-publico', 'Domínio público'),
  protegida('protegida', 'Protegida'),
  naoVerificado('nao-verificado', 'Não verificado');

  /// Value written in the TXT header and stored in the song JSON.
  final String valor;
  final String rotulo;
  const StatusDireitos(this.valor, this.rotulo);

  static StatusDireitos? fromValor(Object? valor) {
    for (final status in values) {
      if (status.valor == valor) return status;
    }
    return null;
  }
}

/// Authorization to use the song in the app (`[LICENCA_APP]`).
enum StatusLicencaApp {
  pendente('pendente', 'Pendente de autorização'),
  autorizada('autorizada', 'Autorizada'),
  naoNecessaria('nao-necessaria', 'Não necessária'),
  negada('negada', 'Negada');

  final String valor;
  final String rotulo;
  const StatusLicencaApp(this.valor, this.rotulo);

  static StatusLicencaApp? fromValor(Object? valor) {
    for (final status in values) {
      if (status.valor == valor) return status;
    }
    return null;
  }
}

/// Result of parsing `[DIREITOS]`: the status and, for protected works, the
/// optional last year of protection (e.g. `protegida até 2086`).
typedef DireitosLidos = ({StatusDireitos status, int? ate});

/// Lowercases, removes Portuguese accents and turns spaces, underscores and
/// parentheses into hyphens, so `Domínio Público`, `dominio_publico` and
/// `dominio-publico` are the same value, and `Protegida (até 2086)` is read
/// as `protegida-ate-2086`.
String _normalizar(String valor) {
  const acentos = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'é': 'e',
    'ê': 'e',
    'í': 'i',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ü': 'u',
    'ç': 'c',
  };
  final minusculo = valor.trim().toLowerCase();
  final semAcento = minusculo.split('').map((c) => acentos[c] ?? c).join();
  return semAcento
      .replaceAll(RegExp(r'[\s_()]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

final _protegidaComAno = RegExp(r'^protegida(?:-ate)?-?(\d{4})$');

/// Parses a `[DIREITOS]` value; returns null when it is not recognized.
DireitosLidos? lerDireitos(String valor) {
  final normalizado = _normalizar(valor);
  final comAno = _protegidaComAno.firstMatch(normalizado);
  if (comAno != null) {
    final ano = int.parse(comAno.group(1)!);
    if (ano < 1900 || ano > 2300) return null;
    return (status: StatusDireitos.protegida, ate: ano);
  }
  final status = StatusDireitos.fromValor(normalizado);
  return status == null ? null : (status: status, ate: null);
}

/// Parses a `[LICENCA_APP]` value; returns null when it is not recognized.
StatusLicencaApp? lerLicencaApp(String valor) =>
    StatusLicencaApp.fromValor(_normalizar(valor));

/// Text shown for the copyright status, e.g. `Protegida (até 2086)`.
String descreverDireitos(StatusDireitos status, int? ate) =>
    status == StatusDireitos.protegida && ate != null
        ? '${status.rotulo} (até $ate)'
        : status.rotulo;
