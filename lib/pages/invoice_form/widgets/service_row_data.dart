import 'package:flutter/material.dart';

class ServiceRowData {
  final nameController = TextEditingController();
  final quantityController = TextEditingController(text: "1");
  final priceController = TextEditingController(text: "0");
  final FocusNode focusNode = FocusNode();
  bool showAddButton = false;
  double total = 0;

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    priceController.dispose();
    focusNode.dispose();
  }
}
