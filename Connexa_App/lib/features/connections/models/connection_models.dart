/// Models representing business connections and networking in Connexa.
library;

class ConnectedMemberItem {
  const ConnectedMemberItem({
    required this.connectionId,
    required this.memberId,
    required this.fullName,
    required this.companyName,
    required this.businessType,
    required this.industryId,
    required this.industryName,
    required this.location,
    required this.connectedSinceUtc,
    this.maskedEmail,
    this.maskedPhoneNumber,
    this.connectionStatus = 'Connected',
  });

  final int connectionId;
  final int memberId;
  final String fullName;
  final String companyName;
  final String businessType;
  final int industryId;
  final String industryName;
  final String location;
  final DateTime connectedSinceUtc;
  final String? maskedEmail;
  final String? maskedPhoneNumber;
  final String connectionStatus;

  String get displayEmail => maskedEmail ?? 'Protected';

  String get displayPhone => maskedPhoneNumber ?? 'Protected';

  String get displayLocation =>
      location.trim().isNotEmpty ? location.trim() : 'Gujarat, India';

  factory ConnectedMemberItem.fromJson(Map<String, dynamic> json) {
    return ConnectedMemberItem(
      connectionId: (json['connectionId'] as num?)?.toInt() ?? 0,
      memberId: (json['memberId'] as num?)?.toInt() ?? 0,
      fullName: json['fullName']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      businessType:
          json['businessType']?.toString() ?? 'Manufacturer / Company',
      industryId: (json['industryId'] as num?)?.toInt() ?? 0,
      industryName: json['industryName']?.toString() ?? 'General',
      location: json['location']?.toString() ?? 'Gujarat, India',
      connectedSinceUtc:
          DateTime.tryParse(json['connectedSinceUtc']?.toString() ?? '') ??
          DateTime.now(),
      maskedEmail: json['maskedEmail']?.toString(),
      maskedPhoneNumber: json['maskedPhoneNumber']?.toString(),
      connectionStatus: json['connectionStatus']?.toString() ?? 'Connected',
    );
  }
}

class ConnectionRequestItem {
  const ConnectionRequestItem({
    required this.id,
    required this.memberId,
    required this.fullName,
    required this.companyName,
    required this.businessType,
    required this.industryId,
    required this.industryName,
    required this.location,
    this.note,
    required this.createdAtUtc,
    required this.status,
    required this.direction,
  });

  final int id;
  final int memberId;
  final String fullName;
  final String companyName;
  final String businessType;
  final int industryId;
  final String industryName;
  final String location;
  final String? note;
  final DateTime createdAtUtc;
  final String status;
  final String direction; // 'Received' or 'Sent'

  String get displayLocation =>
      location.trim().isNotEmpty ? location.trim() : 'Gujarat, India';

  factory ConnectionRequestItem.fromJson(Map<String, dynamic> json) {
    return ConnectionRequestItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      memberId: (json['memberId'] as num?)?.toInt() ?? 0,
      fullName: json['fullName']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      businessType:
          json['businessType']?.toString() ?? 'Manufacturer / Company',
      industryId: (json['industryId'] as num?)?.toInt() ?? 0,
      industryName: json['industryName']?.toString() ?? 'General',
      location: json['location']?.toString() ?? 'Gujarat, India',
      note: json['note']?.toString(),
      createdAtUtc:
          DateTime.tryParse(json['createdAtUtc']?.toString() ?? '') ??
          DateTime.now(),
      status: json['status']?.toString() ?? 'Pending',
      direction: json['direction']?.toString() ?? 'Received',
    );
  }
}

class ConnectionsSummary {
  const ConnectionsSummary({
    this.totalConnected = 0,
    this.receivedPendingCount = 0,
    this.sentPendingCount = 0,
  });

  final int totalConnected;
  final int receivedPendingCount;
  final int sentPendingCount;

  factory ConnectionsSummary.fromJson(Map<String, dynamic> json) {
    return ConnectionsSummary(
      totalConnected: (json['totalConnected'] as num?)?.toInt() ?? 0,
      receivedPendingCount:
          (json['receivedPendingCount'] as num?)?.toInt() ?? 0,
      sentPendingCount: (json['sentPendingCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class PaginatedList<T> {
  const PaginatedList({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
}
