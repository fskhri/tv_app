class ContentModel {
  final int? id;
  final String type; // 'image' atau 'video'
  final String path;
  final int displayOrder;

  ContentModel({
    this.id,
    required this.type,
    required this.path,
    required this.displayOrder,
  });

  factory ContentModel.fromMap(Map<String, dynamic> map) {
    return ContentModel(
      id: map['id'],
      type: map['type'],
      path: map['path'],
      displayOrder: map['display_order'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'path': path,
      'display_order': displayOrder,
    };
  }
} 