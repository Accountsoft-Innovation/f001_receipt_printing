import 'dart:developer';
import 'dart:typed_data';

<<<<<<< Updated upstream
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:f001_receipt_printing/f001_receipt_printing_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
=======
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:f001_receipt_printing/f001_receipt_printing_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
>>>>>>> Stashed changes
import 'package:screenshot/screenshot.dart';
import 'package:image/image.dart' as img;
import 'f001_receipt_printing_enums.dart';
import 'f001_receipt_printing_platform_interface.dart';
import 'f001_receipt_printing_printer.dart';

<<<<<<< Updated upstream

import 'f001_receipt_printing_enums.dart';
import 'f001_receipt_printing_platform_interface.dart';
import 'f001_receipt_printing_response.dart';

class F001ReceiptPrinting {
  FlutterBluetoothSerial bluetoothSerial = FlutterBluetoothSerial.instance;
  List<ReceiptPrintingDevice> bluetoothDevices = [];
  ReceiptPrintingDevice? selectedDevice;
  BluetoothConnection? deviceConnection;

  final Generator generator;

  F001ReceiptPrinting({required this.generator, this.selectedDevice, this.deviceConnection});
=======
class F001ReceiptPrinting {
  final FlutterBlueClassic flutterBlue = FlutterBlueClassic();

  List<BluetoothDevice> bluetoothDevices = [];
  BluetoothDevice? selectedDevice;
  BluetoothConnection? _connection;
  bool connectedToPrinter = false;

  final Generator generator;

  F001ReceiptPrinting({required this.generator, this.selectedDevice});
>>>>>>> Stashed changes

  /// Returns Plugin Version.
  Future<String?> getPlatformVersion() async {
    return await F001ReceiptPrintingPlatform.instance.getPlatformVersion();
  }

  /// Initialises Receipt Printing Manager with the provided [PrinterPaperSize] value.
  static Future<F001ReceiptPrinting> initialisePrinter({required PrinterPaperSize paperSize}) async {
    CapabilityProfile profile = await CapabilityProfile.load();
    PaperSize generatorPaperSize;

    switch (paperSize) {
      case PrinterPaperSize.mm58:
        generatorPaperSize = PaperSize.mm58;
        break;
      case PrinterPaperSize.mm80:
        generatorPaperSize = PaperSize.mm80;
        break;
    }
    return F001ReceiptPrinting(generator: Generator(generatorPaperSize, profile));
  }

  /// Get recommended widget width based on the provided [PrinterPaperSize] value.
  static double getWidgetWidthFromPaperSize({required PrinterPaperSize paperSize}) {
    switch (paperSize) {
      case PrinterPaperSize.mm58:
        return 350.0;
      case PrinterPaperSize.mm80:
        return 550.0;
    }
  }

  /// Refreshes paired Bluetooth devices list.
<<<<<<< Updated upstream
  ///
  /// The [bluetoothDevices] will be populated with paired devices.
  Future<List<ReceiptPrintingDevice>> scanForDevices() async {
    List<BluetoothDevice> pairedDevices = await bluetoothSerial.getBondedDevices();

    bluetoothDevices.clear();
    bluetoothDevices.addAll(pairedDevices.map((BluetoothDevice device) {
      return ReceiptPrintingDevice.convertBluetoothDeviceToReceiptPrintingDevice(device: device);
    }).toList());
    return bluetoothDevices;
  }

