import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:f001_receipt_printing/f001_receipt_printing_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelF001ReceiptPrinting platform = MethodChannelF001ReceiptPrinting();
  const MethodChannel channel = MethodChannel('f001_receipt_printing');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
