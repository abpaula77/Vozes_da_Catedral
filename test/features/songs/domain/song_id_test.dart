import 'package:flutter_test/flutter_test.dart';
import 'package:vozes_da_catedral/features/songs/domain/song_id.dart';

void main() {
  test('generates valid UUID v4 song identifiers', () {
    final id = SongId.generate();

    expect(SongId.isUuid(id), isTrue);
    expect(id[14], '4');
  });

  test('recognizes legacy local identifiers as non-UUID', () {
    expect(SongId.isUuid('19a0f4e_local'), isFalse);
  });
}
