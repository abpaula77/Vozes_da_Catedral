import 'direitos_autorais.dart';
import 'song_model.dart';
import '../../../core/domain/momento_liturgico.dart';

/// Parser for the custom plain-text chord+lyric format used by Vozes da Catedral.
///
/// Format example:
/// ```
/// [TITULO]: Santo, Santo, Santo
/// [TOM]: D
/// [CATEGORIA]: santo
/// [BPM]: 80
/// [VIDEO]: https://www.youtube.com/watch?v=...
/// [LETRISTA]: Nome
/// [COMPOSITOR]: Nome
/// [EDITORA]: Nome
/// [DIREITOS]: protegida até 2086
/// [LICENCA_APP]: pendente
///
/// [ESTROFE]
/// D        F#m
/// Santo, Santo, Santo
/// G        A4  A
/// Senhor Deus do Universo
///
/// [REFRAO]
/// D        A
/// Hosana nas alturas!
/// ```
class SongParser {
  SongParser._();

  /// Section type tags recognized in the file.
  static const _sectionTags = {
    'ESTROFE',
    'REFRAO',
    'REFRÃO',
    'PONTE',
    'PRE-REFRAO',
    'PRÉ-REFRÃO',
    'INTRO',
    'OUTRO',
    'CODA',
    'VERSO',
  };

  /// Chord characters — used to detect if a line is a chord line.
  static final _chordLineRegex = RegExp(
    r'^[A-Gb#♭m7sus24dim aug/\s\d]+$',
    caseSensitive: true,
  );

