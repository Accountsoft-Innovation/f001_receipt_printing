class BluetoothPrinterResponse {
  bool actionSuccess;
  String errorMessage;

  BluetoothPrinterResponse({required this.actionSuccess, this.errorMessage = ""});
}