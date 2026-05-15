class DayNote {
  final String id;
  final DateTime date;
  final String content;
  final NoteCategory category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imagePath; // local file path, null if no image attached

  DayNote({
    required this.id,
    required this.date,
    required this.content,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'content': content,
        'category': category.index,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'imagePath': imagePath,
      };

  factory DayNote.fromJson(Map<String, dynamic> json) => DayNote(
        id: json['id'],
        date: DateTime.parse(json['date']),
        content: json['content'],
        category: NoteCategory.values[json['category'] ?? 0],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        imagePath: json['imagePath'] as String?,
      );

  DayNote copyWith({
    String? content,
    NoteCategory? category,
    String? imagePath,
    bool clearImage = false,
  }) =>
      DayNote(
        id: id,
        date: date,
        content: content ?? this.content,
        category: category ?? this.category,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      );

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;
}

enum NoteCategory {
  plan,
  reminder,
  journal,
  event,
}

extension NoteCategoryExtension on NoteCategory {
  String get label {
    switch (this) {
      case NoteCategory.plan:
        return 'Plan';
      case NoteCategory.reminder:
        return 'Reminder';
      case NoteCategory.journal:
        return 'Journal';
      case NoteCategory.event:
        return 'Event';
    }
  }

  String get emoji {
    switch (this) {
      case NoteCategory.plan:
        return '📋';
      case NoteCategory.reminder:
        return '🔔';
      case NoteCategory.journal:
        return '📖';
      case NoteCategory.event:
        return '🎉';
    }
  }
}