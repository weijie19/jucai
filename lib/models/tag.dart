class Tag {
  final int? id;
  final String name;
  final int color;
  final int createdAt;

  const Tag({this.id, required this.name, required this.color, required this.createdAt});

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color': color,
        'created_at': createdAt,
      };

  factory Tag.fromMap(Map<String, dynamic> m) => Tag(
        id: m['id'] as int?,
        name: m['name'] as String,
        color: m['color'] as int,
        createdAt: m['created_at'] as int,
      );
}
