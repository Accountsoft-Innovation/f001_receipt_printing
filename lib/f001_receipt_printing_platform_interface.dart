import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'f001_receipt_printing_method_channel.dart';

abstract class F001ReceiptPrintingPlatform extends PlatformInterface {
  /// Constructs a F001ReceiptPrintingPlatform.
  F001ReceiptPrintingPlatform() : super(token: _token);

  static final Object _token = Object();

  static F001ReceiptPrintingPlatform _instance = MethodChannelF001ReceiptPrinting();

  /// The default instance of [F001ReceiptPrintingPlatform] to use.
  ///
  /// Defaults to [MethodChannelF001ReceiptPrinting].
  static F001ReceiptPrintingPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [F001ReceiptPrintingPlatform] when
  /// they register themselves.
  static set instance(F001ReceiptPrintingPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() async {
    return "YEET";
  }
}
