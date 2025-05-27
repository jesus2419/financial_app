class MandatoryPayment {
  int? id;
  int? accountId;
  String name;
  double amount;
  String dueDate;
  String? frequency;
  int? categoryId;
  String? notes;

  MandatoryPayment({
    this.id,
    this.accountId,
    required this.name,
    required this.amount,
    required this.dueDate,
    this.frequency,
    this.categoryId,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'account_id': accountId,
    'name': name,
    'amount': amount,
    'due_date': dueDate,
    'frequency': frequency,
    'category_id': categoryId,
    'notes': notes,
  };

  factory MandatoryPayment.fromMap(Map<String, dynamic> map) => MandatoryPayment(
    id: map['id'],
    accountId: map['account_id'],
    name: map['name'],
    amount: map['amount'] * 1.0,
    dueDate: map['due_date'],
    frequency: map['frequency'],
    categoryId: map['category_id'],
    notes: map['notes'],
  );
}