  /// Parses a raw `.txt` string into a [SongContent] model.
  /// Throws [SongParseException] if required fields are missing.
  static SongContent parse(String raw) {
    final lines = raw.split('\n');

    String? titulo;
    String? tom;
    int? bpm;
    String? videoUrl;
    String? letrista;
    String? compositor;
    String? editora;
    DireitosLidos? direitos;
    StatusLicencaApp? licencaApp;
    final categorias = <String>[];
    final momentosLiturgicos = <MomentoLiturgico>[];
    final secoes = <SongSection>[];

    String? currentSectionType;
    final currentLines = <SongLine>[];
    String? pendingChordLine;

    void flushSection() {
      if (currentSectionType != null) {
        // flush any dangling chord line as a chord-only line
        if (pendingChordLine != null) {
          currentLines.add(SongLine(cifra: pendingChordLine, letra: ''));
          pendingChordLine = null;
        }
        if (currentLines.isNotEmpty) {
          secoes.add(
            SongSection(
              tipo: currentSectionType!,
              linhas: List.from(currentLines),
            ),
          );
        }
        currentLines.clear();
        currentSectionType = null;
      }
    }

    for (final rawLine in lines) {
      final line =
          rawLine.trimRight(); // preserve leading spaces for chord alignment

      // ── Header tags: [TITULO], [TOM], [CATEGORIA], [BPM] ──────────────────
      // Keys may contain accented letters ([TÍTULO], [LICENÇA_APP]).
      final headerMatch = _headerRegex.firstMatch(line);
      if (headerMatch != null) {
        final key = headerMatch.group(1)!.toUpperCase();
        final value = headerMatch.group(2)!.trim();
        switch (key) {
          case 'TITULO':
          case 'TÍTULO':
            titulo = value;
            break;
          case 'TOM':
            tom = value;
            break;
          case 'BPM':
            bpm = int.tryParse(value);
            break;
          case 'VIDEO':
            videoUrl = normalizeVideoUrl(value);
            if (videoUrl == null) {
              throw SongParseException(
                'Link de vídeo inválido: "$value". Use um endereço '
                'http:// ou https://.',
              );
            }
            break;
          // ── Authorship and rights (issue #27) ─────────────────────────────
          case 'LETRISTA':
            letrista = _textoCurto('LETRISTA', value);
            break;
          case 'COMPOSITOR':
            compositor = _textoCurto('COMPOSITOR', value);
            break;
          case 'EDITORA':
            editora = _textoCurto('EDITORA', value);
            break;
          case 'DIREITOS':
            direitos = lerDireitos(value);
            if (direitos == null) {
              throw SongParseException(
                'Valor inválido em [DIREITOS]: "$value". Use dominio-publico, '
                'protegida (opcional: "protegida até 2086") ou nao-verificado.',
              );
            }
            break;
          case 'LICENCA_APP':
          case 'LICENÇA_APP':
            licencaApp = lerLicencaApp(value);
            if (licencaApp == null) {
              throw SongParseException(
                'Valor inválido em [LICENCA_APP]: "$value". Use pendente, '
                'autorizada, nao-necessaria ou negada.',
              );
            }
            break;
          case 'CATEGORIA':
          case 'CATEGORIAS':
            // Support comma-separated categories
            categorias.addAll(
              value.split(',').map((c) => c.trim().toLowerCase()),
            );
            break;
          case 'MOMENTO':
          case 'MOMENTOS':
            for (final tag in value.split(',')) {
              final moment = MomentoLiturgico.fromTag(tag);
              if (moment == null) {
                throw SongParseException(
                  'Momento litúrgico inválido: "$tag". Use um momento '
                  'reconhecido pelo Rito Romano.',
                );
              }
              if (!momentosLiturgicos.contains(moment)) {
                momentosLiturgicos.add(moment);
              }
            }
            break;
        }
        continue;
      }

      // ── Section tags: [ESTROFE], [REFRAO], etc. ───────────────────────────
      final sectionMatch = RegExp(r'^\[([^\]]+)\]$').firstMatch(line);
      if (sectionMatch != null) {
        final tag = sectionMatch.group(1)!.trim().toUpperCase();
        if (_sectionTags.contains(tag) ||
            tag.startsWith('ESTROFE') ||
            tag.startsWith('VERSO')) {
          flushSection();
          currentSectionType = tag;
          continue;
        }
      }

      // ── Lines inside a section ─────────────────────────────────────────────
      if (currentSectionType != null) {
        if (line.isEmpty) {
          // Empty line within section: flush pending chord
          if (pendingChordLine != null) {
            currentLines.add(SongLine(cifra: pendingChordLine, letra: ''));
            pendingChordLine = null;
          }
          continue;
        }

        if (_isChordLine(line)) {
          // Flush previous pending chord (chord with no following lyric)
          if (pendingChordLine != null) {
            currentLines.add(SongLine(cifra: pendingChordLine, letra: ''));
          }
          pendingChordLine = line;
        } else {
          // Lyric line — pair with pending chord if any
          currentLines.add(SongLine(cifra: pendingChordLine, letra: line));
          pendingChordLine = null;
        }
      }
    }

    flushSection();

    if (titulo == null || titulo.isEmpty) {
      throw SongParseException(
        'Campo [TITULO] não encontrado ou vazio no arquivo.',
      );
    }

    return SongContent(
      titulo: titulo,
      tomOriginal: tom,
      bpm: bpm,
      categorias: categorias,
      momentosLiturgicos: momentosLiturgicos,
      videoUrl: videoUrl,
      letrista: letrista,
      compositor: compositor,
      editora: editora,
      statusDireitos: direitos?.status,
      direitosAte: direitos?.ate,
      statusLicencaApp: licencaApp,
      secoes: secoes,
    );
  }

  /// Header line `[CHAVE]: valor`. Same as the former `\w+` key (ASCII
  /// letters, digits, underscore) plus accented letters.
  static final _headerRegex = RegExp(r'^\[([A-Za-z0-9_À-ÿ]+)\]:\s*(.+)$');

  static const _limiteTexto = 200;

  static String _textoCurto(String campo, String valor) {
    if (valor.length > _limiteTexto) {
      throw SongParseException(
        'O campo [$campo] deve ter no máximo $_limiteTexto caracteres.',
      );
    }
    return valor;
  }

  /// Returns [value] as an absolute http(s) URL with a host, or null.
  static String? normalizeVideoUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri.toString();
  }

  /// Heuristic: a line is a chord line if it contains only chord notation characters
  /// and has at least one uppercase letter (chord root).
  static bool _isChordLine(String line) {
    if (line.trim().isEmpty) return false;
    // Must have at least one uppercase letter A-G (chord root)
    if (!RegExp(r'[A-G]').hasMatch(line)) return false;
    // Should match chord pattern — letters, numbers, symbols but no long words
    return _chordLineRegex.hasMatch(line.trim());
  }
}

/// Exception thrown when a song file cannot be parsed.
class SongParseException implements Exception {
  final String message;
  const SongParseException(this.message);

  @override
  String toString() => 'SongParseException: $message';
}
