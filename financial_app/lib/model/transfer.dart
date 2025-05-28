class Transfer {
  int? id;
  int fromAccountId;
  int toAccountId;
  double amount;
  String date;
  String? description;

  Transfer({
    this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.date,
    this.description,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'from_account_id': fromAccountId,
    'to_account_id': toAccountId,
    'amount': amount,
    'date': date,
    'description': description,
  };

  factory Transfer.fromMap(Map<String, dynamic> map) => Transfer(
    id: map['id'],
    fromAccountId: map['from_account_id'],
    toAccountId: map['to_account_id'],
    amount: map['amount'] * 1.0,
    date: map['date'],
    description: map['description'],
  );
}
