class ReceiptPrinterResponse {
  bool actionSuccess;
  String errorMessage;

  ReceiptPrinterResponse({required this.actionSuccess, this.errorMessage = ""});
}