class MandatoryPaymentLog {
  int? id;
  int mandatoryPaymentId;
  int? transactionId;
  double paidAmount;
  String paidDate;

  MandatoryPaymentLog({
    this.id,
    required this.mandatoryPaymentId,
    this.transactionId,
    required this.paidAmount,
    required this.paidDate,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'mandatory_payment_id': mandatoryPaymentId,
    'transaction_id': transactionId,
    'paid_amount': paidAmount,
    'paid_date': paidDate,
  };

  factory MandatoryPaymentLog.fromMap(Map<String, dynamic> map) => MandatoryPaymentLog(
    id: map['id'],
    mandatoryPaymentId: map['mandatory_payment_id'],
    transactionId: map['transaction_id'],
    paidAmount: map['paid_amount'] * 1.0,
    paidDate: map['paid_date'],
  );
}
