A simple package to connect to a Bluetooth device (printer), and print a receipt as an image based on the provided data.

## Getting started

First, initialise an instance of the [F001ReceiptPrinting] class.

```dart
class _MyAppState extends State<MyApp> {
  F001ReceiptPrinting? receiptPrinterManager;
  
  @override
  void initState() async {
    super.initState();
    
    // Creates an instance of F001ReceiptPrinting class.
    try {
      receiptPrinterManager = await F001ReceiptPrinting.initialisePrinter(paperSize: PrinterPaperSize.mm80);
    } catch (ex) {
      log("Error initialising Receipt Printer: ${ex.toString()}");
    }
  }
}
```

To display a list of any bonded Bluetooth device in your UI, you can follow this example.

```dart
class _MyAppState extends State<MyApp> {
  F001ReceiptPrinting? receiptPrinterManager;
  List<ReceiptPrintingDevice> bondedDevices = [];
  ReceiptPrintingDevice? selectedDevice;

  @override
  void initState() async {
    super.initState();
    try {
      receiptPrinterManager = await F001ReceiptPrinting.initialisePrinter(paperSize: PrinterPaperSize.mm80);
    } catch (ex) {
      log("Error initialising Receipt Printer: ${ex.toString()}");
    }

    if (receiptPrinterManager != null) {
      setState(() async {
        bondedDevices.addAll(await receiptPrinterManager!.scanForDevices());
      });
    }
  }

  Future<void> onPrinterTap({required ReceiptPrintingDevice device}) async {
    if (selectedDevice == null) {
      // First time connection.
      ReceiptPrinterResponse response = await receiptPrinterManager!.connectToDevice(device: device);
      if (response.actionSuccess) {
        selectedDevice = device;
      }
    } else if (selectedDevice?.address == device.address) {
      // Tapping on connected device.
      await receiptPrinterManager!.disconnectFromDevice();
      selectedDevice = null;
    } else {
      // Tapping on different device.
      await receiptPrinterManager!.disconnectFromDevice();
      ReceiptPrinterResponse response = await receiptPrinterManager!.connectToDevice(device: device);
      if (response.actionSuccess) {
        selectedDevice = device;
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Receipt Printing"),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(10.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bondedDevices.isEmpty
                  ? const Center(child: Text("No Devices Found", style: TextStyle(color: Colors.black, fontSize: 14)))
                  : ListView.builder(
                itemBuilder: (BuildContext listCtx, int index) {
                  return GestureDetector(
                    onTap: () async => await onPrinterTap(device: bondedDevices[index]),
                    child: ListTile(
                      title: Text(bondedDevices[index].name ?? "N/A", style: const TextStyle(color: Colors.black, fontSize: 14)),
                      subtitle: Text(bondedDevices[index].address, style: const TextStyle(color: Colors.black, fontSize: 12)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

After connecting to a Bluetooth device (printer), you can attempt to print a receipt by providing a Widget to be converted as an image.

```dart
class _MyAppState extends State<MyApp> {
  F001ReceiptPrinting? receiptPrinterManager;

  Future<void> onPrintButtonTap({required BuildContext context}) async {
    if (selectedDevice == null) {
      log("Please select a Bluetooth device before printing.");
    } else {
      // Widget value can be any Flutter widget, as long as it fits on the phone screen (like a screenshot).
      Widget receiptAsWidget = SizedBox(
        // You can test out with your own width value if you like.
        width: F001ReceiptPrinting.getWidgetWidthFromPaperSize(paperSize: PrinterPaperSize.mm80),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Text Row 1", style: TextStyle(color: Colors.black, fontSize: 14)),
            Text("Text Row 2", style: TextStyle(color: Colors.black, fontSize: 18)),
          ],
        ),
      );

      ReceiptPrinterResponse response = await receiptPrinterManager!.printReceipt(widgetToBeCaptured: receiptAsWidget, context: context);
      if (response.actionSuccess) {
        log("Printing Success.");
      } else {
        log("Error: ${response.errorMessage}");
      }
    }
  }
}
```
