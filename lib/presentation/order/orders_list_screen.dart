import 'package:flutter/material.dart';

import '../../data/models/order.dart';
import '../../database/daatabase_helper.dart';
import 'order_details.dart';

class OrdersListScreen extends StatelessWidget {
  final String waiterId;

  OrdersListScreen({required this.waiterId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Order>>(
      future: DatabaseHelper.getOrdersByWaiter(waiterId, []), // Пример, все блюда нужно передать из БД
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          final orders = snapshot.data!;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return ListTile(
                title: Text('Столик: ${order.tableId}'),
                subtitle: Text('Дата: ${order.orderDateTime}'),
                trailing: Text(order.isPaid ? 'Оплачено' : 'Не оплачено'),
                onTap: () {
                  // Переход к подробной информации о заказе
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailsScreen(order: order),
                    ),
                  );
                },
              );
            },
          );
        } else {
          return Center(child: Text('Нет заказов.'));
        }
      },
    );
  }
}
