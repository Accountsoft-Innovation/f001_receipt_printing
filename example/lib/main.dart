import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import 'package:f001_receipt_printing/f001_receipt_printing.dart';
import 'package:f001_receipt_printing/f001_receipt_printing_enums.dart';
import 'package:f001_receipt_printing/f001_receipt_printing_response.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Receipt Printing Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ReceiptPrinterDemo(),
    );
  }
}

class ReceiptPrinterDemo extends StatefulWidget {
  const ReceiptPrinterDemo({super.key});

  @override
  State<ReceiptPrinterDemo> createState() => _ReceiptPrinterDemoState();
}

class _ReceiptPrinterDemoState extends State<ReceiptPrinterDemo> {
  late F001ReceiptPrinting _printer;
  bool _isLoading = false;
  String _status = "Not connected";
  List<String> _deviceNames = [];
  List<String> _foundAddresses = [];

  @override
  void initState() {
    super.initState();
    _initializePrinter();
  }

  Future<void> _initializePrinter() async {
    _printer = await F001ReceiptPrinting.initialisePrinter(
      paperSize: PrinterPaperSize.mm58,
    );
  }

  Future<void> _scanDevices() async {
    setState(() {
      _isLoading = true;
      _status = "Scanning...";
      _deviceNames.clear();
      _foundAddresses.clear();
    });

    await Future.delayed(const Duration(seconds: 1), () async {
      // Check if Bluetooth is turned on
      final FlutterBlueClassic flutterBlue = FlutterBlueClassic();
      final state = await flutterBlue.adapterStateNow;
      if (state != BluetoothAdapterState.on) {
        log("Please Turn On Bluetooth connection");
        return;
      }
    });

    await _printer.scanForDevices((device) {
      final deviceId = device.address ?? '';
      final displayName = device.name ?? device.address;

      if (!_foundAddresses.contains(deviceId)) {
        log("[Scan] New device found: $displayName");
        setState(() {
          _deviceNames.add(displayName);
          _foundAddresses.add(deviceId);
          _status = "Found ${_deviceNames.length} device(s)";
        });
      } else {
        log("[Scan] Duplicate ignored: $displayName");
      }
    });

    setState(() {
      _isLoading = false;
      if (_deviceNames.isEmpty) _status = "No devices found";
    });
  }

  Future<void> _connectToFirstDevice() async {
    setState(() {
      _isLoading = true;
      _status = "Connecting...";
    });

    List<BluetoothDevice> devices = [];
    await _printer.scanForDevices((device) {
      if (!devices.any((d) => d.address == device.address)) {
        devices.add(device);
      }
    });

    if (devices.isEmpty) {
      setState(() {
        _status = "No devices to connect.";
        _isLoading = false;
      });
      return;
    }

    final response = await _printer.connectToDevice(device: devices.first);
    setState(() {
      _status = response.actionSuccess
          ? "Connected to: ${devices.first.name ?? devices.first.address}"
          : "Connection failed: ${response.errorMessage}";
      _isLoading = false;
    });
  }

  Future<void> _disconnectFromDevice() async {
    await _printer.disconnectFromDevice();
    setState(() => _status = "Disconnected from printer.");
  }

  Future<void> _printReceipt() async {
    final response = await _printer.printReceipt(
      widgetToBeCaptured: _buildReceiptWidget(),
      context: context,
    );

    setState(() {
      _status = response.actionSuccess
          ? "Receipt sent to printer"
          : "Print failed: ${response.errorMessage}";
    });
  }

  Widget _buildReceiptWidget() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(10),
      width: F001ReceiptPrinting.getWidgetWidthFromPaperSize(
        paperSize: PrinterPaperSize.mm58,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("🏪 My Store", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text("1x Apple  .............. \$2.00"),
          Text("2x Banana .............. \$3.00"),
          Divider(),
          Text("Total: \$5.00", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text("Thank you! 😊"),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Receipt Printer Example")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Status: $_status", style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _scanDevices,
                child: const Text("🔍 Scan Devices"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _connectToFirstDevice,
                child: const Text("🔌 Connect to First Device"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _disconnectFromDevice,
                child: const Text("❌ Disconnect"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _printReceipt,
                child: const Text("🖨️ Print Sample Receipt"),
              ),
              const SizedBox(height: 30),
              const Text("Devices Found:", style: TextStyle(fontWeight: FontWeight.bold)),
              ..._deviceNames.map((name) => Text(name)).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
