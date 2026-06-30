import 'contract_member_response.dart';

class ContractDetailResponse {
  final String id;
  final String? templateId;
  final String roomId;
  final String roomNumber;

  final String tenantId;
  final String tenantName;
  final String tenantPhone;
  final String tenantIdCardNumber;
  final String tenantHometown;

  final String startDate;
  final String endDate;
  final double depositAmount;
  final String status;
  final String? contractFileUrl;
  final double rentPrice;
  final List<ContractMemberResponse> members;
  final String? contractTerms;
  final String? createdAt;

  // Thông tin chủ trọ
  final String landlordName;
  final String landlordIdCardNumber;
  final String landlordAddress;
  final String? landlordSignatureUrl;

  ContractDetailResponse({
    required this.id,
    this.templateId,
    required this.roomId,
    required this.roomNumber,
    required this.tenantId,
    required this.tenantName,
    required this.tenantPhone,
    required this.tenantIdCardNumber,
    required this.tenantHometown,
    required this.startDate,
    required this.endDate,
    required this.depositAmount,
    required this.status,
    this.contractFileUrl,
    required this.rentPrice,
    required this.members,
    this.contractTerms,
    this.createdAt,
    required this.landlordName,
    required this.landlordIdCardNumber,
    required this.landlordAddress,
    this.landlordSignatureUrl,
  });

  factory ContractDetailResponse.fromJson(Map<String, dynamic> json) {
    return ContractDetailResponse(
      id: json['id'] ?? '',
      templateId: json['templateId'],
      roomId: json['roomId'] ?? '',
      roomNumber: json['roomNumber'] ?? '',

      tenantId: json['tenantId'] ?? '',
      tenantName: json['tenantName'] ?? '',
      tenantPhone: json['tenantPhone'] ?? '',
      tenantIdCardNumber: json['tenantIdCardNumber'] ?? '',
      tenantHometown: json['tenantHometown'] ?? '',

      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      depositAmount: (json['depositAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'PENDING',
      contractFileUrl: json['contractFileUrl'],
      rentPrice: (json['rentPrice'] ?? 0).toDouble(),
      members: (json['members'] as List?)
          ?.map((e) => ContractMemberResponse.fromJson(e))
          .toList() ?? [],
      contractTerms: json['contractTerms'],
      createdAt: json['createdAt'],

      landlordName: json['landlordName'] ?? '',
      landlordIdCardNumber: json['landlordIdCardNumber'] ?? '',
      landlordAddress: json['landlordAddress'] ?? '',
      landlordSignatureUrl: json['landlordSignatureUrl'],
    );
  }
}