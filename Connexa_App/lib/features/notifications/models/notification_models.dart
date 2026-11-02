class AppNotification {
  const AppNotification({
    required this.id,
    required this.recipientMemberId,
    this.actorMemberId,
    this.actorName,
    this.actorCompanyName,
    required this.eventType,
    required this.title,
    required this.message,
    this.isRead = false,
    this.readAtUtc,
    this.referenceType,
    this.referenceId,
    this.payloadJson,
    required this.createdAtUtc,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int? ?? 0,
      recipientMemberId: json['recipientMemberId'] as int? ?? 0,
      actorMemberId: json['actorMemberId'] as int?,
      actorName: json['actorName'] as String?,
      actorCompanyName: json['actorCompanyName'] as String?,
      eventType: json['eventType'] as String? ?? 'SystemAnnouncement',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      readAtUtc: json['readAtUtc'] != null
          ? DateTime.tryParse(json['readAtUtc'] as String)
          : null,
      referenceType: json['referenceType'] as String?,
      referenceId: json['referenceId'] as int?,
      payloadJson: json['payloadJson'] as String?,
      createdAtUtc: json['createdAtUtc'] != null
          ? DateTime.tryParse(json['createdAtUtc'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  final int id;
  final int recipientMemberId;
  final int? actorMemberId;
  final String? actorName;
  final String? actorCompanyName;
  final String eventType;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? readAtUtc;
  final String? referenceType;
  final int? referenceId;
  final String? payloadJson;
  final DateTime createdAtUtc;

  AppNotification copyWith({
    bool? isRead,
    DateTime? readAtUtc,
  }) {
    return AppNotification(
      id: id,
      recipientMemberId: recipientMemberId,
      actorMemberId: actorMemberId,
      actorName: actorName,
      actorCompanyName: actorCompanyName,
      eventType: eventType,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      readAtUtc: readAtUtc ?? this.readAtUtc,
      referenceType: referenceType,
      referenceId: referenceId,
      payloadJson: payloadJson,
      createdAtUtc: createdAtUtc,
    );
  }
}

class NotificationListResponse {
  const NotificationListResponse({
    required this.items,
    required this.totalCount,
    required this.unreadCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawItems = json['items'] as List<dynamic>? ?? <dynamic>[];
    return NotificationListResponse(
      items: rawItems
          .map((dynamic item) => AppNotification.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int? ?? 0,
      unreadCount: json['unreadCount'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }

  final List<AppNotification> items;
  final int totalCount;
  final int unreadCount;
  final int page;
  final int pageSize;
  final int totalPages;
}
