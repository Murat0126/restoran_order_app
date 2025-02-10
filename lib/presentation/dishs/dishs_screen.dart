import 'package:flutter/material.dart';
import '../../data/models/dish.dart';
import '../../database/daatabase_helper.dart';
import '../order/add_order_edit_screen.dart';
import '../user_profile.dart';

class DishesListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Dish>>(
      future: DatabaseHelper.getDishes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          final dishes = snapshot.data!;

          // Группируем блюда по типу кухни и типу блюда
          final groupedByCuisine = <String, Map<String, List<Dish>>>{};

          // Группируем блюда по типу кухни и типу блюда
          for (var dish in dishes) {
            if (!groupedByCuisine.containsKey(dish.cuisineType)) {
              groupedByCuisine[dish.cuisineType] = {};
            }

            if (!groupedByCuisine[dish.cuisineType]!.containsKey(dish.dishType)) {
              groupedByCuisine[dish.cuisineType]![dish.dishType] = [];
            }

            groupedByCuisine[dish.cuisineType]![dish.dishType]!.add(dish);
          }

          // Строим список с группировкой
          return Scaffold(
            appBar: AppBar(
              title: Text('Список блюд'),
              actions: [
                IconButton(
                  icon: Icon(Icons.account_circle),
                  onPressed: () {
                    // Логика для перехода к экрану профиля пользователя
                    // Например, можно открыть экран профиля
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfileScreen(), // Экран профиля
                      ),
                    );
                  },
                ),
              ],
            ),
            body: ListView.builder(
              itemCount: groupedByCuisine.keys.length,
              itemBuilder: (context, cuisineIndex) {
                final cuisineType = groupedByCuisine.keys.elementAt(cuisineIndex);
                final dishesByCuisine = groupedByCuisine[cuisineType]!;

                return ExpansionTile(
                  title: Text(cuisineType),
                  children: dishesByCuisine.keys.map((dishType) {
                    final dishesByDishType = dishesByCuisine[dishType]!;

                    return ExpansionTile(
                      title: Text(dishType),
                      children: dishesByDishType.map((dish) {
                        return ListTile(
                          title: Text(dish.name),
                          subtitle: Text(dish.description),
                          trailing: Text('${dish.price} ₽'),
                          onTap: () {
                            // Переход к экрану редактирования блюда
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddOrEditDishScreen(dish: dish),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    );
                  }).toList(),
                );
              },
            ),
          );
        } else {
          return Center(child: Text('No dishes available'));
        }
      },
    );
  }
}
