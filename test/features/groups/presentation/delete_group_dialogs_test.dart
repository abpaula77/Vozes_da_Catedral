import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vozes_da_catedral/features/groups/domain/group_model.dart';
import 'package:vozes_da_catedral/features/groups/presentation/delete_group_dialogs.dart';

Future<void> abrir(WidgetTester tester, Widget dialog) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder:
            (context) => Scaffold(
              body: TextButton(
                onPressed:
                    () => showDialog<void>(
                      context: context,
                      builder: (_) => dialog,
                    ),
                child: const Text('abrir'),
              ),
            ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

FilledButton botao(WidgetTester tester, String texto) => tester.widget(
  find.ancestor(of: find.text(texto), matching: find.byType(FilledButton)),
);

final botaoCopiar = find.ancestor(
  of: find.text('Copiar para outro grupo'),
  matching: find.byWidgetPredicate((w) => w is OutlinedButton),
);

void main() {
  test('nomeConfere ignores case and spaces at the ends', () {
    expect(nomeConfere('  coral 19H ', 'Coral 19h'), isTrue);
    expect(nomeConfere('Coral 19', 'Coral 19h'), isFalse);
    expect(nomeConfere('', 'Coral 19h'), isFalse);
  });

  testWidgets('Excluir is enabled only with the group name', (tester) async {
    await abrir(tester, const ConfirmarExclusaoDialog(nomeGrupo: 'Coral 19h'));

    expect(botao(tester, 'Excluir').onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Coral');
    await tester.pump();
    expect(botao(tester, 'Excluir').onPressed, isNull);

    await tester.enterText(find.byType(TextField), ' coral 19H ');
    await tester.pump();
    expect(botao(tester, 'Excluir').onPressed, isNotNull);
  });

  testWidgets('copy button is disabled after copying once', (tester) async {
    var copias = 0;
    await abrir(
      tester,
      ResumoExclusaoDialog(
        nomeGrupo: 'Coral 19h',
        carregar:
            () async => const ResumoExclusao(
              membros: 3,
              musicas: 10,
              musicasExclusivas: 2,
              celebracoes: 1,
              solicitacoesPendentes: 0,
            ),
        copiar: () async {
          copias++;
          return '2 músicas e 1 celebração copiadas para Coral 10h.';
        },
      ),
    );

    expect(find.text('Músicas: 10 (2 só existem neste grupo)'), findsOneWidget);
    final copiar = botaoCopiar;
    expect(tester.widget<OutlinedButton>(copiar).onPressed, isNotNull);

    await tester.tap(copiar);
    await tester.pumpAndSettle();

    expect(copias, 1);
    expect(tester.widget<OutlinedButton>(copiar).onPressed, isNull);
    expect(
      find.text('2 músicas e 1 celebração copiadas para Coral 10h.'),
      findsOneWidget,
    );
  });

  testWidgets('copy stays available when the user cancels the destination', (
    tester,
  ) async {
    await abrir(
      tester,
      ResumoExclusaoDialog(
        nomeGrupo: 'Coral 19h',
        carregar:
            () async => const ResumoExclusao(
              membros: 1,
              musicas: 0,
              musicasExclusivas: 0,
              celebracoes: 2,
              solicitacoesPendentes: 0,
            ),
        copiar: () async => null,
      ),
    );

    final copiar = botaoCopiar;
    await tester.tap(copiar);
    await tester.pumpAndSettle();

    expect(tester.widget<OutlinedButton>(copiar).onPressed, isNotNull);
  });

  testWidgets('no copy button when there is nothing exclusive', (tester) async {
    await abrir(
      tester,
      ResumoExclusaoDialog(
        nomeGrupo: 'Coral 19h',
        carregar:
            () async => const ResumoExclusao(
              membros: 1,
              musicas: 4,
              musicasExclusivas: 0,
              celebracoes: 0,
              solicitacoesPendentes: 1,
            ),
        copiar: () async => null,
      ),
    );

    expect(find.text('Copiar para outro grupo'), findsNothing);
    expect(botao(tester, 'Continuar').onPressed, isNotNull);
  });
}
