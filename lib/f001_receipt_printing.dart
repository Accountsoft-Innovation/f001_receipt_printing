import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:f001_receipt_printing/f001_receipt_printing_enums.dart';
import 'package:f001_receipt_printing/f001_receipt_printing_platform_interface.dart';
import 'package:f001_receipt_printing/f001_receipt_printing_printer.dart';
import 'package:f001_receipt_printing/f001_receipt_printing_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image/image.dart' as img;

class F001ReceiptPrinting {
  final _thermalPrinterPlugin = FlutterThermalPrinter.instance;
  StreamSubscription<List<Printer>>? _printersStreamSubscription;
  List<ReceiptPrintingPrinter> bluetoothDevices = [];
  ReceiptPrintingPrinter? selectedDevice;
  
  final Generator generator;
  bool connectedToPrinter = false;

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
  ///
  /// The [bluetoothDevices] will be populated with paired devices.
  Future<List<ReceiptPrintingPrinter>> scanForDevices() async {
    _printersStreamSubscription?.cancel();
    await _thermalPrinterPlugin.getPrinters(connectionTypes: [
      ConnectionType.BLE,
    ]);
    
    _printersStreamSubscription = _thermalPrinterPlugin.devicesStream.listen((List<Printer> printers) {
      bluetoothDevices.clear();
      bluetoothDevices.addAll(printers.map((Printer printer) {
        return ReceiptPrintingPrinter.convertBluetoothDeviceToReceiptPrintingDevice(printer: printer);
      }).toList());
    });

    return bluetoothDevices;
  }

  /// Attempts to connect to a Bluetooth device based on the provided [address] value.
  ///
  /// On success, this will set the [deviceConnection] & [selectedDevice] values.
  Future<ReceiptPrinterResponse> connectToDevice({required ReceiptPrintingPrinter device}) async {
    try {
      log("[BP] Attempting to connect to device '${selectedDevice?.name ?? "NULL"}'...");
      bool connectAttempt = await _thermalPrinterPlugin.connect(device);
      connectedToPrinter = connectAttempt;
      selectedDevice = device;
      log("[BP] Connected to device: ${selectedDevice?.name ?? "NULL"}!");
      return ReceiptPrinterResponse(actionSuccess: true);
    } catch (ex) {
      log("[BP] Bluetooth device connection attempt failed: ${ex.toString()}");
      connectedToPrinter = false;
      return ReceiptPrinterResponse(actionSuccess: false, errorMessage: ex.toString());
    }
  }

  /// Disconnect from connected device.
  ///
  /// This action sets the [deviceConnection] & [selectedDevice] values into null.
  Future<void> disconnectFromDevice() async {
    if (!connectedToPrinter) {
      log("[BP] Already disconnected from Bluetooth device.");
    } else {
      _thermalPrinterPlugin.disconnect(ReceiptPrintingPrinter.convertReceiptPrintingDeviceToPrinter(receiptPrinter: selectedDevice!)).then((value) async {
        connectedToPrinter = false;
        selectedDevice = null;
        log("[BP] Disconnected from Bluetooth device.");
      });
    }
  }

  /// Prints a receipt based on the provided [Widget] data.
  ///
  /// Recommended to use a [Column] widget wrapped by a [SizedBox] widget with the [SizedBox.width] value declared.
  Future<ReceiptPrinterResponse> printReceipt({required Widget widgetToBeCaptured, required BuildContext context}) async {
    try {
      final ScreenshotController screenshotController = ScreenshotController();
      List<Uint8List> bytes = <Uint8List>[];

      await screenshotController.captureFromLongWidget(widgetToBeCaptured, delay: const Duration(seconds: 1), context: context).then((Uint8List capturedImage) {
        final img.Image image = img.decodeImage(capturedImage)!;
        bytes.add(Uint8List.fromList(generator.image(image)));
        // Add two for extra white space.
        bytes.add(Uint8List.fromList(generator.feed(1)));
        bytes.add(Uint8List.fromList(generator.feed(1)));
      });

      if (!connectedToPrinter) {
        throw Exception("Connection to Printer is not established.");
      }

      for (var line in bytes) {
        try {
          await _thermalPrinterPlugin.printImageBytes(imageBytes: line, printer: ReceiptPrintingPrinter.convertReceiptPrintingDeviceToPrinter(receiptPrinter: selectedDevice!));
          // deviceConnection?.output.add(line);
          // await deviceConnection?.output.allSent;
          await Future.delayed(const Duration(milliseconds: 200));
        } catch (e) {
          rethrow;
        }
      }

      return ReceiptPrinterResponse(actionSuccess: true);
    } catch (ex) {
      log("[BP] Unable to print receipt: ${ex.toString()}");
      return ReceiptPrinterResponse(actionSuccess: false, errorMessage: ex.toString());
    }
  }
}
