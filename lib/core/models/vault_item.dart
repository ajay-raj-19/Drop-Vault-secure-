import 'package:flutter/material.dart';

class VaultItem {
  final String id;
  final String title;
  final String type; // link, note, file, image
  final String content;
  final String collectionName;
  final DateTime createdAt;
  final List<String> tags;
  final String? category;

  VaultItem({
    required this.id,
    required this.title,
    required this.type,
    required this.content,
    required this.collectionName,
    required this.createdAt,
    this.tags = const [],
    this.category,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type,
    'content': content,
    'collectionName': collectionName,
    'createdAt': createdAt.toIso8601String(),
    'tags': tags,
    'category': category,
  };

  factory VaultItem.fromJson(Map<String, dynamic> json) => VaultItem(
    id: json['id'],
    title: json['title'],
    type: json['type'],
    content: json['content'],
    collectionName: json['collectionName'] ?? 'Personal Research',
    createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    tags: List<String>.from(json['tags'] ?? []),
    category: json['category'],
  );

  IconData getIconData() {
    switch (type.toLowerCase()) {
      case 'note':
        return Icons.edit_note;
      case 'file':
        return Icons.upload_file;
      case 'image':
        return Icons.image;
      case 'link':
        switch (category?.toLowerCase()) {
          case 'github':
            return Icons.code;
          case 'youtube':
            return Icons.play_circle_outline;
          case 'instagram':
            return Icons.camera_alt;
          case 'website':
            return Icons.language;
          default:
            return Icons.link;
        }
      default:
        return Icons.insert_drive_file;
    }
  }
}
