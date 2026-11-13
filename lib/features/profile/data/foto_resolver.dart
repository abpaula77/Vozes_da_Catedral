import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/presentation/auth_provider.dart';
import '../domain/meu_perfil_model.dart';

/// Turns a `users.foto` value into an image URL (issue #42).
///
/// - Google photos are used directly.
/// - Uploaded photos live in a private bucket: a 1-hour signed URL is
///   requested. Requests made in the same frame (e.g. a whole member list)
///   are batched into a single call, and URLs are kept in memory while the
///   app is open.
/// - Any failure resolves to null, so the UI shows the initial (3.4).
class FotoResolver {
  FotoResolver(this._client);

  final SupabaseClient Function() _client;

  static const _validadeSegundos = 3600;
  // Refresh a little before the signed URL expires.
  static const _validadeCache = Duration(minutes: 55);

  final _cache = <String, ({String url, DateTime expira})>{};
  final _pendentes = <String, Completer<String?>>{};
  Timer? _agendado;

  Future<String?> resolver(String? foto) {
    switch (classificarFoto(foto)) {
      case TipoFoto.nenhuma:
        return Future.value();
      case TipoFoto.google:
        return Future.value(foto!.trim());
      case TipoFoto.enviada:
        final caminho = caminhoNoBucket(foto)!;
        final emCache = _cache[caminho];
        if (emCache != null && DateTime.now().isBefore(emCache.expira)) {
          return Future.value(emCache.url);
        }
        final pendente = _pendentes.putIfAbsent(caminho, Completer.new);
        _agendado ??= Timer(Duration.zero, _buscarLote);
        return pendente.future;
    }
  }

  /// Forgets cached URLs, e.g. after the user changes their own photo.
  void limpar() => _cache.clear();

  Future<void> _buscarLote() async {
    _agendado = null;
    final lote = Map.of(_pendentes);
    _pendentes.clear();
    if (lote.isEmpty) return;

    final caminhos = lote.keys.toList();
    try {
      final resultados = await _client().storage
          .from(bucketAvatars)
          .createSignedUrlsResult(caminhos, _validadeSegundos);
      final expira = DateTime.now().add(_validadeCache);
      for (final (indice, resultado) in resultados.indexed) {
        if (resultado is! SignedUrlSuccess) continue;
        // One result per requested path, in order; prefer the returned path.
        final caminho =
            resultado.path.isNotEmpty
                ? resultado.path
                : (indice < caminhos.length ? caminhos[indice] : '');
        _cache[caminho] = (url: resultado.signedUrl, expira: expira);
        lote.remove(caminho)?.complete(resultado.signedUrl);
      }
    } catch (_) {
      // Offline or not allowed: fall through and show the initial.
    }
    for (final completer in lote.values) {
      if (!completer.isCompleted) completer.complete(null);
    }
  }
}

final fotoResolverProvider = Provider<FotoResolver>(
  (ref) => FotoResolver(() => ref.read(supabaseProvider)),
);

/// Image URL for a `users.foto` value; null shows the initial.
final fotoUrlProvider = FutureProvider.autoDispose.family<String?, String>(
  (ref, foto) => ref.watch(fotoResolverProvider).resolver(foto),
);
