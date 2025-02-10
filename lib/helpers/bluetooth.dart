import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../../data/models/order.dart';

class BluetoothPrinterHelper {
  static final BlueThermalPrinter printer = BlueThermalPrinter.instance;

  // Получение списка доступных Bluetooth-принтеров
  static Future<List<BluetoothDevice>> getAvailablePrinters() async {
    return await printer.getBondedDevices();
  }

  // Подключение к принтеру
  static Future<void> connectToPrinter(BluetoothDevice device) async {
    if (!(await printer.isConnected)!) {
      await printer.connect(device);
    }
  }

  // Печать чека
  static Future<void> printReceipt(Order order) async {
    if (!(await printer.isConnected)!) {
      print('Принтер не подключен');
      return;
    }

    printer.printNewLine();
    printer.printCustom("Чек оплаты", 3, 1);
    printer.printNewLine();
    printer.printCustom("Столик: ${order.tableId}", 2, 0);
    printer.printCustom("Дата: ${order.orderDateTime}", 1, 0);
    printer.printNewLine();
    printer.printCustom("Заказ:", 2, 0);

    for (var dish in order.orderedDishes) {
      printer.printCustom("${dish.name} - ${dish.discountPrice} ₽", 1, 0);
    }

    printer.printNewLine();
    printer.printCustom("Статус: ${order.isPaid ? "Оплачено" : "Не оплачено"}", 2, 0);
    printer.printNewLine();
    printer.printCustom("Спасибо за заказ!", 2, 1);
    printer.printNewLine();
    printer.paperCut();
  }
}
