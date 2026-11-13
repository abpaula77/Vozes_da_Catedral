/// Application user profile.
class UserModel {
  final String id;
  final String nome;
  final String papel; // 'coordenador' or 'membro' — global default

  const UserModel({required this.id, required this.nome, required this.papel});

  Map<String, dynamic> toJson() => {'id': id, 'nome': nome, 'papel': papel};

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    nome: json['nome'] as String,
    papel: json['papel'] as String? ?? 'membro',
  );
}
