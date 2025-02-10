import 'package:flutter/material.dart';

import '../../data/models/dish.dart';
import '../../database/daatabase_helper.dart';

class AddOrEditDishScreen extends StatefulWidget {
  final Dish? dish;

  AddOrEditDishScreen({this.dish});

  @override
  _AddOrEditDishScreenState createState() => _AddOrEditDishScreenState();
}

class _AddOrEditDishScreenState extends State<AddOrEditDishScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _cuisineTypeController = TextEditingController();
  final _dishTypeController = TextEditingController();
  List<String> _images = [];

  @override
  void initState() {
    super.initState();
    if (widget.dish != null) {
      // Если мы редактируем блюдо, заполняем поля
      _nameController.text = widget.dish!.name;
      _descriptionController.text = widget.dish!.description;
      _priceController.text = widget.dish!.price.toString();
      _discountPriceController.text = widget.dish!.discountPrice.toString();
      _cuisineTypeController.text = widget.dish!.cuisineType;
      _dishTypeController.text = widget.dish!.dishType;
      _images = widget.dish!.images;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dish == null ? 'Добавить блюдо' : 'Редактировать блюдо'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Название блюда'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Описание блюда'),
            ),
            TextField(
              controller: _cuisineTypeController,
              decoration: InputDecoration(labelText: 'Тип кухни'),
            ),
            TextField(
              controller: _dishTypeController,
              decoration: InputDecoration(labelText: 'Тип блюда'),
            ),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Цена'),
            ),
            TextField(
              controller: _discountPriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Цена со скидкой'),
            ),
            // UI для добавления изображений (просто пример)
            ElevatedButton(
              onPressed: () async {
                // Реализуйте логику выбора изображений
                final newImages = await selectImages();
                setState(() {
                  _images.addAll(newImages);
                });
              },
              child: Text('Добавить изображения'),
            ),
            ElevatedButton(
              onPressed: () {
                final dish = Dish(
                  id: widget.dish?.id, // Используем ID для обновления
                  name: _nameController.text,
                  description: _descriptionController.text,
                  cuisineType: _cuisineTypeController.text,
                  dishType: _dishTypeController.text,
                  price: double.parse(_priceController.text),
                  discountPrice: double.parse(_discountPriceController.text),
                  images: _images,
                );
                if (widget.dish == null) {
                  // Добавляем новое блюдо
                  DatabaseHelper.insertDish(dish);
                } else {
                  // Обновляем существующее блюдо
                  DatabaseHelper.updateDish(dish);
                }
                Navigator.pop(context);
              },
              child: Text(widget.dish == null ? 'Добавить блюдо' : 'Обновить блюдо'),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<String>> selectImages() async {
    // Реализуйте логику выбора изображений (например, с помощью image_picker)
    return []; // Возвращаем список выбранных изображений
  }
}
