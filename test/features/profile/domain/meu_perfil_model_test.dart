import 'package:flutter_test/flutter_test.dart';
import 'package:vozes_da_catedral/features/profile/domain/meu_perfil_model.dart';

void main() {
  group('classificarFoto', () {
    test('recognizes the three kinds of users.foto values', () {
      expect(classificarFoto(null), TipoFoto.nenhuma);
      expect(classificarFoto('  '), TipoFoto.nenhuma);
      expect(
        classificarFoto('https://lh3.googleusercontent.com/a/x'),
        TipoFoto.google,
      );
      expect(classificarFoto('avatars/u1/f.jpg'), TipoFoto.enviada);
    });

    test('treats unknown formats as no photo', () {
      expect(classificarFoto('http://inseguro/x.png'), TipoFoto.nenhuma);
      expect(classificarFoto('u1/f.jpg'), TipoFoto.nenhuma);
    });
  });

  test('caminhoNoBucket strips the bucket prefix of uploaded photos only', () {
    expect(caminhoNoBucket('avatars/u1/f.jpg'), 'u1/f.jpg');
    expect(caminhoNoBucket('https://lh3.googleusercontent.com/a/x'), isNull);
    expect(caminhoNoBucket(null), isNull);
  });

  test('inicialDoNome', () {
    expect(inicialDoNome('maria'), 'M');
    expect(inicialDoNome('  joão'), 'J');
    expect(inicialDoNome(''), '?');
  });

  group('validarNome', () {
    test('requires 2 to 80 characters after trimming', () {
      expect(validarNome(null), isNotNull);
      expect(validarNome(' a '), isNotNull);
      expect(validarNome('Ana'), isNull);
      expect(validarNome('  Ana  '), isNull);
      expect(validarNome('x' * 80), isNull);
      expect(validarNome('x' * 81), isNotNull);
    });
  });

  group('image types', () {
    test('accepts only JPEG, PNG and WebP', () {
      expect(tipoDeImagem('foto.JPG'), 'image/jpeg');
      expect(tipoDeImagem('foto.jpeg'), 'image/jpeg');
      expect(tipoDeImagem('foto.png'), 'image/png');
      expect(tipoDeImagem('foto.webp'), 'image/webp');
      expect(tipoDeImagem('foto.gif'), isNull);
      expect(tipoDeImagem('foto.heic'), isNull);
    });

    test('maps content types to file extensions', () {
      expect(extensaoDoTipo('image/jpeg'), 'jpg');
      expect(extensaoDoTipo('image/png'), 'png');
      expect(extensaoDoTipo('image/webp'), 'webp');
    });
  });

  group('MeuPerfilModel', () {
    const google = 'https://lh3.googleusercontent.com/a/x';

    test('knows when the Google photo is in use', () {
      const perfil = MeuPerfilModel(
        id: 'u1',
        nome: 'Ana',
        foto: google,
        fotoDoGoogle: google,
      );
      expect(perfil.tipoFoto, TipoFoto.google);
      expect(perfil.usaFotoDoGoogle, isTrue);
    });

    test('an uploaded photo is not the Google photo', () {
      const perfil = MeuPerfilModel(
        id: 'u1',
        nome: 'Ana',
        foto: 'avatars/u1/f.jpg',
        fotoDoGoogle: google,
      );
      expect(perfil.tipoFoto, TipoFoto.enviada);
      expect(perfil.usaFotoDoGoogle, isFalse);
    });
  });
}
