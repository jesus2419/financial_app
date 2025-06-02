class SavingsGoal {
  int? id;
  String name;
  double targetAmount;
  double currentAmount;
  String? deadline;
  String? description;
  String? icon;
  String? color;

  SavingsGoal({
    this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    this.deadline,
    this.description,
    this.icon,
    this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline,
      'description': description,
      'icon': icon,
      'color': color,
    };
  }

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'],
      name: map['name'],
      targetAmount: map['target_amount'],
      currentAmount: map['current_amount'] ?? 0,
      deadline: map['deadline'],
      description: map['description'],
      icon: map['icon'],
      color: map['color'],
    );
  }
}
