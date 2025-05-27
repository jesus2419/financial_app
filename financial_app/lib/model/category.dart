class Category {
  int? id;
  String name;
  String type;
  String? icon;
  String? color;

  Category({
    this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type,
    'icon': icon,
    'color': color,
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'],
    name: map['name'],
    type: map['type'],
    icon: map['icon'],
    color: map['color'],
  );
}
