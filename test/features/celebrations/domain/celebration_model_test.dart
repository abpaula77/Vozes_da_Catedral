import 'package:flutter_test/flutter_test.dart';
import 'package:vozes_da_catedral/features/celebrations/domain/celebration_model.dart';

void main() {
  test('creates all 12 Roman Rite moments as empty ordered slots', () {
    final items = defaultRitoRomano('celebracao-id');

    expect(items, hasLength(12));
    expect(
      items.map((item) => item.ordem),
      orderedEquals(List.generate(12, (i) => i)),
    );
    expect(
      items.map((item) => item.momentoLiturgico),
      orderedEquals([
        MomentoLiturgico.entrada,
        MomentoLiturgico.atoPenitencial,
        MomentoLiturgico.gloria,
        MomentoLiturgico.salmoResponsorial,
        MomentoLiturgico.aclamacaoEvangelho,
        MomentoLiturgico.oferta,
        MomentoLiturgico.santo,
        MomentoLiturgico.cordeiroDeDeus,
        MomentoLiturgico.comunhao,
        MomentoLiturgico.posComunhao,
        MomentoLiturgico.consagracao,
        MomentoLiturgico.final_,
      ]),
    );
    expect(items.every((item) => item.celebracaoId == 'celebracao-id'), isTrue);
    expect(items.every((item) => item.musicaId == null), isTrue);
  });
}
