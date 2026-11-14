import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vozes_da_catedral/features/songs/domain/song_parser.dart';
import 'package:vozes_da_catedral/features/songs/presentation/autoria_direitos_card.dart';

void main() {
  const raw = '''
[TITULO]: Da cepa brotou a rama
[LETRISTA]: Dom Carlos Alberto Navarro
[COMPOSITOR]: Pe. Waldeci Farias
[EDITORA]: Edições CNBB / Paulus
[DIREITOS]: Protegida (até 2086)
[LICENCA_APP]: pendente

[ESTROFE]
D        A
Primeira linha da letra
''';

  Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('card lists every filled-in field', (tester) async {
    await tester.pumpWidget(
      app(AutoriaDireitosCard(song: SongParser.parse(raw))),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Autoria e direitos'), findsOneWidget);
    for (final trecho in [
      'Dom Carlos Alberto Navarro',
      'Pe. Waldeci Farias',
      'Edições CNBB / Paulus',
      'Protegida (até 2086)',
      'Pendente de autorização',
    ]) {
      expect(
        find.textContaining(trecho, findRichText: true),
        findsOneWidget,
        reason: trecho,
      );
    }
  });

  testWidgets('says "Não informados." when nothing is filled in', (
    tester,
  ) async {
    final song = SongParser.parse('[TITULO]: A\n[ESTROFE]\nD\nLinha\n');
    await tester.pumpWidget(app(AutoriaDireitosCard(song: song)));
    expect(find.text('Não informados.'), findsOneWidget);
  });

  testWidgets('menu dialog shows the title and the data, and closes', (
    tester,
  ) async {
    final song = SongParser.parse(raw);
    await tester.pumpWidget(
      app(
        Builder(
          builder:
              (context) => TextButton(
                onPressed: () => mostrarAutoriaDireitos(context, song),
                child: const Text('abrir'),
              ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Autoria e direitos'), findsOneWidget);
    expect(find.text('Da cepa brotou a rama'), findsOneWidget);
    expect(
      find.textContaining('Pe. Waldeci Farias', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();
    expect(find.text('Autoria e direitos'), findsNothing);
  });
}
