class Invoice {
  final int? id;
  final String clientName;
  final String yourName;
  final String brandName;
  final String issuedDate;
  final String dueDate;
  final String currencySymbol;
  final String currencyCode;
  final double discount;
  final double subtotal;
  final double total;
  final double paidAmount;          // ← NEW FIELD
  final String paymentMethod;
  final String accountNo;
  final String email;
  final String phone;
  final String status;
  final String penaltyType;
  final double penaltyValue;
  final String notes;
  final String createdAt;

  Invoice({
    this.id,
    required this.clientName,
    required this.yourName,
    required this.brandName,
    required this.issuedDate,
    required this.dueDate,
    required this.currencySymbol,
    required this.currencyCode,
    required this.discount,
    required this.subtotal,
    required this.total,
    this.paidAmount = 0.0,           // ← default 0
    required this.paymentMethod,
    required this.accountNo,
    required this.email,
    required this.phone,
    required this.status,
    required this.penaltyType,
    required this.penaltyValue,
    required this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "client_name": clientName,
      "your_name": yourName,
      "brand_name": brandName,
      "issued_date": issuedDate,
      "due_date": dueDate,
      "currency_symbol": currencySymbol,
      "currency_code": currencyCode,
      "discount": discount,
      "subtotal": subtotal,
      "total": total,
      "paid_amount": paidAmount,                // ← added
      "payment_method": paymentMethod,
      "account_no": accountNo,
      "email": email,
      "phone": phone,
      "status": status,
      "penalty_type": penaltyType,
      "penalty_value": penaltyValue,
      "notes": notes,
      "created_at": createdAt,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as int?,
      clientName: map['client_name'] as String? ?? '',
      yourName: map['your_name'] as String? ?? '',
      brandName: map['brand_name'] as String? ?? '',
      issuedDate: map['issued_date'] as String? ?? '',
      dueDate: map['due_date'] as String? ?? '',
      currencySymbol: map['currency_symbol'] as String? ?? '',
      currencyCode: map['currency_code'] as String? ?? '',
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,   // ← added
      paymentMethod: map['payment_method'] as String? ?? '',
      accountNo: map['account_no'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      penaltyType: map['penalty_type'] as String? ?? '',
      penaltyValue: (map['penalty_value'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}