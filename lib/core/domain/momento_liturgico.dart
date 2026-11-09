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
      (moment) => moment.name == value,
      orElse: () => MomentoLiturgico.outros,
    );
  }

  static MomentoLiturgico? fromTag(String value) {
    final normalized = _normalize(value);
    for (final moment in MomentoLiturgico.values) {
      if (_normalize(moment.name) == normalized ||
          _normalize(moment.label) == normalized) {
        return moment;
      }
    }
    return null;
  }

  static String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ç', 'c');
}
