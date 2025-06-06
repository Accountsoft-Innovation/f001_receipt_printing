// import 'dart:developer';
//
// import 'package:flutter_blue_classic/flutter_blue_classic.dart';
// import 'package:stock_inquiry/f001_receipt_printing/f001_receipt_printing_printer.dart'; // Assuming Printer class is here
//
// class ReceiptPrintingPrinter extends BluetoothDevice {
//   bool? isConnected;
//
//   ReceiptPrintingPrinter({
//     required super.address,
//     super.name,
//     this.isConnected,
//   });
//
//   /// Converts a Printer object to a ReceiptPrintingPrinter
//   static ReceiptPrintingPrinter fromPrinter(ReceiptPrintingPrinter printer) {
//     return ReceiptPrintingPrinter(
//       address: printer.address,
//       name: printer.name,
//       isConnected: printer.isConnected,
//     );
//   }
//
//   /// Converts a ReceiptPrintingPrinter to a Printer object
//   static Device toPrinter(ReceiptPrintingPrinter receiptPrinter) {
//     return ReceiptPrintingPrinter(
//       address: receiptPrinter.address,
//       name: receiptPrinter.name,
//       isConnected: receiptPrinter.isConnected,
//     );
//   }
//
//   /// Logs the device details to the console
//   void logDeviceDetailsInConsole() {
//     log("Address: ${address.isNotEmpty ? address : "NULL"}");
//     log("Name: ${name ?? "NULL"}");
//     log("Is Connected: ${isConnected ?? "NULL"}");
//   }
// }
