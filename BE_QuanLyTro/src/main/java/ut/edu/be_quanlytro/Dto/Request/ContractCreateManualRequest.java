package ut.edu.be_quanlytro.Dto.Request;

import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Getter @Setter
public class ContractCreateManualRequest {
    private UUID roomId;
    private LocalDate startDate;
    private LocalDate endDate;
    private BigDecimal depositAmount;
    private UUID depositId;

    // Thông tin khách thuê chủ trọ tự gõ tay
    private String tenantName;
    private String tenantPhone;
    private LocalDate tenantDob;
    private String tenantHometown;
    private String tenantIdCardNumber;

    private UUID templateId;
}