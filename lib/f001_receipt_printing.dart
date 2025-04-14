
import 'f001_receipt_printing_platform_interface.dart';

class F001ReceiptPrinting {
  Future<String?> getPlatformVersion() async {
    return await F001ReceiptPrintingPlatform.instance.getPlatformVersion();
  }
}
