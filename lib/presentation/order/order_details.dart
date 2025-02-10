import 'package:flutter/material.dart';
import '../../data/models/order.dart';
import '../../helpers/bluetooth.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Order order;

  OrderDetailsScreen({required this.order});

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  BluetoothDevice? selectedPrinter;

  Future<void> _selectPrinter() async {
    List<BluetoothDevice> devices = await BluetoothPrinterHelper.getAvailablePrinters();
    if (devices.isNotEmpty) {
      setState(() {
        selectedPrinter = devices.first;
      });
      await BluetoothPrinterHelper.connectToPrinter(selectedPrinter!);
    }
  }

  Future<void> _printReceipt() async {
    if (selectedPrinter == null) {
      await _selectPrinter();
    }
    await BluetoothPrinterHelper.printReceipt(widget.order);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Детали заказа')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Столик: ${widget.order.tableId}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Дата: ${widget.order.orderDateTime}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            Text('Заказанные блюда:', style: TextStyle(fontSize: 18)),
            ...widget.order.orderedDishes.map((dish) {
              return ListTile(
                title: Text(dish.name),
                subtitle: Text(dish.description),
                trailing: Text('${dish.discountPrice} ₽'),
              );
            }).toList(),
            SizedBox(height: 16),
            Text('Статус оплаты: ${widget.order.isPaid ? "Оплачено" : "Не оплачено"}'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _printReceipt,
              child: Text('Распечатать чек'),
            ),
          ],
        ),
      ),
    );
  }
}