  /// Attempts to connect to a Bluetooth device based on the provided [address] value.
  ///
  /// On success, this will set the [deviceConnection] & [selectedDevice] values.
  Future<ReceiptPrinterResponse> connectToDevice({required ReceiptPrintingDevice device}) async {
    try {
      log("[BP] Attempting to connect to device '${selectedDevice?.name ?? "NULL"}'...");
      BluetoothConnection connectAttempt = await BluetoothConnection.toAddress(device.address);
      deviceConnection = connectAttempt;
      selectedDevice = device;
      log("[BP] Connected to device: ${selectedDevice?.name ?? "NULL"}!");
      return ReceiptPrinterResponse(actionSuccess: true);
    } catch (ex) {
      log("[BP] Bluetooth device connection attempt failed: ${ex.toString()}");
=======
  Future<void> scanForDevices(Function(BluetoothDevice) onDeviceFound) async {
    try {

      final state = await flutterBlue.adapterStateNow;
      if (state != BluetoothAdapterState.on) {
        flutterBlue.turnOn();
        await Future.delayed(const Duration(seconds: 2));
      }

      final scanSubscription = flutterBlue.scanResults.listen((device) {
        final deviceId = device.address ?? '';
        final alreadyExists = bluetoothDevices.any((d) => (d.address ?? '') == deviceId);
        if (!alreadyExists) {
          onDeviceFound(device);
        } else {
          log("[Bluetooth] ⚠️ Duplicate ignored: ${device.name} (${deviceId})");
        }
      });

      flutterBlue.startScan();
      await Future.delayed(const Duration(seconds: 20));

      flutterBlue.stopScan();

      try {
        await scanSubscription.cancel();
        log("[Bluetooth] Scan subscription cancelled");
      } catch (e) {
        log("[Bluetooth] Scan subscription cancel error: $e");
      }
    } catch (ex, st) {
      log("[Bluetooth] ❌ Error during scan: $ex\n$st");
    }
  }

  /// Connect to a Bluetooth classic device
  Future<ReceiptPrinterResponse> connectToDevice({required BluetoothDevice device}) async {
    try {
      log("Attempting to connect to device '${device.name ?? device.address}'...");

      // Disconnect if already connected
      if (_connection != null && connectedToPrinter) {
        await disconnectFromDevice();
      }

      _connection = await flutterBlue.connect(device.address);

      if (_connection != null && _connection!.isConnected) {
        selectedDevice = device;
        connectedToPrinter = true;
        log("Connected to device: ${device.name ?? device.address}");
        return ReceiptPrinterResponse(actionSuccess: true);
      } else {
        return ReceiptPrinterResponse(actionSuccess: false, errorMessage: "Connection failed");
      }
    } catch (ex) {
      log("Connection error: $ex");
      connectedToPrinter = false;
>>>>>>> Stashed changes
      return ReceiptPrinterResponse(actionSuccess: false, errorMessage: ex.toString());
    }
  }

  /// Disconnect from the current connected device
  Future<void> disconnectFromDevice() async {
<<<<<<< Updated upstream
    if (deviceConnection == null) {
      log("[BP] Already disconnected from Bluetooth device.");
    } else {
      await deviceConnection?.finish().then((value) async {
        deviceConnection = null;
        selectedDevice = null;
        log("[BP] Disconnected from Bluetooth device.");
      });
=======
    if (!connectedToPrinter || _connection == null) {
      log("Already disconnected.");
      return;
    }

    try {
      _connection?.dispose();
      _connection = null;
      connectedToPrinter = false;
      selectedDevice = null;
      log("Disconnected from device.");
    } catch (ex) {
      log("Error disconnecting: $ex");
>>>>>>> Stashed changes
    }
  }

  /// Prints a receipt based on the provided [Widget] data.
  Future<ReceiptPrinterResponse> printReceipt({
    required Widget widgetToBeCaptured,
    required BuildContext context,
  }) async {
    if (!connectedToPrinter || selectedDevice == null || _connection == null) {
      return ReceiptPrinterResponse(
          actionSuccess: false,
          errorMessage: "Not connected to any printer."
      );
    }

    try {
      final ScreenshotController screenshotController = ScreenshotController();
      Uint8List capturedImageBytes = await screenshotController.captureFromLongWidget(
        widgetToBeCaptured,
        delay: const Duration(seconds: 1),
        context: context,
      );

      img.Image image = img.decodeImage(capturedImageBytes)!;
      List<int> printData = generator.image(image);
      printData.addAll(generator.feed(2)); // feed a few lines after printing

<<<<<<< Updated upstream
      if (deviceConnection == null) {
        throw Exception("Connection to Printer is not established.");
      }

      for (var line in bytes) {
        try {
          deviceConnection?.output.add(line);
          await deviceConnection?.output.allSent;
          await Future.delayed(const Duration(milliseconds: 200));
        } catch (e) {
          rethrow;
        }
=======
      // Send bytes in chunks to printer
      int chunkSize = 1024;
      for (int i = 0; i < printData.length; i += chunkSize) {
        int end = (i + chunkSize > printData.length) ? printData.length : i + chunkSize;
        List<int> chunk = printData.sublist(i, end);
        _connection!.output.add(Uint8List.fromList(chunk));
        // Write data through the connection
        // await _connection!.write(Uint8List.fromList(chunk));
        await Future.delayed(const Duration(milliseconds: 100));
>>>>>>> Stashed changes
      }

      return ReceiptPrinterResponse(actionSuccess: true);
    } catch (ex) {
      log("Print error: $ex");
      return ReceiptPrinterResponse(
          actionSuccess: false,
          errorMessage: ex.toString()
      );
    }
  }
<<<<<<< Updated upstream

}
=======
}
>>>>>>> Stashed changes
