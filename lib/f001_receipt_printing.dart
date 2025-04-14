import 'dart:developer';
import 'dart:typed_data';

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:f001_receipt_printing/f001_receipt_printing_enums.dart';
import 'package:f001_receipt_printing/f001_receipt_printing_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image/image.dart' as img;

import 'f001_receipt_printing_platform_interface.dart';

class F001ReceiptPrinting {
  FlutterBluetoothSerial bluetoothSerial = FlutterBluetoothSerial.instance;
  List<BluetoothDevice> bluetoothDevices = [];
  BluetoothDevice? selectedDevice;
  BluetoothConnection? deviceConnection;

  final Generator generator;

  F001ReceiptPrinting({required this.generator, this.selectedDevice, this.deviceConnection});

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

  /// Refreshes paired Bluetooth devices list.
  ///
  /// The [bluetoothDevices] will be populated with paired devices.
  Future<List<BluetoothDevice>> scanForDevices() async {
    List<BluetoothDevice> pairedDevices = await bluetoothSerial.getBondedDevices();
    bluetoothDevices.clear();
    bluetoothDevices.addAll(pairedDevices);
    return bluetoothDevices;
  }

  /// Attempts to connect to a Bluetooth device based on the provided [address] value.
  ///
  /// On success, this will set the [deviceConnection] & [selectedDevice] values.
  Future<ReceiptPrinterResponse> connectToDevice({required BluetoothDevice device}) async {
    try {
      log("[BP] Attempting to connect to device '${selectedDevice?.name ?? "NULL"}'...");
      BluetoothConnection connectAttempt = await BluetoothConnection.toAddress(device.address);
      deviceConnection = connectAttempt;
      selectedDevice = device;
      log("[BP] Connected to device: ${selectedDevice?.name ?? "NULL"}!");
      return ReceiptPrinterResponse(actionSuccess: true);
    } catch (ex) {
      log("[BP] Bluetooth device connection attempt failed: ${ex.toString()}");
      return ReceiptPrinterResponse(actionSuccess: false, errorMessage: ex.toString());
    }
  }

  /// Disconnect from connected device.
  ///
  /// This action sets the [deviceConnection] & [selectedDevice] values into null.
  Future<void> disconnectFromDevice() async {
    if (deviceConnection == null) {
      log("[BP] Already disconnected from Bluetooth device.");
    } else {
      await deviceConnection?.finish().then((value) async {
        deviceConnection = null;
        selectedDevice = null;
        log("[BP] Disconnected from Bluetooth device.");
      });
    }
  }

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
      }

      return ReceiptPrinterResponse(actionSuccess: true);
    } catch (ex) {
      log("[BP] Unable to print receipt: ${ex.toString()}");
      return ReceiptPrinterResponse(actionSuccess: false, errorMessage: ex.toString());
    }
  }

}
