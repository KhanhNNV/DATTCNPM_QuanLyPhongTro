class IssueResponse {
  final String id;
  final String roomNumber;
  final String tenantName;
  final String description;
  final String? imageUrl;
  final String status;
  final String? solutionNote;
  final DateTime? createdAt;

  IssueResponse({
    required this.id,
    required this.roomNumber,
    required this.tenantName,
    required this.description,
    this.imageUrl,
    required this.status,
    this.solutionNote,
    this.createdAt,
  });

  factory IssueResponse.fromJson(Map<String, dynamic> json) {
    return IssueResponse(
      id: json['id'] ?? '',
      roomNumber: json['roomNumber'] ?? '',
      tenantName: json['tenantName'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      status: json['status'] ?? 'PENDING',
      solutionNote: json['solutionNote'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}