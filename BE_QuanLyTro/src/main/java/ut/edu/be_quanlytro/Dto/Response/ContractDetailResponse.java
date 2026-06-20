package ut.edu.be_quanlytro.Dto.Response;

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

    // Thông tin người đứng tên hợp đồng (Đại diện)
    private UUID tenantId;
    private String tenantName;
    private String tenantPhone;

    // Thông tin hợp đồng
    private LocalDate startDate;
    private LocalDate endDate;
    private BigDecimal depositAmount;
    private ContractStatus status;
    private String contractFileUrl;
    private BigDecimal rentPrice;

    // Danh sách toàn bộ những người đang ở trong phòng (bao gồm cả đại diện)
    private List<ContractMemberResponse> members;

    private String contractTerms;
}