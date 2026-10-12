class PredefinedService {
  final int? id;
  final String name;
  final String description;
  final double defaultPrice;

  PredefinedService({
    this.id,
    required this.name,
    this.description = '',
    required this.defaultPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'default_price': defaultPrice,
    };
  }

  factory PredefinedService.fromMap(Map<String, dynamic> map) {
    return PredefinedService(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      defaultPrice: (map['default_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
