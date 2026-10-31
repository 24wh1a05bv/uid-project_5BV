class Task {
  String id;
  String name;
  String description;
  bool isCompleted;
  DateTime? dueDate;
  String priority; // 'high', 'medium', 'low'
  String category;
  DateTime? completedAt;

  Task({
    required this.id,
    required this.name,
    required this.description,
    this.isCompleted = false,
    this.dueDate,
    this.priority = 'medium',
    this.category = 'General',
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'isCompleted': isCompleted,
        'dueDate': dueDate?.toIso8601String(),
        'priority': priority,
        'category': category,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        isCompleted: json['isCompleted'] ?? false,
        dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
        priority: json['priority'] ?? 'medium',
        category: json['category'] ?? 'General',
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'])
            : null,
      );
}
