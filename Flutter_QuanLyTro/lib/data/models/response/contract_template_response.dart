class ContractTemplateResponse {
  final String id;
  final String name;
  final String content;
  final bool isSystemTemplate;
  final String? createdAt;
  final String? updatedAt;

  ContractTemplateResponse({
    required this.id,
    required this.name,
    required this.content,
    required this.isSystemTemplate,
    this.createdAt,
    this.updatedAt,
  });

  factory ContractTemplateResponse.fromJson(Map<String, dynamic> json) {
    return ContractTemplateResponse(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      content: json['content'] ?? '',
      isSystemTemplate: json['isSystemTemplate'] ?? false,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}