import 'package:flutter_test/flutter_test.dart';
import 'package:vozes_da_catedral/features/songs/domain/song_model.dart';
import 'package:vozes_da_catedral/features/songs/domain/song_parser.dart';

void main() {
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
}
