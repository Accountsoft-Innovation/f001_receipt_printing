import 'dart:developer';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class ReceiptPrintingDevice extends BluetoothDevice{
  ReceiptPrintingDevice({
    String? name,
    required String address,
    BluetoothDeviceType type = BluetoothDeviceType.unknown,
    bool isConnected = false,
    BluetoothBondState bondState = BluetoothBondState.unknown,
  }) : super(
    name: name,
    address: address,
    type: type,
    isConnected: isConnected,
    bondState: bondState,
  );

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