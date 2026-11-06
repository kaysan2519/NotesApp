import '../core/constants/app_colors.dart';

/// Model data catatan pribadi yang selaras dengan response JSON `/api/notes/*`.
class NoteModel {
  final int id;
  final int userId;
  final String title;
  final String content;
  final String color;
  final bool isPinned;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.color,
    required this.isPinned,
    required this.isPrivate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      color: ((json['color'] as String?) ?? AppColors.defaultNoteHex).toUpperCase(),
      isPinned: json['is_pinned'] == true || json['is_pinned'] == 1,
      isPrivate: json['is_private'] == null
          ? true
          : (json['is_private'] == true || json['is_private'] == 1),
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? (DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'color': color,
      'is_pinned': isPinned,
      'is_private': isPrivate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  NoteModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? content,
    String? color,
    bool? isPinned,
    bool? isPrivate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
