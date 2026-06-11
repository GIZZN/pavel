class PropertyModel {
  final int? id;
  final int userId;
  final String title;
  final String description;
  final String location;
  final double price;
  final double area;
  final int rooms;
  final String floor;
  final String propertyType; // 'apartment', 'house', 'commercial', 'land'
  final String? imageUrl; // base64
  final DateTime createdAt;
  final bool isPremium;

  PropertyModel({
    this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.location,
    required this.price,
    required this.area,
    required this.rooms,
    required this.floor,
    required this.propertyType,
    this.imageUrl,
    DateTime? createdAt,
    this.isPremium = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'location': location,
      'price': price,
      'area': area,
      'rooms': rooms,
      'floor': floor,
      'property_type': propertyType,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'is_premium': isPremium,
    };
  }

  factory PropertyModel.fromMap(Map<String, dynamic> map) {
    return PropertyModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      location: map['location'] as String,
      price: (map['price'] as num).toDouble(),
      area: (map['area'] as num).toDouble(),
      rooms: map['rooms'] as int,
      floor: map['floor'] as String,
      propertyType: map['property_type'] as String,
      imageUrl: map['image_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      isPremium: map['is_premium'] as bool? ?? false,
    );
  }
}
