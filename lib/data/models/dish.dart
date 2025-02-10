class Dish {
  final int? id;
  final String name; // Название блюда
  final String description; // Описание блюда
  final String cuisineType; // Тип кухни
  final String dishType; // Тип блюда (например, основное, закуска, десерт)
  final double price; // Цена блюда
  final double discountPrice; // Цена со скидкой
  final List<String> images; // Список URL или путей к изображениям

  Dish({
    this.id,
    required this.name,
    required this.description,
    required this.cuisineType,
    required this.dishType,
    required this.price,
    required this.discountPrice,
    required this.images,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'cuisineType': cuisineType,
      'dishType': dishType,
      'price': price,
      'discountPrice': discountPrice,
      'images': images.join(','), // Сохраняем изображения как строку
    };
  }

  static Dish fromMap(Map<String, dynamic> map) {
    return Dish(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      cuisineType: map['cuisineType'],
      dishType: map['dishType'],
      price: map['price'],
      discountPrice: map['discountPrice'],
      images: List<String>.from(map['images'].split(',')),
    );
  }
}
