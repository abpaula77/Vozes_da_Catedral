import '../../../core/domain/momento_liturgico.dart';

export '../../../core/domain/momento_liturgico.dart';

/// Liturgical moments of the Roman Rite (Rito Romano).
/// Order follows the standard Mass structure.
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
