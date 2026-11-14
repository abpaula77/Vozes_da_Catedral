import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vozes_da_catedral/features/songs/domain/song_model.dart';
import 'package:vozes_da_catedral/features/songs/domain/song_parser.dart';

void main() {
  test('parses a song with chords and liturgical moment metadata', () {
    const raw = '''
[TITULO]: Canção de teste
[TOM]: D
[MOMENTO]: consagracao

[ESTROFE 1]
D          A
Linha de teste
G          D
Outra linha de teste

[REFRAO]
G          D
Refrão de teste
''';

    final song = SongParser.parse(raw);

    expect(song.titulo, 'Canção de teste');
    expect(song.tomOriginal, 'D');
    expect(song.momentosLiturgicos.map((moment) => moment.name), [
      'consagracao',
    ]);
    expect(
      jsonDecode(
        jsonEncode(
          song.momentosLiturgicos.map((moment) => moment.name).toList(),
        ),
      ),
      ['consagracao'],
    );
    expect(song.secoes, hasLength(2));
    expect(song.secoes.first.linhas.first.cifra, 'D          A');
  });

  test('parses the documented TXT song format', () {
    const raw = '''
[TITULO]: Nome da música
[TOM]: D
[CATEGORIA]: entrada, advento
[MOMENTO]: entrada, comunhao
[BPM]: 92

[ESTROFE 1]
D                 A
Primeira linha da letra
G                 D
Segunda linha da letra

[REFRAO]
G              D
Refrão da música
A              D
Refrão continua aqui

[ESTROFE 2]
D                 A
Outra estrofe
G                 D
Mais uma linha
''';

    final song = SongParser.parse(raw);

    expect(song.titulo, 'Nome da música');
    expect(song.tomOriginal, 'D');
    expect(song.bpm, 92);
    expect(song.categorias, ['entrada', 'advento']);
    expect(song.momentosLiturgicos.map((moment) => moment.name), [
      'entrada',
      'comunhao',
    ]);
    expect(
      SongContent.fromJson(song.toJson()).momentosLiturgicos,
      song.momentosLiturgicos,
    );
    final legacyContent = Map<String, dynamic>.from(song.toJson())
      ..remove('momentosLiturgicos');
    expect(SongContent.fromJson(legacyContent).momentosLiturgicos, isEmpty);
    expect(song.secoes.map((section) => section.tipo), [
      'ESTROFE 1',
      'REFRAO',
      'ESTROFE 2',
    ]);
    expect(song.secoes.first.linhas.first.cifra, 'D                 A');
    expect(song.secoes.first.linhas.first.letra, 'Primeira linha da letra');
  });

  test('rejects unknown liturgical moment tags', () {
    expect(
      () => SongParser.parse('[TITULO]: Música\n[MOMENTO]: casamento'),
      throwsA(
        isA<SongParseException>().having(
          (error) => error.message,
          'message',
          contains('Momento litúrgico inválido'),
        ),
      ),
    );
  });

  group('video link', () {
    const body = '[ESTROFE]\nD\nLinha\n';

    test('parses [VIDEO] and keeps it through a JSON round trip', () {
      final song = SongParser.parse(
        '[TITULO]: A\n[VIDEO]: https://youtu.be/abc123\n$body',
      );
      expect(song.videoUrl, 'https://youtu.be/abc123');
      final decoded = SongContent.fromJson(
        jsonDecode(jsonEncode(song.toJson())) as Map<String, dynamic>,
      );
      expect(decoded.videoUrl, 'https://youtu.be/abc123');
    });

    test('songs without [VIDEO] and legacy JSON have no video', () {
      expect(SongParser.parse('[TITULO]: A\n$body').videoUrl, isNull);
      final legacy = SongContent.fromJson({
        'titulo': 'A',
        'categorias': [],
        'secoes': [],
      });
      expect(legacy.videoUrl, isNull);
    });

    test('rejects links that are not absolute http(s) URLs', () {
      for (final bad in [
        'javascript:alert(1)',
        'youtube.com/watch?v=1',
        'ftp://x.com/a',
        'not a url',
      ]) {
        expect(
          () => SongParser.parse('[TITULO]: A\n[VIDEO]: $bad\n$body'),
          throwsA(isA<SongParseException>()),
          reason: bad,
        );
      }
    });
  });
}
