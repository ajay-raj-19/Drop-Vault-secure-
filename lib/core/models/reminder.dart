class Reminder {
  final String id;
  final String title;
  final String collectionName;
  final DateTime dateTime;
  final bool isCompleted;
  final String? itemId;
  final DateTime updatedAt;

  Reminder({
    required this.id,
    required this.title,
    required this.collectionName,
    required this.dateTime,
    this.isCompleted = false,
    this.itemId,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? dateTime;

  Reminder copyWith({
    String? id,
    String? title,
    String? collectionName,
    DateTime? dateTime,
    bool? isCompleted,
    String? itemId,
    bool clearItemId = false,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      collectionName: collectionName ?? this.collectionName,
      dateTime: dateTime ?? this.dateTime,
      isCompleted: isCompleted ?? this.isCompleted,
      itemId: clearItemId ? null : (itemId ?? this.itemId),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'collectionName': collectionName,
    'dateTime': dateTime.toIso8601String(),
    'isCompleted': isCompleted,
    'itemId': itemId,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    id: json['id'],
    title: json['title'],
    collectionName: json['collectionName'] ?? 'Personal Research',
    dateTime: DateTime.parse(json['dateTime']),
    isCompleted: json['isCompleted'] ?? false,
    itemId: json['itemId'],
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'])
        : DateTime.parse(json['dateTime']),
  );
}
