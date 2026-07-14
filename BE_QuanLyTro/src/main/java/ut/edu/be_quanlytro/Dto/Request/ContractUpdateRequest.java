    package ut.edu.be_quanlytro.Dto.Request;

    import lombok.Getter;
    import lombok.Setter;

    import java.math.BigDecimal;
    import java.time.LocalDate;
    import java.util.List;
    import java.util.UUID;

    @Getter @Setter
    public class ContractUpdateRequest {
            private LocalDate startDate;
            private LocalDate endDate;
            private BigDecimal depositAmount;
            private UUID templateId;
            private String tenantFullName;
            private String tenantIdCardNumber;
            private LocalDate tenantDob;
            private String tenantHometown;
            private List<ContractMemberAddRequest> members;
    }