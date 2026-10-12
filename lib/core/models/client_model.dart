class Client {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String companyName;
  final String address;

  Client({
    this.id,
    required this.name,
    this.email = '',
    this.phone = '',
    this.companyName = '',
    this.address = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'company_name': companyName,
      'address': address,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      companyName: map['company_name'] as String? ?? '',
      address: map['address'] as String? ?? '',
    );
  }
}
