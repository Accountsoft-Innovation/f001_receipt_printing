import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'f001_receipt_printing_platform_interface.dart';

/// An implementation of [F001ReceiptPrintingPlatform] that uses method channels.
class MethodChannelF001ReceiptPrinting extends F001ReceiptPrintingPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('f001_receipt_printing');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
