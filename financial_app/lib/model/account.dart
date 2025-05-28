class Account {
  int? id;
  String type;
  String? bankName;
  double? creditLimit;
  int? cutOffDay;
  String? description;

  Account({
    this.id,
    required this.type,
    this.bankName,
    this.creditLimit,
    this.cutOffDay,
    this.description,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'bank_name': bankName,
    'credit_limit': creditLimit,
    'cut_off_day': cutOffDay,
    'description': description,
  };

  factory Account.fromMap(Map<String, dynamic> map) => Account(
    id: map['id'],
    type: map['type'],
    bankName: map['bank_name'],
    creditLimit: map['credit_limit'] != null ? map['credit_limit'] * 1.0 : null,
    cutOffDay: map['cut_off_day'],
    description: map['description'],
  );
}
