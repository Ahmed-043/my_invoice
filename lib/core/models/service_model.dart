class ServiceItem {
  final int? id;
  final int invoiceId;
  final String serviceName;
  final int quantity;
  final double price;
  final double total;

  ServiceItem({
    this.id,
    required this.invoiceId,
    required this.serviceName,
    required this.quantity,
    required this.price,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "invoice_id": invoiceId,
      "service_name": serviceName,
      "quantity": quantity,
      "price": price,
      "total": total,
    };
  }

  factory ServiceItem.fromMap(Map<String, dynamic> map) {
    return ServiceItem(
      id: map['id'],
      invoiceId: map['invoice_id'],
      serviceName: map['service_name'],
      quantity: map['quantity'],
      price: map['price'],
      total: map['total'],
    );
  }
}
