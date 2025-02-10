// import 'package:bluetooth_print/bluetooth_print_model.dart';
// import '../../data/models/order.dart';
//
// class PrinterHelper {
//   static final BlueThermalPrinter printer = BlueThermalPrinter.instance;
//
//   // Метод получения списка доступных принтеров
//   static Future<List<BluetoothDevice>> getAvailablePrinters() async {
//     return await printer.getBondedDevices();
//   }
//
//   // Метод подключения к выбранному Bluetooth-принтеру
//   static Future<void> connectToPrinter(BluetoothDevice device) async {
//     if (!(await printer.isConnected)!) {
//       await printer.connect(device);
//     }
//   }
//
//   // Метод печати чека
//   static Future<void> printReceipt(Order order) async {
//     if (!(await printer.isConnected)!) {
//       print('Принтер не подключен');
//       return;
//     }
//
//     printer.printNewLine();
//     printer.printCustom("Чек оплаты", 3, 1);
//     printer.printNewLine();
//     printer.printCustom("Столик: ${order.tableId}", 2, 0);
//     printer.printCustom("Дата: ${order.orderDateTime}", 1, 0);
//     printer.printNewLine();
//     printer.printCustom("Заказ:", 2, 0);
//
//     for (var dish in order.orderedDishes) {
//       printer.printCustom("${dish.name} - ${dish.discountPrice} ₽", 1, 0);
//     }
//
//     printer.printNewLine();
//     printer.printCustom("Статус: ${order.isPaid ? "Оплачено" : "Не оплачено"}", 2, 0);
//     printer.printNewLine();
//     printer.printCustom("Спасибо за заказ!", 2, 1);
//     printer.printNewLine();
//     printer.paperCut();
//   }
// }
