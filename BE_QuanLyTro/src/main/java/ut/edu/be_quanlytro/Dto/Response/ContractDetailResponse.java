    package ut.edu.be_quanlytro.Dto.Response;

    import jakarta.persistence.Column;
    import lombok.Builder;
    import lombok.Getter;
    import lombok.Setter;
    import ut.edu.be_quanlytro.Entity.Enum.ContractStatus;

    import java.math.BigDecimal;
    import java.time.LocalDate;
    import java.util.List;
    import java.util.UUID;

    @Getter @Setter @Builder
    public class ContractDetailResponse {
        private UUID id;
        private UUID roomId;
        private String roomNumber;
        private UUID tenantId;
        private String tenantName;
        private String tenantPhone;
        private String tenantIdCardNumber;
        private String tenantHometown;
        private String tenantSignatureUrl;
        private UUID areaId;
        private String areaName;
        private String areaAddress;
        private String landlordName;
        private String landlordIdCardNumber;
        private String landlordHometown;
        private String landlordSignatureUrl;
        private LocalDate startDate;
        private LocalDate endDate;
        private BigDecimal depositAmount;
        private ContractStatus status;
        private String contractFileUrl;
        private BigDecimal rentPrice;
        private List<ContractMemberResponse> members;
        private String contractTerms;
        private UUID templateId;
    }