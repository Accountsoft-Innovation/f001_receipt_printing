import 'dart:developer';

import 'package:flutter_thermal_printer/utils/printer.dart';

class ReceiptPrintingPrinter extends Printer {
  ReceiptPrintingPrinter({
    super.address,
    super.name,
    super.connectionType,
    super.isConnected,
    super.vendorId,
    super.productId,
  });

  static ReceiptPrintingPrinter convertBluetoothDeviceToReceiptPrintingDevice({required Printer printer}) {
    return ReceiptPrintingPrinter(
      address: printer.address,
      name: printer.name,
      connectionType: printer.connectionType,
      isConnected: printer.isConnected,
      vendorId: printer.vendorId,
      productId: printer.productId,
    );
  }

  static Printer convertReceiptPrintingDeviceToPrinter({required ReceiptPrintingPrinter receiptPrinter}) {
    return Printer(
      address: receiptPrinter.address,
      name: receiptPrinter.name,
      connectionType: receiptPrinter.connectionType,
      isConnected: receiptPrinter.isConnected,
      vendorId: receiptPrinter.vendorId,
      productId: receiptPrinter.productId,
    );
  }
  
  /// Simply outputs the Bluetooth Device details in the console log.
  void logDeviceDetailsInConsole() {
    log("Address: ${address ?? "NULL"}");
    log("Name: ${name ?? "NULL"}");
    log("Connection Type: ${connectionType?.name ?? "NULL"}");
    log("Is Connected: ${isConnected?.toString() ?? "NULL"}");
    log("Vendor ID: ${vendorId ?? "NULL"}");
    log("Product ID: ${productId ?? "NULL"}");
  }

}