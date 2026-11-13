import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vozes_da_catedral/features/groups/data/solicitacoes_provider.dart';
import 'package:vozes_da_catedral/features/groups/domain/solicitacao_model.dart';

void main() {
  group('StatusSolicitacao.fromString', () {
    test('parses every status returned by the RPCs', () {
      expect(
        StatusSolicitacao.fromString('pendente'),
        StatusSolicitacao.pendente,
      );
      expect(
        StatusSolicitacao.fromString('aprovada'),
        StatusSolicitacao.aprovada,
      );
      expect(
        StatusSolicitacao.fromString('recusada'),
        StatusSolicitacao.recusada,
      );
      expect(
        StatusSolicitacao.fromString('cancelada'),
        StatusSolicitacao.cancelada,
      );
    });

    test('returns null for missing or unknown values', () {
      expect(StatusSolicitacao.fromString(null), isNull);
      expect(StatusSolicitacao.fromString('outro'), isNull);
    });
  });

  group('GrupoAbertoModel', () {
    test('parses an open group without a request', () {
      final grupo = GrupoAbertoModel.fromJson({
        'id': 'g1',
        'nome': 'Coral 19h',
        'descricao': null,
        'meu_status': null,
        'pode_solicitar_em': null,
      });

      expect(grupo.nome, 'Coral 19h');
      expect(grupo.descricao, isNull);
      expect(grupo.meuStatus, isNull);
      expect(grupo.podeSolicitar(), isTrue);
    });

    test('cannot request while a request is pending', () {
      final grupo = GrupoAbertoModel.fromJson({
        'id': 'g1',
        'nome': 'Coral',
        'meu_status': 'pendente',
        'pode_solicitar_em': null,
      });

      expect(grupo.meuStatus, StatusSolicitacao.pendente);
      expect(grupo.podeSolicitar(), isFalse);
    });

    test('respects the 7-day wait after a rejection', () {
      final grupo = GrupoAbertoModel.fromJson({
        'id': 'g1',
        'nome': 'Coral',
        'meu_status': 'recusada',
        'pode_solicitar_em': '2026-11-20T13:00:00+00:00',
      });

      expect(grupo.meuStatus, StatusSolicitacao.recusada);
      expect(grupo.podeSolicitar(DateTime.utc(2026, 11, 19, 12)), isFalse);
      expect(grupo.podeSolicitar(DateTime.utc(2026, 11, 20, 13)), isTrue);
      expect(grupo.podeSolicitar(DateTime.utc(2026, 11, 21)), isTrue);
    });
  });

  group('MinhaSolicitacaoModel', () {
    test('parses a pending request, which can be cancelled', () {
      final solicitacao = MinhaSolicitacaoModel.fromJson({
        'id': 's1',
        'grupo_id': 'g1',
        'grupo_nome': 'Coral',
        'status': 'pendente',
        'mensagem': 'Sou tenor',
        'criada_em': '2026-11-13T10:00:00+00:00',
        'pode_solicitar_em': null,
      });

      expect(solicitacao.status, StatusSolicitacao.pendente);
      expect(solicitacao.mensagem, 'Sou tenor');
      expect(solicitacao.criadaEm, DateTime.utc(2026, 11, 13, 10));
      expect(solicitacao.podeCancelar, isTrue);
    });

    test('a rejected request cannot be cancelled and has an end date', () {
      final solicitacao = MinhaSolicitacaoModel.fromJson({
        'id': 's1',
        'grupo_id': 'g1',
        'grupo_nome': 'Coral',
        'status': 'recusada',
        'mensagem': null,
        'criada_em': '2026-11-13T10:00:00+00:00',
        'pode_solicitar_em': '2026-11-20T10:00:00+00:00',
      });

      expect(solicitacao.podeCancelar, isFalse);
      expect(solicitacao.podeSolicitarEm, DateTime.utc(2026, 11, 20, 10));
    });
  });

  group('SolicitacaoPendenteModel', () {
    test('parses name, photo and message', () {
      final pendente = SolicitacaoPendenteModel.fromJson({
        'id': 's1',
        'user_id': 'u1',
        'nome': 'maria',
        'foto': 'https://lh3.googleusercontent.com/a/foto',
        'mensagem': 'Sou soprano',
        'criada_em': '2026-11-13T10:00:00+00:00',
      });

      expect(pendente.foto, startsWith('https://'));
      expect(pendente.mensagem, 'Sou soprano');
      expect(pendente.inicial, 'M');
    });

    test('treats blank photo and message as absent', () {
      final pendente = SolicitacaoPendenteModel.fromJson({
        'id': 's1',
        'user_id': 'u1',
        'nome': '  ',
        'foto': '',
        'mensagem': '   ',
        'criada_em': '2026-11-13T10:00:00+00:00',
      });

      expect(pendente.foto, isNull);
      expect(pendente.mensagem, isNull);
      expect(pendente.inicial, '?');
    });
  });

  test('formatarData uses DD/MM/AAAA', () {
    expect(formatarData(DateTime(2026, 3, 5, 23, 59)), '05/03/2026');
  });

  group('mensagemErroSolicitacao', () {
    test('shows the RPC message to the user', () {
      const error = PostgrestException(
        message: 'Você já faz parte deste grupo.',
        code: 'P0001',
      );
      expect(mensagemErroSolicitacao(error), 'Você já faz parte deste grupo.');
    });

    test('falls back to a connection message for other errors', () {
      expect(
        mensagemErroSolicitacao(Exception('Failed host lookup')),
        contains('internet'),
      );
    });
  });
}
