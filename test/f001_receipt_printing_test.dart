import 'package:f001_receipt_printing/f001_receipt_printing_enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:f001_receipt_printing/f001_receipt_printing.dart';
import 'package:f001_receipt_printing/f001_receipt_printing_platform_interface.dart';
import 'package:f001_receipt_printing/f001_receipt_printing_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockF001ReceiptPrintingPlatform
    with MockPlatformInterfaceMixin
    implements F001ReceiptPrintingPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final F001ReceiptPrintingPlatform initialPlatform = F001ReceiptPrintingPlatform.instance;

  test('$MethodChannelF001ReceiptPrinting is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelF001ReceiptPrinting>());
  });

  test('getPlatformVersion', () async {
    F001ReceiptPrinting f001ReceiptPrintingPlugin = await F001ReceiptPrinting.initialisePrinter(paperSize: PrinterPaperSize.mm80);
    MockF001ReceiptPrintingPlatform fakePlatform = MockF001ReceiptPrintingPlatform();
    F001ReceiptPrintingPlatform.instance = fakePlatform;

    expect(await f001ReceiptPrintingPlugin.getPlatformVersion(), '42');
  });
}
