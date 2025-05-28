class Transaction {
  int? id;
  int accountId;
  double amount;
  int? categoryId;
  String? description;
  String date;

  Transaction({
    this.id,
    required this.accountId,
    required this.amount,
    this.categoryId,
    this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'account_id': accountId,
    'amount': amount,
    'category_id': categoryId,
    'description': description,
    'date': date,
  };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
    id: map['id'],
    accountId: map['account_id'],
    amount: map['amount'] * 1.0,
    categoryId: map['category_id'],
    description: map['description'],
    date: map['date'],
  );
}
