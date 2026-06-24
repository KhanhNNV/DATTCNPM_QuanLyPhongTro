class ContractTemplateRequest {
  final String name;
  final String content;

  ContractTemplateRequest({
    required this.name,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "content": content,
    };
  }
}