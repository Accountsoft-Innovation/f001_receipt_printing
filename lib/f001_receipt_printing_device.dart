import 'dart:developer';

import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';

class ReceiptPrintingDevice extends BluetoothDevice {
  ReceiptPrintingDevice({
    super.name,
    required super.address,
    super.type,
    super.isConnected,
    super.bondState,
  });

  static ReceiptPrintingDevice convertBluetoothDeviceToReceiptPrintingDevice({required BluetoothDevice device}) {
    return ReceiptPrintingDevice(
      name: device.name,
      address: device.address,
      type: device.type,
      isConnected: device.isConnected,
      bondState: device.bondState,
    );
  }
  
  /// Simply outputs the Bluetooth Device details in the console log.
  void logDeviceDetailsInConsole() {
    log("Address: $address");
    log("Name: $name");
    log("Type: ${type.stringValue}");
    log("Is Connected: ${isConnected.toString()}");
  }

}