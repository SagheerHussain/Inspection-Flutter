import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/formatters/formatter.dart';

class NotificationModel {
  String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  bool isRead; // Mutable so we can update UI locally
  final DateTime createdAt;
  final bool isGlobal;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
    required this.isGlobal,
  });

  String get formattedDate => TFormatter.formatDate(createdAt);

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: json['data'] is Map<String, dynamic> ? json['data'] : {},
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isGlobal: json['isGlobal'] ?? false,
    );
  }

  factory NotificationModel.fromDocSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (doc.data() == null) return NotificationModel.empty();
    final data = doc.data()!;
    data['_id'] = doc.id;
    return NotificationModel.fromJson(data);
  }

  static NotificationModel fromQuerySnapshot(QueryDocumentSnapshot<Object?> doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['_id'] = doc.id;
    return NotificationModel.fromJson(data);
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'isGlobal': isGlobal,
    };
  }

  static NotificationModel empty() => NotificationModel(
        id: '',
        userId: '',
        type: '',
        title: '',
        body: '',
        data: {},
        isRead: false,
        createdAt: DateTime.now(),
        isGlobal: false,
      );
}
