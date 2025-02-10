import 'package:flutter/material.dart';

class MenuScreen extends StatelessWidget {
  final List<String> menuItems = ['Pizza', 'Burger', 'Pasta', 'Salad'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Menu')),
      body: ListView.builder(
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(menuItems[index]),
            onTap: () {
              // Добавить блюдо в заказ
            },
          );
        },
      ),
    );
  }
}
