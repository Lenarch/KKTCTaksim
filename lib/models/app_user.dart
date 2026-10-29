/// Giriş yapmış kullanıcı. Kimliği telefon numarasıyla doğrulanır.
class AppUser {
  final String id;
  final String phone;

  /// Kayıtta girilen ad; telefonla doğrudan giriş yapanlarda henüz olmayabilir.
  final String? name;

  const AppUser({required this.id, required this.phone, this.name});

  AppUser copyWith({String? name}) => AppUser(id: id, phone: phone, name: name ?? this.name);

  Map<String, dynamic> toJson() => {'id': id, 'phone': phone, 'name': name};

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        phone: json['phone'] as String,
        name: json['name'] as String?,
      );
}
