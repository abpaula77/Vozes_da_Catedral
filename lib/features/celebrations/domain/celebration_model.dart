/// Liturgical moments of the Roman Rite (Rito Romano).
/// Order follows the standard Mass structure.
enum MomentoLiturgico {
  entrada('Entrada'),
  atoPenitencial('Ato Penitencial'),
  gloria('Glória'),
  salmoResponsorial('Salmo Responsorial'),
  aclamacaoEvangelho('Aclamação ao Evangelho'),
  oferta('Oferta / Ofertório'),
  santo('Santo'),
  cordeiroDeDeus('Cordeiro de Deus'),
  comunhao('Comunhão'),
  posComunhao('Pós-Comunhão / Meditação'),
  consagracao('Consagração / Canto Mariano'),
  final_('Final / Envio'),
  outros('Outros');

  final String label;
  const MomentoLiturgico(this.label);

  static MomentoLiturgico fromString(String value) {
    return MomentoLiturgico.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MomentoLiturgico.outros,
    );
  }
}

/// Domain model for a celebration (missa).
class CelebracaoModel {
  final String id;
  final String grupoId;
  final String titulo;
  final DateTime dataHora;
  final String criadoPor;
  final List<ItemCelebracaoModel> itens;
  final DateTime updatedAt;

  const CelebracaoModel({
    required this.id,
    required this.grupoId,
    required this.titulo,
    required this.dataHora,
    required this.criadoPor,
    required this.itens,
    required this.updatedAt,
  });
}

/// A single item in a celebration — one liturgical moment slot.
class ItemCelebracaoModel {
  final String id;
  final String celebracaoId;
  final String? musicaId;
  final int ordem;
  final MomentoLiturgico momentoLiturgico;
  final String? observacao;

  const ItemCelebracaoModel({
    required this.id,
    required this.celebracaoId,
    this.musicaId,
    required this.ordem,
    required this.momentoLiturgico,
    this.observacao,
  });
}

/// Factory: create a default Rito Romano celebration structure (empty slots).
List<ItemCelebracaoModel> defaultRitoRomano(String celebracaoId) {
  final momentos = [
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
  ];

  return momentos.asMap().entries.map((entry) {
    return ItemCelebracaoModel(
      id: '${celebracaoId}_${entry.key}',
      celebracaoId: celebracaoId,
      musicaId: null,
      ordem: entry.key,
      momentoLiturgico: entry.value,
      observacao: null,
    );
  }).toList();
}
