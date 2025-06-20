import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
// import 'package:f001_receipt_printing/f001_receipt_printing_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image/image.dart' as img;
import 'f001_receipt_printing_response.dart';
import 'f001_receipt_printing_enums.dart';
import 'f001_receipt_printing_platform_interface.dart';
import 'f001_receipt_printing_printer.dart';

class F001ReceiptPrinting {
  final FlutterBlueClassic flutterBlue = FlutterBlueClassic();

  List<BluetoothDevice> bluetoothDevices = [];
  BluetoothDevice? selectedDevice;
  BluetoothConnection? _connection;
  bool connectedToPrinter = false;

  final Generator generator;

  F001ReceiptPrinting({required this.generator, this.selectedDevice});

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
  Future<void> scanForDevices(
      Function(BluetoothDevice) onDeviceFound, {
        Duration? scanDuration,
      }) async {
    try {
      BluetoothAdapterState state = await flutterBlue.adapterStateNow;

      if (state != BluetoothAdapterState.on) {
        flutterBlue.turnOn();
        print("[Bluetooth] 🔄 Waiting for user to turn on Bluetooth...");

        // Poll for state change
        const maxWaitTime = Duration(seconds: 10);
        const pollInterval = Duration(milliseconds: 500);
        int waited = 0;

        while (state != BluetoothAdapterState.on && waited < maxWaitTime.inMilliseconds) {
          await Future.delayed(pollInterval);
          waited += pollInterval.inMilliseconds;
          state = await flutterBlue.adapterStateNow;
        }

        if (state != BluetoothAdapterState.on) {
          print("[Bluetooth] ❌ Bluetooth was not turned on in time.");
          return;
        }

        print("[Bluetooth] ✅ Bluetooth is now ON.");
      }

      bool anyDeviceFound = false;

      final scanSubscription = flutterBlue.scanResults.listen((device) {
        final deviceId = device.address ?? '';
        final alreadyExists = bluetoothDevices.any((d) => (d.address ?? '') == deviceId);

        if (!alreadyExists) {
          print("[Bluetooth] ✅ Device found: ${device.name} (${deviceId})");
          anyDeviceFound = true;
          onDeviceFound(device);
        } else {
          print("[Bluetooth] ⚠️ Duplicate ignored: ${device.name} (${deviceId})");
        }
      });

      flutterBlue.startScan();

      // Use provided duration or fallback to 5 seconds
      await Future.delayed(scanDuration ?? const Duration(seconds: 5));

      flutterBlue.stopScan();

      try {
        await scanSubscription.cancel();
        print("[Bluetooth] ✅ Scan subscription cancelled");
      } catch (e) {
        print("[Bluetooth] ❌ Scan subscription cancel error: $e");
      }

      if (anyDeviceFound) {
        print("[Bluetooth] 🎉 At least one device was found.");
      } else {
        print("[Bluetooth] ❗ No devices found during scan.");
      }
    } catch (ex, st) {
      print("[Bluetooth] ❌ Error during scan: $ex\n$st");
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
      return ReceiptPrinterResponse(actionSuccess: false, errorMessage: ex.toString());
    }
  }

  /// Disconnect from the current connected device
  Future<void> disconnectFromDevice() async {
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

      // Send bytes in chunks to printer
      int chunkSize = 1024;
      for (int i = 0; i < printData.length; i += chunkSize) {
        int end = (i + chunkSize > printData.length) ? printData.length : i + chunkSize;
        List<int> chunk = printData.sublist(i, end);
        _connection!.output.add(Uint8List.fromList(chunk));
        // Write data through the connection
        // await _connection!.write(Uint8List.fromList(chunk));
        await Future.delayed(const Duration(milliseconds: 100));
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
}