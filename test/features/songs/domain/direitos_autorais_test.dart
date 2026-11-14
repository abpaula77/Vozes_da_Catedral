import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vozes_da_catedral/features/songs/domain/direitos_autorais.dart';
import 'package:vozes_da_catedral/features/songs/domain/song_model.dart';
import 'package:vozes_da_catedral/features/songs/domain/song_parser.dart';

void main() {
  const body = '[ESTROFE]\nD\nLinha\n';

  group('lerDireitos', () {
    test('accepts the three values, with or without accents', () {
      expect(
        lerDireitos('dominio-publico')?.status,
        StatusDireitos.dominioPublico,
      );
      expect(
        lerDireitos('Domínio Público')?.status,
        StatusDireitos.dominioPublico,
      );
      expect(
        lerDireitos('nao_verificado')?.status,
        StatusDireitos.naoVerificado,
      );
      expect(
        lerDireitos('Não verificado')?.status,
        StatusDireitos.naoVerificado,
      );
      expect(lerDireitos('protegida'), (
        status: StatusDireitos.protegida,
        ate: null,
      ));
    });

    test('reads the optional last year of protection', () {
      for (final valor in [
        'protegida até 2086',
        'Protegida (até 2086)',
        'protegida ate 2086',
        'protegida 2086',
      ]) {
        expect(lerDireitos(valor), (
          status: StatusDireitos.protegida,
          ate: 2086,
        ), reason: valor);
      }
    });

    test('rejects unknown values and absurd years', () {
      for (final valor in ['livre', 'protegida até 86', 'protegida até 9999']) {
        expect(lerDireitos(valor), isNull, reason: valor);
      }
    });
  });

  test('lerLicencaApp accepts the four values', () {
    expect(lerLicencaApp('pendente'), StatusLicencaApp.pendente);
    expect(lerLicencaApp('Autorizada'), StatusLicencaApp.autorizada);
    expect(lerLicencaApp('não necessária'), StatusLicencaApp.naoNecessaria);
    expect(lerLicencaApp('nao-necessaria'), StatusLicencaApp.naoNecessaria);
    expect(lerLicencaApp('negada'), StatusLicencaApp.negada);
    expect(lerLicencaApp('talvez'), isNull);
  });

  test('descreverDireitos', () {
    expect(
      descreverDireitos(StatusDireitos.protegida, 2086),
      'Protegida (até 2086)',
    );
    expect(descreverDireitos(StatusDireitos.protegida, null), 'Protegida');
    expect(
      descreverDireitos(StatusDireitos.dominioPublico, null),
      'Domínio público',
    );
  });

  group('parser', () {
    const cabecalho = '''
[TITULO]: Da cepa brotou a rama
[LETRISTA]: Dom Carlos Alberto Navarro
[COMPOSITOR]: Pe. Waldeci Farias
[EDITORA]: Edições CNBB / Paulus
[DIREITOS]: Protegida (até 2086)
[LICENCA_APP]: pendente
''';

    test('reads authorship and rights and keeps them in a JSON round trip', () {
      final song = SongParser.parse('$cabecalho$body');
      expect(song.letrista, 'Dom Carlos Alberto Navarro');
      expect(song.compositor, 'Pe. Waldeci Farias');
      expect(song.editora, 'Edições CNBB / Paulus');
      expect(song.statusDireitos, StatusDireitos.protegida);
      expect(song.direitosAte, 2086);
      expect(song.statusLicencaApp, StatusLicencaApp.pendente);
      expect(song.temAutoriaOuDireitos, isTrue);
      // The lyrics are not affected by the new header lines.
      expect(song.secoes.single.linhas.single.letra, 'Linha');

      final decoded = SongContent.fromJson(
        jsonDecode(jsonEncode(song.toJson())) as Map<String, dynamic>,
      );
      expect(decoded.letrista, song.letrista);
      expect(decoded.statusDireitos, StatusDireitos.protegida);
      expect(decoded.direitosAte, 2086);
      expect(decoded.statusLicencaApp, StatusLicencaApp.pendente);
    });

    test('accepts accented header keys', () {
      final song = SongParser.parse(
        '[TÍTULO]: A\n[LICENÇA_APP]: negada\n$body',
      );
      expect(song.titulo, 'A');
      expect(song.statusLicencaApp, StatusLicencaApp.negada);
    });

    test('songs without the fields and legacy JSON stay valid', () {
      final song = SongParser.parse('[TITULO]: A\n$body');
      expect(song.temAutoriaOuDireitos, isFalse);
      expect(song.statusLicencaApp, isNull);

      final legacy = SongContent.fromJson({
        'titulo': 'A',
        'categorias': [],
        'secoes': [],
      });
      expect(legacy.temAutoriaOuDireitos, isFalse);
    });

    test('unknown stored values are treated as not informed', () {
      final content = SongContent.fromJson({
        'titulo': 'A',
        'categorias': [],
        'secoes': [],
        'direitos': 'valor-futuro',
        'licencaApp': 'outro',
      });
      expect(content.statusDireitos, isNull);
      expect(content.statusLicencaApp, isNull);
    });

    test('rejects invalid values with a clear message', () {
      expect(
        () => SongParser.parse('[TITULO]: A\n[DIREITOS]: livre\n$body'),
        throwsA(
          isA<SongParseException>().having(
            (e) => e.message,
            'message',
            contains('[DIREITOS]'),
          ),
        ),
      );
      expect(
        () => SongParser.parse('[TITULO]: A\n[LICENCA_APP]: talvez\n$body'),
        throwsA(
          isA<SongParseException>().having(
            (e) => e.message,
            'message',
            contains('[LICENCA_APP]'),
          ),
        ),
      );
      expect(
        () => SongParser.parse('[TITULO]: A\n[EDITORA]: ${'x' * 201}\n$body'),
        throwsA(isA<SongParseException>()),
      );
    });
  });
}
